'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import type { AdminActionPoint } from '@/lib/backend';

const priorityColor: Record<string, string> = {
  high: 'bg-red-100 text-red-700',
  medium: 'bg-amber-100 text-amber-700',
  low: 'bg-gray-100 text-gray-700',
};

export default function ActionPointsList({ actionPoints }: { actionPoints: AdminActionPoint[] }) {
  const [statusFilter, setStatusFilter] = useState<'all' | 'open' | 'resolved'>('open');

  const filtered = useMemo(() => {
    if (statusFilter === 'all') return actionPoints;
    const wantResolved = statusFilter === 'resolved';
    return actionPoints.filter((ap) => ap.resolved === wantResolved);
  }, [actionPoints, statusFilter]);

  const openCount = actionPoints.filter((ap) => !ap.resolved).length;
  const resolvedCount = actionPoints.length - openCount;

  return (
    <div className="mb-8">
      <div className="mb-4 flex flex-wrap items-center gap-3">
        <div className="flex gap-2">
          {([
            ['open', `Open (${openCount})`],
            ['resolved', `Resolved (${resolvedCount})`],
            ['all', `All (${actionPoints.length})`],
          ] as const).map(([value, label]) => (
            <button
              key={value}
              onClick={() => setStatusFilter(value)}
              className={`rounded-lg border px-3 py-1.5 text-sm font-medium ${
                statusFilter === value
                  ? 'border-gray-900 bg-gray-900 text-white'
                  : 'border-gray-200 text-gray-600 hover:bg-gray-50'
              }`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {filtered.length === 0 ? (
        <div className="rounded-xl border border-gray-200 bg-white p-8 text-center text-sm text-gray-500 shadow-sm">
          No action points here.
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map((ap) => (
            <div
              key={ap.id}
              className="flex items-start gap-3 rounded-xl border border-gray-200 bg-white p-4 shadow-sm"
            >
              <span
                className={`mt-0.5 shrink-0 rounded-full px-2 py-0.5 text-xs font-medium capitalize ${
                  priorityColor[ap.priority] ?? 'bg-gray-100 text-gray-700'
                }`}
              >
                {ap.priority}
              </span>
              <div className="min-w-0 flex-1">
                <p className="text-sm text-gray-900">{ap.message}</p>
                <div className="mt-1 flex flex-wrap items-center gap-x-2 gap-y-0.5 text-xs text-gray-500">
                  <span className="capitalize">{ap.scope}</span>
                  {ap.ownerId ? (
                    <>
                      ·{' '}
                      <Link href={`/users/${ap.ownerId}`} className="text-blue-600 hover:underline">
                        {ap.ownerName ?? ap.ownerId}
                      </Link>
                    </>
                  ) : (
                    <span>· Unknown owner</span>
                  )}
                  {ap.fieldName && <span>· {ap.fieldName}</span>}
                  {ap.cropName && <span>· {ap.cropName}</span>}
                  {ap.category && <span>· {ap.category}</span>}
                  {ap.dueDate && <span>· due {new Date(ap.dueDate).toLocaleDateString()}</span>}
                  <span>· created {new Date(ap.createdAt).toLocaleDateString()}</span>
                </div>
              </div>
              <span
                className={`mt-0.5 shrink-0 rounded-full px-2 py-0.5 text-xs font-medium ${
                  ap.resolved ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'
                }`}
              >
                {ap.resolved ? 'Resolved' : 'Open'}
              </span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
