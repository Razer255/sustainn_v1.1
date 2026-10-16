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
                      className="flex items-start gap-3 rounded-xl border border-gray-200 bg-white p-4 shadow-sm"
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
    </div>
  );
}
