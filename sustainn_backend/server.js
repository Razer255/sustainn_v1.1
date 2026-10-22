const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  console.error('FATAL: JWT_SECRET is not set. Refusing to start without it.');
  process.exit(1);
}
const JWT_EXPIRES_IN = '30d';
const BCRYPT_ROUNDS = 10;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB connection
mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    console.log('Successfully connected to MongoDB Atlas.');
    seedDatabase();
  })
  .catch((err) => {
    console.error('Error connecting to MongoDB Atlas:', err.message);
    console.log('Please make sure your MongoDB username and password in .env are correct and IP access is allowed.');
  });

// ─── Database Models ─────────────────────────────────────────

const UserSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  phone: { type: String, required: true },
  name: { type: String, required: true },
  guardianName: { type: String },
  password: { type: String },
  language: { type: String, default: 'en' },
  region: { type: String, required: true },
  createdAt: { type: Date, default: Date.now }
});
const User = mongoose.model('User', UserSchema);

const FieldSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  ownerId: { type: String, required: true, ref: 'User' },
  name: { type: String, required: true },
  area: { type: Number, required: true },
  latitude: { type: Number },
  longitude: { type: Number },
  boundaryPoints: { type: [{ lat: Number, lng: Number, _id: false }], default: [] },
  soilType: { type: String, required: true },
  healthStatus: { type: String, default: 'good' },
  activeCrops: { type: Number, default: 0 },
  pendingActions: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now }
});
const Field = mongoose.model('Field', FieldSchema);

const CropSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  fieldId: { type: String, required: true, ref: 'Field' },
  season: { type: String, required: true },
  cropName: { type: String, required: true },
  variety: { type: String, required: true },
  sownDate: { type: Date, required: true },
  expectedHarvestDate: { type: Date },
  status: { type: String, default: 'active' }, // 'active', 'harvested'
  isIntercrop: { type: Boolean, default: false },
  areaCovered: { type: Number },
  healthStatus: { type: String, default: 'good' },
  activityCount: { type: Number, default: 0 }
});
const Crop = mongoose.model('Crop', CropSchema);

const ActivitySchema = new mongoose.Schema({
  _id: { type: String, required: true },
  cropId: { type: String, required: true, ref: 'Crop' },
  type: { type: String, required: true },
  subtype: { type: String },
  date: { type: Date, required: true },
  areaCovered: { type: Number },
  areaUnit: { type: String },
  notes: { type: String },
  cost: { type: Number, default: 0 },
  quantity: { type: Number },
  unit: { type: String },
  createdBy: { type: String, required: true },
  attributes: { type: mongoose.Schema.Types.Mixed }
});
const Activity = mongoose.model('Activity', ActivitySchema);

const ActionPointSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  scope: { type: String, required: true },
  refId: { type: String, required: true },
  message: { type: String, required: true },
  priority: { type: String, required: true },
  dueDate: { type: Date },
  category: { type: String },
  resolved: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});
const ActionPoint = mongoose.model('ActionPoint', ActionPointSchema);

const FinancialSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  cropId: { type: String, required: true, ref: 'Crop' },
  inputCost: { type: Number, default: 0 },
  expectedRevenue: { type: Number, default: 0 },
  actualRevenue: { type: Number, default: 0 },
  updatedAt: { type: Date, default: Date.now }
});
const Financial = mongoose.model('Financial', FinancialSchema);

const IssueReportSchema = new mongoose.Schema({
  _id: { type: String, required: true },
  userId: { type: String, required: true },
  userName: { type: String, required: true },
  userPhone: { type: String, required: true },
  message: { type: String, required: true, maxlength: 1000 },
  status: { type: String, enum: ['open', 'resolved'], default: 'open' },
  createdAt: { type: Date, default: Date.now }
});
const IssueReport = mongoose.model('IssueReport', IssueReportSchema);

// ─── Location (States / Districts) ───────────────────────────
// Served from a bundled static dataset instead of proxying data.gov.in's
// LGD API, which has proven unreliable (sustained outages / unreachable
// from multiple networks). Tehsil and Village are free-text fields on the
// client, since no comparable open dataset exists at that granularity.

const statesData = require('./data/states-districts.json');

app.get('/api/location/states', (req, res) => {
  res.json(statesData.map((s) => ({ code: s.code, name: s.name })));
});

app.get('/api/location/districts', (req, res) => {
  const { stateCode } = req.query;
  if (!stateCode) return res.status(400).json({ error: 'stateCode is required' });
  const state = statesData.find((s) => String(s.code) === String(stateCode));
  if (!state) return res.json([]);
  res.json(state.districts);
});

// ─── Farmer Auth ──────────────────────────────────────────────
// Verifies the JWT issued at login, sent as 'Authorization: Bearer <token>'.
// Attaches req.userId so routes can check the caller actually owns the
// field/crop/activity/etc. they're trying to read or modify.

function requireAuth(req, res, next) {
  const header = req.header('Authorization');
  const token = header && header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header.' });
  }
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.userId = payload.userId;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid or expired token.' });
  }
}

/**
 * Confirms the authenticated user (req.userId) owns the field being
 * referenced, either directly (fieldId) or transitively via a crop or
 * activity id. Returns the resolved field on success, or sends a 403/404
 * response and returns null — callers should `return` immediately when
 * this returns null.
 */
async function ownsField(req, res, { fieldId, cropId, activityId } = {}) {
  let resolvedFieldId = fieldId;

  if (!resolvedFieldId && cropId) {
    const crop = await Crop.findById(cropId);
    if (!crop) {
      res.status(404).json({ error: 'Crop not found' });
      return null;
    }
    resolvedFieldId = crop.fieldId;
  }

  if (!resolvedFieldId && activityId) {
    const activity = await Activity.findById(activityId);
    if (!activity) {
      res.status(404).json({ error: 'Activity not found' });
      return null;
    }
    const crop = await Crop.findById(activity.cropId);
    if (!crop) {
      res.status(404).json({ error: 'Crop not found' });
      return null;
    }
    resolvedFieldId = crop.fieldId;
  }

  if (!resolvedFieldId) {
    res.status(400).json({ error: 'fieldId, cropId, or activityId is required.' });
    return null;
  }

  const field = await Field.findById(resolvedFieldId);
  if (!field) {
    res.status(404).json({ error: 'Field not found' });
    return null;
  }
  if (field.ownerId !== req.userId) {
    res.status(403).json({ error: 'You do not have access to this resource.' });
    return null;
  }
  return field;
}

// ─── Admin Routes ─────────────────────────────────────────────
// Protected by a static API key (ADMIN_API_KEY) sent as 'x-admin-key'.
// Intended for the internal admin dashboard, not the farmer app.

function requireAdminKey(req, res, next) {
  const key = req.header('x-admin-key');
  if (!process.env.ADMIN_API_KEY || key !== process.env.ADMIN_API_KEY) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
}

app.get('/api/admin/stats', requireAdminKey, async (req, res) => {
  try {
    const [userCount, fieldCount, cropCount, activityCount, actionPointCount, openReportCount] = await Promise.all([
      User.countDocuments(),
      Field.countDocuments(),
      Crop.countDocuments(),
      Activity.countDocuments(),
      ActionPoint.countDocuments({ resolved: false }),
      IssueReport.countDocuments({ status: 'open' }),
    ]);
    res.json({
      userCount,
      fieldCount,
      cropCount,
      activityCount,
      openActionPointCount: actionPointCount,
      openIssueReportCount: openReportCount
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/admin/users', requireAdminKey, async (req, res) => {
  try {
    const users = await User.find().sort({ createdAt: -1 });
    res.json(users.map(u => ({
      id: u._id,
      phone: u.phone,
      name: u.name,
      guardianName: u.guardianName,
      language: u.language,
      region: u.region,
      createdAt: u.createdAt.toISOString()
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/admin/fields', requireAdminKey, async (req, res) => {
  try {
    const fields = await Field.find().sort({ createdAt: -1 });
    res.json(fields.map(f => ({
      id: f._id,
      ownerId: f.ownerId,
      name: f.name,
      area: f.area,
      latitude: f.latitude,
      longitude: f.longitude,
      boundaryPoints: f.boundaryPoints,
      soilType: f.soilType,
      healthStatus: f.healthStatus,
      activeCrops: f.activeCrops,
      pendingActions: f.pendingActions,
      createdAt: f.createdAt.toISOString()
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/admin/crops', requireAdminKey, async (req, res) => {
  try {
    const crops = await Crop.find().sort({ sownDate: -1 });
    res.json(crops.map(c => ({
      id: c._id,
      fieldId: c.fieldId,
      season: c.season,
      cropName: c.cropName,
      variety: c.variety,
      sownDate: c.sownDate.toISOString(),
      expectedHarvestDate: c.expectedHarvestDate ? c.expectedHarvestDate.toISOString() : null,
      status: c.status,
      isIntercrop: c.isIntercrop,
      areaCovered: c.areaCovered,
      healthStatus: c.healthStatus,
      activityCount: c.activityCount
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// All farming activities across every user, newest first, enriched with
// crop/field/owner context so the admin dashboard's Activity Log can
// filter and display without separate lookups.
app.get('/api/admin/activities', requireAdminKey, async (req, res) => {
  try {
    const [activities, crops, fields, users, financials] = await Promise.all([
      Activity.find().sort({ date: -1 }).limit(500),
      Crop.find(),
      Field.find(),
      User.find(),
      Financial.find()
    ]);

    const cropById = new Map(crops.map(c => [c._id, c]));
    const fieldById = new Map(fields.map(f => [f._id, f]));
    const userById = new Map(users.map(u => [u._id, u]));
    const financialByCropId = new Map(financials.map(f => [f.cropId, f]));

    res.json(activities.map(a => {
      const crop = cropById.get(a.cropId);
      const field = crop ? fieldById.get(crop.fieldId) : null;
      const owner = field ? userById.get(field.ownerId) : null;
      const financial = financialByCropId.get(a.cropId);
      return {
        id: a._id,
        cropId: a.cropId,
        type: a.type,
        subtype: a.subtype,
        date: a.date.toISOString(),
        areaCovered: a.areaCovered,
        areaUnit: a.areaUnit,
        notes: a.notes,
        cost: a.cost,
        quantity: a.quantity,
        unit: a.unit,
        createdBy: a.createdBy,
        attributes: a.attributes,
        cropName: crop ? crop.cropName : null,
        cropVariety: crop ? crop.variety : null,
        cropSeason: crop ? crop.season : null,
        fieldId: crop ? crop.fieldId : null,
        fieldName: field ? field.name : null,
        fieldArea: field ? field.area : null,
        fieldSoilType: field ? field.soilType : null,
        ownerId: field ? field.ownerId : null,
        ownerName: owner ? owner.name : null,
        ownerPhone: owner ? owner.phone : null,
        cropInputCost: financial ? financial.inputCost : null,
        cropExpectedRevenue: financial ? financial.expectedRevenue : null,
        cropActualRevenue: financial ? financial.actualRevenue : null
      };
    }));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Full drill-down for one user: their fields, each field's crops, each
// crop's activities and financials. One aggregated call so the admin
// dashboard doesn't need to fan out N+1 requests.
app.get('/api/admin/users/:userId/detail', requireAdminKey, async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const fields = await Field.find({ ownerId: userId }).sort({ createdAt: -1 });
    const fieldIds = fields.map(f => f._id);

    const crops = await Crop.find({ fieldId: { $in: fieldIds } }).sort({ sownDate: -1 });
    const cropIds = crops.map(c => c._id);

    const [activities, financials] = await Promise.all([
      Activity.find({ cropId: { $in: cropIds } }).sort({ date: -1 }),
      Financial.find({ cropId: { $in: cropIds } })
    ]);

    res.json({
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name,
        guardianName: user.guardianName,
        language: user.language,
        region: user.region,
        createdAt: user.createdAt.toISOString()
      },
      fields: fields.map(f => ({
        id: f._id,
        ownerId: f.ownerId,
        name: f.name,
        area: f.area,
        latitude: f.latitude,
        longitude: f.longitude,
        soilType: f.soilType,
        healthStatus: f.healthStatus,
        activeCrops: f.activeCrops,
        pendingActions: f.pendingActions,
        createdAt: f.createdAt.toISOString()
      })),
      crops: crops.map(c => ({
        id: c._id,
        fieldId: c.fieldId,
        season: c.season,
        cropName: c.cropName,
        variety: c.variety,
        sownDate: c.sownDate.toISOString(),
        expectedHarvestDate: c.expectedHarvestDate ? c.expectedHarvestDate.toISOString() : null,
        status: c.status,
        isIntercrop: c.isIntercrop,
        areaCovered: c.areaCovered,
        healthStatus: c.healthStatus,
        activityCount: c.activityCount
      })),
      activities: activities.map(a => ({
        id: a._id,
        cropId: a.cropId,
        type: a.type,
        subtype: a.subtype,
        date: a.date.toISOString(),
        areaCovered: a.areaCovered,
        areaUnit: a.areaUnit,
        notes: a.notes,
        cost: a.cost,
        quantity: a.quantity,
        unit: a.unit,
        createdBy: a.createdBy
      })),
      financials: financials.map(f => ({
        id: f._id,
        cropId: f.cropId,
        inputCost: f.inputCost,
        expectedRevenue: f.expectedRevenue,
        actualRevenue: f.actualRevenue,
        updatedAt: f.updatedAt.toISOString()
      }))
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// List issue reports. ?status=open|resolved filters; omit for all.
app.get('/api/admin/issue-reports', requireAdminKey, async (req, res) => {
  try {
    const { status } = req.query;
    const query = status ? { status } : {};
    const reports = await IssueReport.find(query).sort({ createdAt: -1 });
    res.json(reports.map(r => ({
      id: r._id,
      userId: r.userId,
      userName: r.userName,
      userPhone: r.userPhone,
      message: r.message,
      status: r.status,
      createdAt: r.createdAt.toISOString()
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Mark an issue report resolved
app.put('/api/admin/issue-reports/:reportId/resolve', requireAdminKey, async (req, res) => {
  try {
    const report = await IssueReport.findByIdAndUpdate(
      req.params.reportId,
      { status: 'resolved' },
      { new: true }
    );
    if (!report) return res.status(404).json({ error: 'Report not found' });
    res.json({ id: report._id, status: report.status });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Permanently delete an issue report (manual cleanup to bound storage growth)
app.delete('/api/admin/issue-reports/:reportId', requireAdminKey, async (req, res) => {
  try {
    const result = await IssueReport.findByIdAndDelete(req.params.reportId);
    if (!result) return res.status(404).json({ error: 'Report not found' });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Manually create an action point for a farmer, field, or crop. This is
// the static/manual path while automatic computation (weather alerts,
// fertilizer due-dates, etc.) is still unbuilt — an admin types the
// message by hand and pushes it to the relevant scope.
app.post('/api/admin/action-points', requireAdminKey, async (req, res) => {
  try {
    const { scope, refId, message, priority, dueDate, category } = req.body;

    if (!['farmer', 'field', 'crop'].includes(scope)) {
      return res.status(400).json({ error: 'scope must be one of: farmer, field, crop' });
    }
    if (!refId || !message || !priority) {
      return res.status(400).json({ error: 'refId, message, and priority are required.' });
    }

    const refExists = scope === 'farmer'
      ? await User.exists({ _id: refId })
      : scope === 'field'
      ? await Field.exists({ _id: refId })
      : await Crop.exists({ _id: refId });
    if (!refExists) {
      return res.status(404).json({ error: `No ${scope} found with id ${refId}` });
    }

    const actionPoint = new ActionPoint({
      _id: new mongoose.Types.ObjectId().toString(),
      scope,
      refId,
      message,
      priority,
      dueDate: dueDate || undefined,
      category: category || undefined
    });
    await actionPoint.save();

    res.status(201).json({ id: actionPoint._id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// List all action points (resolved and unresolved), enriched with the
// farmer/field/crop they point at, so the admin dashboard can show what's
// been sent and what the farmer has marked resolved.
app.get('/api/admin/action-points', requireAdminKey, async (req, res) => {
  try {
    const [actionPoints, users, fields, crops] = await Promise.all([
      ActionPoint.find().sort({ createdAt: -1 }),
      User.find(),
      Field.find(),
      Crop.find()
    ]);

    const userById = new Map(users.map(u => [u._id, u]));
    const fieldById = new Map(fields.map(f => [f._id, f]));
    const cropById = new Map(crops.map(c => [c._id, c]));

    res.json(actionPoints.map(ap => {
      let ownerId = null;
      let ownerName = null;
      let fieldName = null;
      let cropName = null;

      if (ap.scope === 'farmer') {
        const user = userById.get(ap.refId);
        ownerId = ap.refId;
        ownerName = user ? user.name : null;
      } else if (ap.scope === 'field') {
        const field = fieldById.get(ap.refId);
        if (field) {
          ownerId = field.ownerId;
          ownerName = userById.get(field.ownerId)?.name ?? null;
          fieldName = field.name;
        }
      } else if (ap.scope === 'crop') {
        const crop = cropById.get(ap.refId);
        if (crop) {
          cropName = crop.cropName;
          const field = fieldById.get(crop.fieldId);
          if (field) {
            ownerId = field.ownerId;
            ownerName = userById.get(field.ownerId)?.name ?? null;
            fieldName = field.name;
          }
        }
      }

      return {
        id: ap._id,
        scope: ap.scope,
        refId: ap.refId,
        message: ap.message,
        priority: ap.priority,
        dueDate: ap.dueDate ? ap.dueDate.toISOString() : null,
        category: ap.category,
        resolved: ap.resolved,
        createdAt: ap.createdAt.toISOString(),
        ownerId,
        ownerName,
        fieldName,
        cropName
      };
    }));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── REST API Routes ──────────────────────────────────────────

// A stored password is either a bcrypt hash (always starts with $2) or a
// legacy plaintext value from before hashing was added. This lets old
// accounts keep working and upgrades them to a hash on next successful
// login, instead of locking everyone out the moment hashing shipped.
function looksHashed(password) {
  return typeof password === 'string' && password.startsWith('$2');
}

async function verifyPassword(plainPassword, storedPassword) {
  const effectiveStored = storedPassword || 'password123';
  if (looksHashed(effectiveStored)) {
    return bcrypt.compare(plainPassword, effectiveStored);
  }
  return plainPassword === effectiveStored;
}

function issueToken(userId) {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

// Auth Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { identifier, password } = req.body;
    console.log(`[POST] /api/auth/login with identifier: ${identifier}`);

    if (!identifier || !password) {
      return res.status(400).json({ error: 'identifier and password are required.' });
    }

    // Clean identifier to check match
    const cleanPhone = identifier.replace(/[^0-9]/g, '');
    const orConditions = [{ phone: identifier }];
    if (cleanPhone) {
      orConditions.push({ phone: new RegExp(cleanPhone + '$') });
    }
    let user = await User.findOne({ $or: orConditions });

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials.' });
    }

    const passwordMatches = await verifyPassword(password, user.password);
    if (!passwordMatches) {
      return res.status(401).json({ error: 'Invalid credentials.' });
    }

    // Opportunistically upgrade a legacy plaintext password to a hash
    // now that we know it's correct.
    if (!looksHashed(user.password)) {
      user.password = await bcrypt.hash(password, BCRYPT_ROUNDS);
      await user.save();
    }

    res.json({
      token: issueToken(user._id),
      user: {
        id: user._id,
        phone: user.phone,
        name: user.name
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Create User Profile (signup). Unauthenticated by necessity — the
// farmer doesn't have a token until this succeeds — but only creates
// brand-new accounts; it no longer lets a caller "update" an arbitrary
// existing id without proving ownership (that upsert previously let
// anyone who knew/guessed a user id overwrite that account).
app.post('/api/users', async (req, res) => {
  try {
    const { phone, name, guardianName, language, region, id, password } = req.body;
    console.log(`[POST] /api/users creating userId: ${id}`);

    if (!id || !phone || !name || !password) {
      return res.status(400).json({ error: 'id, phone, name, and password are required.' });
    }

    const existingById = await User.findById(id);
    if (existingById) {
      return res.status(409).json({ error: 'A user with this id already exists.' });
    }
    const existingByPhone = await User.findOne({ phone });
    if (existingByPhone) {
      return res.status(409).json({ error: 'An account with this phone number already exists.' });
    }

    const hashedPassword = await bcrypt.hash(password, BCRYPT_ROUNDS);
    const user = new User({ _id: id, phone, name, guardianName, language, region, password: hashedPassword });
    await user.save();

    res.status(201).json({
      token: issueToken(user._id),
      user: { id: user._id, phone: user.phone, name: user.name }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get User Profile — only the signed-in user can read their own profile.
app.get('/api/users/:userId', requireAuth, async (req, res) => {
  try {
    console.log(`[GET] /api/users/${req.params.userId}`);
    if (req.params.userId !== req.userId) {
      return res.status(403).json({ error: 'You do not have access to this profile.' });
    }
    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    const { password, ...safeUser } = user.toObject();
    res.json(safeUser);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update User Profile (name, guardianName, phone, region, language — not password)
app.put('/api/users/:userId', requireAuth, async (req, res) => {
  try {
    if (req.params.userId !== req.userId) {
      return res.status(403).json({ error: 'You do not have access to this profile.' });
    }
    const { name, guardianName, phone, region, language } = req.body;
    console.log(`[PUT] /api/users/${req.params.userId}`);
    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    if (name !== undefined) user.name = name;
    if (guardianName !== undefined) user.guardianName = guardianName;
    if (phone !== undefined) user.phone = phone;
    if (region !== undefined) user.region = region;
    if (language !== undefined) user.language = language;
    await user.save();
    const { password, ...safeUser } = user.toObject();
    res.json(safeUser);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Change Password
app.post('/api/users/:userId/change-password', requireAuth, async (req, res) => {
  try {
    if (req.params.userId !== req.userId) {
      return res.status(403).json({ error: 'You do not have access to this profile.' });
    }
    const { currentPassword, newPassword } = req.body;
    console.log(`[POST] /api/users/${req.params.userId}/change-password`);

    if (!newPassword || newPassword.length < 8) {
      return res.status(400).json({ error: 'New password must be at least 8 characters.' });
    }

    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const currentMatches = await verifyPassword(currentPassword, user.password);
    if (!currentMatches) {
      return res.status(401).json({ error: 'Current password is incorrect.' });
    }

    user.password = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    await user.save();
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get Fields List
app.get('/api/fields', requireAuth, async (req, res) => {
  try {
    const { ownerId } = req.query;
    console.log(`[GET] /api/fields for ownerId: ${ownerId}`);
    if (!ownerId) {
      return res.status(400).json({ error: 'ownerId is required.' });
    }
    if (ownerId !== req.userId) {
      return res.status(403).json({ error: 'You do not have access to this farmer\'s fields.' });
    }
    const fields = await Field.find({ ownerId });
    res.json(fields.map(f => ({
      id: f._id,
      ownerId: f.ownerId,
      name: f.name,
      area: f.area,
      latitude: f.latitude,
      longitude: f.longitude,
      boundaryPoints: f.boundaryPoints,
      soilType: f.soilType,
      healthStatus: f.healthStatus,
      activeCrops: f.activeCrops,
      pendingActions: f.pendingActions,
      createdAt: f.createdAt.toISOString()
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Add Field — ownerId is always the authenticated user, never trusted
// from the request body, so a farmer can't create a field under
// someone else's account.
app.post('/api/fields', requireAuth, async (req, res) => {
  try {
    const { id, name, area, latitude, longitude, boundaryPoints, soilType } = req.body;
    console.log(`[POST] /api/fields adding field: ${name}`);
    const field = new Field({
      _id: id || new mongoose.Types.ObjectId().toString(),
      ownerId: req.userId,
      name,
      area,
      latitude,
      longitude,
      boundaryPoints,
      soilType
    });
    await field.save();
    res.status(201).json({ id: field._id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update Field
app.put('/api/fields/:fieldId', requireAuth, async (req, res) => {
  try {
    console.log(`[PUT] /api/fields/${req.params.fieldId}`);
    const field = await ownsField(req, res, { fieldId: req.params.fieldId });
    if (!field) return;

    const { name, area, latitude, longitude, boundaryPoints, soilType } = req.body;
    if (name !== undefined) field.name = name;
    if (area !== undefined) field.area = area;
    if (latitude !== undefined) field.latitude = latitude;
    if (longitude !== undefined) field.longitude = longitude;
    if (boundaryPoints !== undefined) field.boundaryPoints = boundaryPoints;
    if (soilType !== undefined) field.soilType = soilType;
    await field.save();

    res.json({ id: field._id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete Field — refused if any crop still references it, to avoid
// orphaning crop/activity/financial records.
app.delete('/api/fields/:fieldId', requireAuth, async (req, res) => {
  try {
    console.log(`[DELETE] /api/fields/${req.params.fieldId}`);
    const field = await ownsField(req, res, { fieldId: req.params.fieldId });
    if (!field) return;

    const cropCount = await Crop.countDocuments({ fieldId: req.params.fieldId });
    if (cropCount > 0) {
      return res.status(409).json({
        error: `This field still has ${cropCount} crop(s) on it. Remove them before deleting the field.`
      });
    }

    await Field.findByIdAndDelete(req.params.fieldId);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get Crops List
app.get('/api/crops', requireAuth, async (req, res) => {
  try {
    const { fieldId } = req.query;
    console.log(`[GET] /api/crops for fieldId: ${fieldId}`);
    if (!fieldId) {
      return res.status(400).json({ error: 'fieldId is required.' });
    }
    const field = await ownsField(req, res, { fieldId });
    if (!field) return;

    const crops = await Crop.find({ fieldId });
    res.json(crops.map(c => ({
      id: c._id,
      fieldId: c.fieldId,
      season: c.season,
      cropName: c.cropName,
      variety: c.variety,
      sownDate: c.sownDate.toISOString(),
      expectedHarvestDate: c.expectedHarvestDate ? c.expectedHarvestDate.toISOString() : null,
      status: c.status,
      isIntercrop: c.isIntercrop,
      areaCovered: c.areaCovered,
      healthStatus: c.healthStatus,
      activityCount: c.activityCount
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Add Crop
app.post('/api/crops', requireAuth, async (req, res) => {
  try {
    const { id, fieldId, season, cropName, variety, sownDate, expectedHarvestDate, isIntercrop, areaCovered } = req.body;
    console.log(`[POST] /api/crops adding crop: ${cropName}`);
    const field = await ownsField(req, res, { fieldId });
    if (!field) return;

    const crop = new Crop({
      _id: id || new mongoose.Types.ObjectId().toString(),
      fieldId,
      season,
      cropName,
      variety,
      sownDate,
      expectedHarvestDate,
      isIntercrop,
      areaCovered
    });
    await crop.save();
    
    // Update active crops in parent field
    await Field.findByIdAndUpdate(fieldId, { $inc: { activeCrops: 1 } });
    
    res.status(201).json({ id: crop._id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update Crop
app.put('/api/crops/:cropId', requireAuth, async (req, res) => {
  try {
    console.log(`[PUT] /api/crops/${req.params.cropId}`);
    const field = await ownsField(req, res, { cropId: req.params.cropId });
    if (!field) return;

    const { season, cropName, variety, sownDate, expectedHarvestDate, status, isIntercrop, areaCovered } = req.body;
    const crop = await Crop.findById(req.params.cropId);

    if (season !== undefined) crop.season = season;
    if (cropName !== undefined) crop.cropName = cropName;
    if (variety !== undefined) crop.variety = variety;
    if (sownDate !== undefined) crop.sownDate = sownDate;
    if (expectedHarvestDate !== undefined) crop.expectedHarvestDate = expectedHarvestDate;
    if (status !== undefined) crop.status = status;
    if (isIntercrop !== undefined) crop.isIntercrop = isIntercrop;
    if (areaCovered !== undefined) crop.areaCovered = areaCovered;
    await crop.save();

    res.json({ id: crop._id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete Crop — refused if it has any logged activities, so a farmer
// can't accidentally lose activity history without realizing it.
app.delete('/api/crops/:cropId', requireAuth, async (req, res) => {
  try {
    console.log(`[DELETE] /api/crops/${req.params.cropId}`);
    const field = await ownsField(req, res, { cropId: req.params.cropId });
    if (!field) return;

    const crop = await Crop.findById(req.params.cropId);

    const activityCount = await Activity.countDocuments({ cropId: req.params.cropId });
    if (activityCount > 0) {
      const noun = activityCount === 1 ? 'activity' : 'activities';
      return res.status(409).json({
        error: `This crop has ${activityCount} logged ${noun}. Remove them before deleting the crop.`
      });
    }

    await Crop.findByIdAndDelete(req.params.cropId);
    await Financial.findOneAndDelete({ cropId: req.params.cropId });
    await Field.findByIdAndUpdate(crop.fieldId, { $inc: { activeCrops: -1 } });

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get Activities
app.get('/api/activities', requireAuth, async (req, res) => {
  try {
    const { cropId } = req.query;
    console.log(`[GET] /api/activities for cropId: ${cropId}`);
    if (!cropId) {
      return res.status(400).json({ error: 'cropId is required.' });
    }
    const field = await ownsField(req, res, { cropId });
    if (!field) return;

    const activities = await Activity.find({ cropId }).sort({ date: -1 });
    res.json(activities.map(a => ({
      id: a._id,
      cropId: a.cropId,
      type: a.type,
      subtype: a.subtype,
      date: a.date.toISOString(),
      areaCovered: a.areaCovered,
      areaUnit: a.areaUnit,
      notes: a.notes,
      cost: a.cost,
      quantity: a.quantity,
      unit: a.unit,
      createdBy: a.createdBy,
      attributes: a.attributes
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Log Activity
app.post('/api/activities', requireAuth, async (req, res) => {
  try {
    const { id, cropId, type, subtype, date, areaCovered, areaUnit, notes, cost, quantity, unit, attributes } = req.body;
    console.log(`[POST] /api/activities logging activity: ${type}`);
    const field = await ownsField(req, res, { cropId });
    if (!field) return;

    const activity = new Activity({
      _id: id || new mongoose.Types.ObjectId().toString(),
      cropId,
      type,
      subtype,
      date,
      areaCovered,
      areaUnit,
      notes,
      cost,
      quantity,
      unit,
      createdBy: req.userId,
      attributes
    });
    await activity.save();
    
    // Increment activity count for Crop
    await Crop.findByIdAndUpdate(cropId, { $inc: { activityCount: 1 } });
    
    // Update inputCost in Financials
    if (cost) {
      await Financial.findOneAndUpdate(
        { cropId },
        { $inc: { inputCost: cost } },
        { upsert: true }
      );
    }
    
    res.status(201).json({ id: activity._id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update Activity
app.put('/api/activities/:activityId', requireAuth, async (req, res) => {
  try {
    console.log(`[PUT] /api/activities/${req.params.activityId}`);
    const field = await ownsField(req, res, { activityId: req.params.activityId });
    if (!field) return;

    const { type, subtype, date, areaCovered, areaUnit, notes, cost, quantity, unit, attributes } = req.body;
    const activity = await Activity.findById(req.params.activityId);

    const oldCost = activity.cost || 0;
    const newCost = cost || 0;
    const costDelta = newCost - oldCost;

    activity.type = type;
    activity.subtype = subtype;
    activity.date = date;
    activity.areaCovered = areaCovered;
    activity.areaUnit = areaUnit;
    activity.notes = notes;
    activity.cost = cost;
    activity.quantity = quantity;
    activity.unit = unit;
    activity.attributes = attributes;
    await activity.save();

    if (costDelta !== 0) {
      await Financial.findOneAndUpdate(
        { cropId: activity.cropId },
        { $inc: { inputCost: costDelta } },
        { upsert: true }
      );
    }

    res.json({ id: activity._id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete Activity
app.delete('/api/activities/:activityId', requireAuth, async (req, res) => {
  try {
    console.log(`[DELETE] /api/activities/${req.params.activityId}`);
    const field = await ownsField(req, res, { activityId: req.params.activityId });
    if (!field) return;

    const activity = await Activity.findByIdAndDelete(req.params.activityId);

    await Crop.findByIdAndUpdate(activity.cropId, { $inc: { activityCount: -1 } });

    if (activity.cost) {
      await Financial.findOneAndUpdate(
        { cropId: activity.cropId },
        { $inc: { inputCost: -activity.cost } },
        { upsert: true }
      );
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get Financials
app.get('/api/financials/:cropId', requireAuth, async (req, res) => {
  try {
    console.log(`[GET] /api/financials for cropId: ${req.params.cropId}`);
    const field = await ownsField(req, res, { cropId: req.params.cropId });
    if (!field) return;

    let fin = await Financial.findOne({ cropId: req.params.cropId });
    if (!fin) {
      fin = new Financial({
        _id: new mongoose.Types.ObjectId().toString(),
        cropId: req.params.cropId,
        inputCost: 0,
        expectedRevenue: 0,
        actualRevenue: 0
      });
      await fin.save();
    }
    res.json({
      id: fin._id,
      cropId: fin.cropId,
      inputCost: fin.inputCost,
      expectedRevenue: fin.expectedRevenue,
      actualRevenue: fin.actualRevenue,
      updatedAt: fin.updatedAt.toISOString()
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Update Financials
app.put('/api/financials/:cropId', requireAuth, async (req, res) => {
  try {
    console.log(`[PUT] /api/financials for cropId: ${req.params.cropId}`);
    const field = await ownsField(req, res, { cropId: req.params.cropId });
    if (!field) return;

    const { inputCost, expectedRevenue, actualRevenue } = req.body;
    const fin = await Financial.findOneAndUpdate(
      { cropId: req.params.cropId },
      { 
        inputCost, 
        expectedRevenue, 
        actualRevenue, 
        updatedAt: new Date() 
      },
      { new: true, upsert: true }
    );
    res.json(fin);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * Confirms the authenticated user owns the thing an action point's
 * scope/refId points at (farmer=self, field=their field, crop=their
 * crop's field). Returns true on success, or sends a 403/404/400 and
 * returns false — callers should `return` immediately when false.
 */
async function ownsActionPointRef(req, res, scope, refId) {
  if (!scope || !refId) {
    res.status(400).json({ error: 'scope and refId are required.' });
    return false;
  }
  if (scope === 'farmer') {
    if (refId !== req.userId) {
      res.status(403).json({ error: 'You do not have access to this resource.' });
      return false;
    }
    return true;
  }
  if (scope === 'field') {
    const field = await ownsField(req, res, { fieldId: refId });
    return !!field;
  }
  if (scope === 'crop') {
    const field = await ownsField(req, res, { cropId: refId });
    return !!field;
  }
  res.status(400).json({ error: 'scope must be one of: farmer, field, crop' });
  return false;
}

// Get Action Points
app.get('/api/action-points', requireAuth, async (req, res) => {
  try {
    const { scope, refId } = req.query;
    console.log(`[GET] /api/action-points scope=${scope}, refId=${refId}`);
    const owns = await ownsActionPointRef(req, res, scope, refId);
    if (!owns) return;

    const aps = await ActionPoint.find({ scope, refId, resolved: false });
    res.json(aps.map(ap => ({
      id: ap._id,
      scope: ap.scope,
      refId: ap.refId,
      message: ap.message,
      priority: ap.priority,
      dueDate: ap.dueDate ? ap.dueDate.toISOString() : null,
      category: ap.category,
      resolved: ap.resolved,
      createdAt: ap.createdAt.toISOString()
    })));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Resolve Action Point
app.put('/api/action-points/:apId/resolve', requireAuth, async (req, res) => {
  try {
    console.log(`[PUT] /api/action-points/resolve: ${req.params.apId}`);
    const existing = await ActionPoint.findById(req.params.apId);
    if (!existing) {
      return res.status(404).json({ error: 'Action point not found' });
    }
    const owns = await ownsActionPointRef(req, res, existing.scope, existing.refId);
    if (!owns) return;

    const ap = await ActionPoint.findByIdAndUpdate(
      req.params.apId,
      { resolved: true },
      { new: true }
    );
    res.json(ap);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Submit an Issue Report (farmer-facing — requires login, but no admin key)
app.post('/api/issue-reports', requireAuth, async (req, res) => {
  try {
    const { userName, userPhone, message } = req.body;
    console.log(`[POST] /api/issue-reports from userId: ${req.userId}`);

    if (!userName || !userPhone || !message) {
      return res.status(400).json({ error: 'userName, userPhone, and message are required.' });
    }
    if (message.length > 1000) {
      return res.status(400).json({ error: 'Message must be 1000 characters or fewer.' });
    }

    const report = new IssueReport({
      _id: new mongoose.Types.ObjectId().toString(),
      userId: req.userId,
      userName,
      userPhone,
      message: message.trim()
    });
    await report.save();

    res.status(201).json({ id: report._id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Database Seeder ─────────────────────────────────────────

async function seedDatabase() {
  try {
    const userCount = await User.countDocuments();
    if (userCount > 0) {
      console.log('Database already has data. Skipping seeding.');
      return;
    }
    
    console.log('Database is empty. Seeding baseline mock data...');

    // 1. Seed user
    const defaultUser = new User({
      _id: 'user_001',
      phone: '+91 98765 43210',
      name: 'Rajesh Kumar',
      password: 'password123',
      language: 'en',
      region: 'Pune, Maharashtra',
      createdAt: new Date('2025-03-15T00:00:00.000Z')
    });
    await defaultUser.save();

    // 2. Seed fields
    const defaultFields = [
      new Field({
        _id: 'field_001',
        ownerId: 'user_001',
        name: 'North Field',
        area: 2.5,
        latitude: 18.5204,
        longitude: 73.8567,
        soilType: 'Black Cotton',
        healthStatus: 'good',
        activeCrops: 2,
        pendingActions: 3,
        createdAt: new Date('2025-03-20T00:00:00.000Z')
      }),
      new Field({
        _id: 'field_002',
        ownerId: 'user_001',
        name: 'Riverside Plot',
        area: 1.8,
        latitude: 18.5250,
        longitude: 73.8600,
        soilType: 'Alluvial',
        healthStatus: 'moderate',
        activeCrops: 1,
        pendingActions: 5,
        createdAt: new Date('2025-04-10T00:00:00.000Z')
      }),
      new Field({
        _id: 'field_003',
        ownerId: 'user_001',
        name: 'Hill Terrace',
        area: 3.2,
        latitude: 18.5300,
        longitude: 73.8650,
        soilType: 'Red Laterite',
        healthStatus: 'poor',
        activeCrops: 1,
        pendingActions: 7,
        createdAt: new Date('2025-05-01T00:00:00.000Z')
      })
    ];
    await Field.insertMany(defaultFields);

    // 3. Seed crops
    const defaultCrops = [
      new Crop({
        _id: 'crop_001',
        fieldId: 'field_001',
        season: 'Kharif 2026',
        cropName: 'Rice (Paddy)',
        variety: 'Basmati 1121',
        sownDate: new Date('2026-06-15T00:00:00.000Z'),
        expectedHarvestDate: new Date('2026-10-20T00:00:00.000Z'),
        status: 'active',
        healthStatus: 'good',
        activityCount: 6
      }),
      new Crop({
        _id: 'crop_002',
        fieldId: 'field_001',
        season: 'Kharif 2026',
        cropName: 'Cotton',
        variety: 'Bt Cotton (Bollgard II)',
        sownDate: new Date('2026-06-01T00:00:00.000Z'),
        expectedHarvestDate: new Date('2026-11-30T00:00:00.000Z'),
        status: 'active',
        healthStatus: 'moderate',
        activityCount: 2
      }),
      new Crop({
        _id: 'crop_003',
        fieldId: 'field_002',
        season: 'Kharif 2026',
        cropName: 'Soybean',
        variety: 'JS-9560',
        sownDate: new Date('2026-06-20T00:00:00.000Z'),
        expectedHarvestDate: new Date('2026-10-15T00:00:00.000Z'),
        status: 'active',
        healthStatus: 'good',
        activityCount: 0
      }),
      new Crop({
        _id: 'crop_004',
        fieldId: 'field_003',
        season: 'Kharif 2026',
        cropName: 'Sugarcane',
        variety: 'CoM 0265',
        sownDate: new Date('2026-02-10T00:00:00.000Z'),
        expectedHarvestDate: new Date('2027-01-15T00:00:00.000Z'),
        status: 'active',
        healthStatus: 'poor',
        activityCount: 0
      })
    ];
    await Crop.insertMany(defaultCrops);

    // 4. Seed activities
    const defaultActivities = [
      new Activity({
        _id: 'act_001',
        cropId: 'crop_001',
        type: 'SOWING',
        subtype: 'SW_TRANSPLANT',
        date: new Date('2026-06-15T00:00:00.000Z'),
        notes: 'Transplanted nursery seedlings to main field',
        cost: 3500,
        quantity: 25,
        unit: 'kg',
        createdBy: 'user_001'
      }),
      new Activity({
        _id: 'act_002',
        cropId: 'crop_001',
        type: 'IRRIGATION',
        subtype: 'IR_FLOOD',
        date: new Date('2026-06-22T00:00:00.000Z'),
        notes: 'First irrigation after transplanting',
        cost: 500,
        quantity: 2000,
        unit: 'liters',
        createdBy: 'user_001'
      }),
      new Activity({
        _id: 'act_003',
        cropId: 'crop_001',
        type: 'NUTRIENT',
        subtype: 'NU_BASAL',
        date: new Date('2026-07-01T00:00:00.000Z'),
        notes: 'Applied DAP fertilizer (first dose)',
        cost: 1800,
        quantity: 50,
        unit: 'kg',
        createdBy: 'user_001'
      }),
      new Activity({
        _id: 'act_004',
        cropId: 'crop_001',
        type: 'PLANT_PROTECT',
        subtype: 'PP_INSECTICIDE',
        date: new Date('2026-07-15T00:00:00.000Z'),
        notes: 'Sprayed Chlorantraniliprole for stem borer prevention',
        cost: 1200,
        quantity: 500,
        unit: 'ml',
        createdBy: 'user_001'
      }),
      new Activity({
        _id: 'act_005',
        cropId: 'crop_001',
        type: 'WEED',
        subtype: 'WD_MANUAL',
        date: new Date('2026-07-20T00:00:00.000Z'),
        notes: 'Manual weeding by laborers',
        cost: 2500,
        createdBy: 'user_001'
      }),
      new Activity({
        _id: 'act_006',
        cropId: 'crop_001',
        type: 'IRRIGATION',
        subtype: 'IR_FLOOD',
        date: new Date('2026-07-28T00:00:00.000Z'),
        notes: 'Second irrigation cycle',
        cost: 500,
        quantity: 2000,
        unit: 'liters',
        createdBy: 'user_001'
      }),
      new Activity({
        _id: 'act_007',
        cropId: 'crop_002',
        type: 'SOWING',
        subtype: 'SW_BROADCAST',
        date: new Date('2026-06-01T00:00:00.000Z'),
        notes: 'Direct seeding of Bt Cotton seeds',
        cost: 4500,
        quantity: 2,
        unit: 'packets',
        createdBy: 'user_001'
      }),
      new Activity({
        _id: 'act_008',
        cropId: 'crop_002',
        type: 'NUTRIENT',
        subtype: 'NU_BASAL',
        date: new Date('2026-06-25T00:00:00.000Z'),
        notes: 'Applied Urea (first dose)',
        cost: 900,
        quantity: 30,
        unit: 'kg',
        createdBy: 'user_001'
      })
    ];
    await Activity.insertMany(defaultActivities);

    // 5. Seed Action Points
    const defaultActionPoints = [
      new ActionPoint({
        _id: 'ap_001',
        scope: 'crop',
        refId: 'crop_001',
        message: 'Apply second dose of Urea fertilizer — optimal window in 3 days',
        priority: 'high',
        dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
        category: 'fertilizer',
        createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000)
      }),
      new ActionPoint({
        _id: 'ap_002',
        scope: 'field',
        refId: 'field_002',
        message: 'Weather alert: Heavy rain expected in 2 days — delay pesticide spray',
        priority: 'high',
        dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000),
        category: 'weather',
        createdAt: new Date()
      }),
      new ActionPoint({
        _id: 'ap_003',
        scope: 'crop',
        refId: 'crop_004',
        message: 'Sugarcane showing signs of red rot — inspect and treat immediately',
        priority: 'high',
        dueDate: new Date(),
        category: 'pest',
        createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000)
      }),
      new ActionPoint({
        _id: 'ap_004',
        scope: 'farmer',
        refId: 'user_001',
        message: 'Soil testing recommended for Hill Terrace field — last test 6 months ago',
        priority: 'medium',
        dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        category: 'soil',
        createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000)
      })
    ];
    await ActionPoint.insertMany(defaultActionPoints);

    // 6. Seed Financials
    const defaultFinancials = [
      new Financial({
        _id: 'fin_001',
        cropId: 'crop_001',
        inputCost: 10000,
        expectedRevenue: 35000,
        actualRevenue: 0
      }),
      new Financial({
        _id: 'fin_002',
        cropId: 'crop_002',
        inputCost: 8200,
        expectedRevenue: 28000,
        actualRevenue: 0
      }),
      new Financial({
        _id: 'fin_003',
        cropId: 'crop_003',
        inputCost: 5500,
        expectedRevenue: 18000,
        actualRevenue: 0
      }),
      new Financial({
        _id: 'fin_004',
        cropId: 'crop_004',
        inputCost: 22000,
        expectedRevenue: 75000,
        actualRevenue: 0
      })
    ];
    await Financial.insertMany(defaultFinancials);

    console.log('Seeding completed successfully!');
  } catch (err) {
    console.error('Error seeding database:', err.message);
  }
}

// Start Server
app.listen(PORT, () => {
  console.log(`Sustainn backend listening on port ${PORT}`);
});
