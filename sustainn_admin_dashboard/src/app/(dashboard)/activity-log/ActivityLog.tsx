'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import type { AdminActivityLogEntry } from '@/lib/backend';
import { metaFor } from './activityMeta';

function dayLabel(iso: string) {
  const date = new Date(iso);
  const today = new Date();
  const yesterday = new Date();
  yesterday.setDate(today.getDate() - 1);

  const sameDay = (a: Date, b: Date) =>
    a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();

  if (sameDay(date, today)) return 'Today';
  if (sameDay(date, yesterday)) return 'Yesterday';
  return date.toLocaleDateString(undefined, { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
}

export default function ActivityLog({ entries }: { entries: AdminActivityLogEntry[] }) {
  const [search, setSearch] = useState('');
  const [typeFilter, setTypeFilter] = useState<string>('all');
  const [ownerFilter, setOwnerFilter] = useState<string>('all');
  const [selected, setSelected] = useState<AdminActivityLogEntry | null>(null);

  const types = useMemo(() => {
    const set = new Set(entries.map((e) => e.type));
    return Array.from(set).sort();
  }, [entries]);

  const owners = useMemo(() => {
    const map = new Map<string, string>();
    for (const e of entries) {
      if (e.ownerId && e.ownerName) map.set(e.ownerId, e.ownerName);
    }
    return Array.from(map.entries()).sort((a, b) => a[1].localeCompare(b[1]));
  }, [entries]);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return entries.filter((e) => {
      if (typeFilter !== 'all' && e.type !== typeFilter) return false;
      if (ownerFilter !== 'all' && e.ownerId !== ownerFilter) return false;
      if (!q) return true;
      const haystack = [e.ownerName, e.cropName, e.fieldName, e.notes, e.type, e.subtype]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();
      return haystack.includes(q);
    });
  }, [entries, search, typeFilter, ownerFilter]);

  const grouped = useMemo(() => {
    const groups = new Map<string, AdminActivityLogEntry[]>();
    for (const e of filtered) {
      const key = new Date(e.date).toDateString();
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key)!.push(e);
    }
    return Array.from(groups.entries());
  }, [filtered]);

  return (
    <div>
      <div className="mb-5 flex flex-wrap gap-3">
        <input
          type="text"
          placeholder="Search farmer, crop, field, notes…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-64 rounded-lg border border-gray-200 px-3 py-2 text-sm focus:border-gray-400 focus:outline-none"
        />
        <select
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="rounded-lg border border-gray-200 px-3 py-2 text-sm focus:border-gray-400 focus:outline-none"
        >
          <option value="all">All activity types</option>
          {types.map((t) => (
            <option key={t} value={t}>
              {metaFor(t).emoji} {metaFor(t).label}
            </option>
          ))}
        </select>
        <select
          value={ownerFilter}
          onChange={(e) => setOwnerFilter(e.target.value)}
          className="rounded-lg border border-gray-200 px-3 py-2 text-sm focus:border-gray-400 focus:outline-none"
        >
          <option value="all">All farmers</option>
          {owners.map(([id, name]) => (
            <option key={id} value={id}>
              {name}
            </option>
          ))}
        </select>
        <span className="ml-auto self-center text-sm text-gray-500">
          {filtered.length} of {entries.length} activities
        </span>
      </div>

      {grouped.length === 0 ? (
        <div className="rounded-xl border border-gray-200 bg-white p-10 text-center text-sm text-gray-500 shadow-sm">
          No activities match these filters.
        </div>
      ) : (
        <div className="space-y-6">
          {grouped.map(([dayKey, dayEntries]) => (
            <div key={dayKey}>
              <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">
                {dayLabel(dayEntries[0].date)}
              </h3>
              <div className="space-y-2">
                {dayEntries.map((e) => {
                  const meta = metaFor(e.type);
                  return (
                    <div
                      key={e.id}
                      onClick={() => setSelected(e)}
                      className="flex cursor-pointer items-start gap-3 rounded-xl border border-gray-200 bg-white p-4 shadow-sm transition hover:border-gray-300 hover:shadow-md"
                    >
                      <div
                        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-base"
                        style={{ backgroundColor: `${meta.color}1A` }}
                      >
                        {meta.emoji}
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-x-2 gap-y-0.5">
                          <span className="text-sm font-medium text-gray-900">{meta.label}</span>
                          {e.subtype && <span className="text-xs text-gray-400">· {e.subtype}</span>}
                          <span className="text-xs text-gray-400">
                            · {new Date(e.date).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' })}
                          </span>
                        </div>
                        <div className="mt-0.5 text-xs text-gray-500">
                          {e.ownerId ? (
                            <Link href={`/users/${e.ownerId}`} className="text-blue-600 hover:underline">
                              {e.ownerName}
                            </Link>
                          ) : (
                            <span className="text-gray-400">Unknown farmer</span>
                          )}
                          {e.fieldName && <span> · {e.fieldName}</span>}
                          {e.cropName && <span> · {e.cropName}</span>}
                        </div>
                        {e.notes && <p className="mt-1 text-sm text-gray-700">{e.notes}</p>}
                        {(e.cost || e.quantity) && (
                          <div className="mt-1 flex gap-3 text-xs text-gray-500">
                            {e.cost ? <span>₹{e.cost.toLocaleString()}</span> : null}
                            {e.quantity ? (
                              <span>
                                {e.quantity.toLocaleString()} {e.unit ?? ''}
                              </span>
                            ) : null}
                          </div>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}

      {selected && <ActivityDetailModal entry={selected} onClose={() => setSelected(null)} />}
    </div>
  );
}

function ActivityDetailModal({
  entry,
  onClose,
}: {
  entry: AdminActivityLogEntry;
  onClose: () => void;
}) {
  const meta = metaFor(entry.type);
  const attributeEntries = entry.attributes ? Object.entries(entry.attributes) : [];

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
      onClick={onClose}
    >
      <div
        className="max-h-[85vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-white shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div
          className="flex items-start justify-between gap-3 rounded-t-2xl p-5"
          style={{ backgroundColor: `${meta.color}14` }}
        >
          <div className="flex items-center gap-3">
            <div
              className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full text-xl"
              style={{ backgroundColor: `${meta.color}2A` }}
            >
              {meta.emoji}
            </div>
            <div>
              <h2 className="text-lg font-semibold text-gray-900">{meta.label}</h2>
              {entry.subtype && <p className="text-xs text-gray-500">{entry.subtype}</p>}
            </div>
          </div>
          <button
            onClick={onClose}
            className="rounded-full p-1 text-gray-400 hover:bg-black/5 hover:text-gray-700"
            aria-label="Close"
          >
            ✕
          </button>
        </div>

        <div className="space-y-5 p-5">
          <DetailSection title="When">
            <DetailRow
              label="Date & time"
              value={new Date(entry.date).toLocaleString(undefined, {
                dateStyle: 'full',
                timeStyle: 'short',
              })}
            />
          </DetailSection>

          <DetailSection title="Farmer & location">
            <DetailRow
              label="Farmer"
              value={
                entry.ownerId ? (
                  <Link href={`/users/${entry.ownerId}`} className="text-blue-600 hover:underline">
                    {entry.ownerName}
                  </Link>
                ) : (
                  'Unknown'
                )
              }
            />
            {entry.ownerPhone && <DetailRow label="Phone" value={entry.ownerPhone} />}
            {entry.fieldName && <DetailRow label="Field" value={entry.fieldName} />}
            {entry.fieldArea != null && <DetailRow label="Field area" value={`${entry.fieldArea} acres`} />}
            {entry.fieldSoilType && <DetailRow label="Soil type" value={entry.fieldSoilType} />}
          </DetailSection>

          <DetailSection title="Crop">
            {entry.cropName && <DetailRow label="Crop" value={entry.cropName} />}
            {entry.cropVariety && <DetailRow label="Variety" value={entry.cropVariety} />}
            {entry.cropSeason && <DetailRow label="Season" value={entry.cropSeason} />}
          </DetailSection>

          <DetailSection title="Activity details">
            {entry.areaCovered != null && (
              <DetailRow label="Area covered" value={`${entry.areaCovered} ${entry.areaUnit ?? ''}`} />
            )}
            {entry.quantity != null && (
              <DetailRow label="Quantity" value={`${entry.quantity.toLocaleString()} ${entry.unit ?? ''}`} />
            )}
            {entry.cost != null && (
              <DetailRow label="Cost of this activity" value={`₹${entry.cost.toLocaleString()}`} />
            )}
            {entry.notes && <DetailRow label="Notes" value={entry.notes} />}
            {attributeEntries.length > 0 &&
              attributeEntries.map(([key, value]) => (
                <DetailRow key={key} label={formatAttributeKey(key)} value={formatAttributeValue(value)} />
              ))}
          </DetailSection>

          {(entry.cropInputCost != null ||
            entry.cropExpectedRevenue != null ||
            entry.cropActualRevenue != null) && (
            <DetailSection title="Farm investment (this crop, overall)">
              {entry.cropInputCost != null && (
                <DetailRow label="Total input cost" value={`₹${entry.cropInputCost.toLocaleString()}`} />
              )}
              {entry.cropExpectedRevenue != null && (
                <DetailRow
                  label="Expected revenue"
                  value={`₹${entry.cropExpectedRevenue.toLocaleString()}`}
                />
              )}
              {entry.cropActualRevenue != null && (
                <DetailRow label="Actual revenue so far" value={`₹${entry.cropActualRevenue.toLocaleString()}`} />
              )}
            </DetailSection>
          )}
        </div>
      </div>
    </div>
  );
}

function DetailSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">{title}</h3>
      <div className="space-y-1.5 rounded-xl border border-gray-100 bg-gray-50 p-3">{children}</div>
    </div>
  );
}

function DetailRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex justify-between gap-4 text-sm">
      <span className="text-gray-500">{label}</span>
      <span className="text-right font-medium text-gray-900">{value}</span>
    </div>
  );
}

function formatAttributeKey(key: string) {
  return key
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, (c) => c.toUpperCase())
    .trim();
}

function formatAttributeValue(value: unknown): string {
  if (value == null) return '—';
  if (Array.isArray(value)) return value.map((v) => formatAttributeValue(v)).join(', ');
  if (typeof value === 'object') return JSON.stringify(value);
  return String(value);
}
