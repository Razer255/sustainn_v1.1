const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

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

// ─── Location (LGD) proxy ───────────────────────────────────
// Proxies India's Local Government Directory (data.gov.in) so the Signup
// screen's State → District → Tehsil → Village cascade never ships the
// API key inside the Flutter client bundle.

const LGD_BASE = 'https://api.data.gov.in/resource';
const LGD_RESOURCES = {
  states: 'a71e60f0-a21d-43de-a6c5-fa5d21600cdb',
  districts: '37231365-78ba-44d5-ac22-3deec40b9197',
  subdistricts: '6be51a29-876a-403a-a6da-42fde795e751',
  villages: 'c967fe8f-69c4-42df-8afc-8a2c98057437',
};

// In-memory cache: level -> Map(parentCode -> [{code, name}])
// ('' as parentCode for the unfiltered States list). Cleared on restart.
const lgdCache = {
  states: new Map(),
  districts: new Map(),
  subdistricts: new Map(),
  villages: new Map(),
};

/**
 * Fetch and cache one LGD level, optionally filtered by a parent code.
 * @param {'states'|'districts'|'subdistricts'|'villages'} level
 * @param {{filterField?: string, filterValue?: string|number, codeField: string, nameField: string}} opts
 */
async function fetchLgdLevel(level, opts) {
  const cacheKey = opts.filterValue != null ? String(opts.filterValue) : '';
  const cache = lgdCache[level];
  if (cache.has(cacheKey)) return cache.get(cacheKey);

  const params = new URLSearchParams({
    'api-key': process.env.LGD_API_KEY,
    format: 'json',
    limit: '1000',
  });
  if (opts.filterField && opts.filterValue != null) {
    params.set(`filters[${opts.filterField}]`, String(opts.filterValue));
  }

  const url = `${LGD_BASE}/${LGD_RESOURCES[level]}?${params.toString()}`;
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`LGD upstream error (${level}): ${response.status}`);
  }
  const data = await response.json();
  const records = data.records || [];

  const options = records
    .map((r) => ({ code: r[opts.codeField], name: r[opts.nameField] }))
    .filter((o) => o.code != null && o.name)
    .sort((a, b) => String(a.name).localeCompare(String(b.name)));

  cache.set(cacheKey, options);
  return options;
}

app.get('/api/location/states', async (req, res) => {
  try {
    const options = await fetchLgdLevel('states', {
      codeField: 'state_code',
      nameField: 'state_name_english',
    });
    res.json(options);
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

app.get('/api/location/districts', async (req, res) => {
  try {
    const { stateCode } = req.query;
    if (!stateCode) return res.status(400).json({ error: 'stateCode is required' });
    const options = await fetchLgdLevel('districts', {
      filterField: 'state_code',
      filterValue: stateCode,
      codeField: 'district_code',
      nameField: 'district_name_english',
    });
    res.json(options);
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

app.get('/api/location/subdistricts', async (req, res) => {
  try {
    const { districtCode } = req.query;
    if (!districtCode) return res.status(400).json({ error: 'districtCode is required' });
    const options = await fetchLgdLevel('subdistricts', {
      filterField: 'district_code',
      filterValue: districtCode,
      codeField: 'subdistrict_code',
      nameField: 'subdistrict_name_english',
    });
    res.json(options);
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

app.get('/api/location/villages', async (req, res) => {
  try {
    const { subdistrictCode } = req.query;
    if (!subdistrictCode) return res.status(400).json({ error: 'subdistrictCode is required' });
    const options = await fetchLgdLevel('villages', {
      filterField: 'subdistrictCode', // camelCase on this resource, unlike the other three
      filterValue: subdistrictCode,
      codeField: 'villageCode',
      nameField: 'villageNameEnglish',
    });
    res.json(options);
  } catch (err) {
    res.status(502).json({ error: err.message });
  }
});

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
    const [userCount, fieldCount, cropCount, activityCount, actionPointCount] = await Promise.all([
      User.countDocuments(),
      Field.countDocuments(),
      Crop.countDocuments(),
      Activity.countDocuments(),
      ActionPoint.countDocuments({ resolved: false }),
    ]);
    res.json({ userCount, fieldCount, cropCount, activityCount, openActionPointCount: actionPointCount });
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

// ─── REST API Routes ──────────────────────────────────────────

// Auth Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { identifier, password } = req.body;
    console.log(`[POST] /api/auth/login with identifier: ${identifier}`);
    // Clean identifier to check match
    const cleanPhone = identifier.replace(/[^0-9]/g, '');
    let user = await User.findOne({ 
      $or: [
        { phone: identifier },
        { phone: new RegExp(cleanPhone + '$') }
      ] 
    });
    
    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials.' });
    }
    
    if (user.password && user.password !== password) {
      return res.status(401).json({ error: 'Invalid credentials.' });
    } else if (!user.password && password !== 'password123') {
      return res.status(401).json({ error: 'Invalid credentials.' });
    }
    
    res.json({
      token: 'mock_token_jwt_' + user._id,
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

// Create User Profile
app.post('/api/users', async (req, res) => {
  try {
    const { phone, name, guardianName, language, region, id, password } = req.body;
    console.log(`[POST] /api/users creating/updating userId: ${id}`);

    let user = await User.findById(id);
    if (user) {
      user.phone = phone;
      user.name = name;
      user.guardianName = guardianName;
      user.language = language;
      user.region = region;
      if (password) user.password = password;
      await user.save();
    } else {
      user = new User({ _id: id, phone, name, guardianName, language, region, password });
      await user.save();
    }
    res.status(201).json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get User Profile
app.get('/api/users/:userId', async (req, res) => {
  try {
    console.log(`[GET] /api/users/${req.params.userId}`);
    const user = await User.findById(req.params.userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get Fields List
app.get('/api/fields', async (req, res) => {
  try {
    const { ownerId } = req.query;
    console.log(`[GET] /api/fields for ownerId: ${ownerId}`);
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

// Add Field
app.post('/api/fields', async (req, res) => {
  try {
    const { id, ownerId, name, area, latitude, longitude, boundaryPoints, soilType } = req.body;
    console.log(`[POST] /api/fields adding field: ${name}`);
    const field = new Field({
      _id: id || new mongoose.Types.ObjectId().toString(),
      ownerId,
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

// Get Crops List
app.get('/api/crops', async (req, res) => {
  try {
    const { fieldId } = req.query;
    console.log(`[GET] /api/crops for fieldId: ${fieldId}`);
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
app.post('/api/crops', async (req, res) => {
  try {
    const { id, fieldId, season, cropName, variety, sownDate, expectedHarvestDate, isIntercrop, areaCovered } = req.body;
    console.log(`[POST] /api/crops adding crop: ${cropName}`);
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

// Get Activities
app.get('/api/activities', async (req, res) => {
  try {
    const { cropId } = req.query;
    console.log(`[GET] /api/activities for cropId: ${cropId}`);
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
app.post('/api/activities', async (req, res) => {
  try {
    const { id, cropId, type, subtype, date, areaCovered, areaUnit, notes, cost, quantity, unit, createdBy, attributes } = req.body;
    console.log(`[POST] /api/activities logging activity: ${type}`);
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
      createdBy,
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

// Get Financials
app.get('/api/financials/:cropId', async (req, res) => {
  try {
    console.log(`[GET] /api/financials for cropId: ${req.params.cropId}`);
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
app.put('/api/financials/:cropId', async (req, res) => {
  try {
    const { inputCost, expectedRevenue, actualRevenue } = req.body;
    console.log(`[PUT] /api/financials for cropId: ${req.params.cropId}`);
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

// Get Action Points
app.get('/api/action-points', async (req, res) => {
  try {
    const { scope, refId } = req.query;
    console.log(`[GET] /api/action-points scope=${scope}, refId=${refId}`);
    const query = { resolved: false };
    if (scope) query.scope = scope;
    if (refId) query.refId = refId;
    const aps = await ActionPoint.find(query);
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
app.put('/api/action-points/:apId/resolve', async (req, res) => {
  try {
    console.log(`[PUT] /api/action-points/resolve: ${req.params.apId}`);
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
