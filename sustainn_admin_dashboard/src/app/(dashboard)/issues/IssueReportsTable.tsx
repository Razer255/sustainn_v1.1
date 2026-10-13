'use client';

import { useState } from 'react';
import type { IssueReport } from '@/lib/backend';

const statusColor: Record<string, string> = {
  open: 'bg-amber-100 text-amber-700',
  resolved: 'bg-green-100 text-green-700',
};

export default function IssueReportsTable({ initialReports }: { initialReports: IssueReport[] }) {
  const [reports, setReports] = useState(initialReports);
  const [busyId, setBusyId] = useState<string | null>(null);

  async function resolve(id: string) {
    setBusyId(id);
    try {
      const res = await fetch(`/api/issue-reports/${id}`, { method: 'PUT' });
      if (!res.ok) throw new Error('Failed to resolve');
      setReports((prev) => prev.map((r) => (r.id === id ? { ...r, status: 'resolved' } : r)));
    } catch {
      alert('Could not mark as resolved. Please try again.');
    } finally {
      setBusyId(null);
    }
  }

  async function remove(id: string) {
    if (!confirm('Permanently delete this report? This cannot be undone.')) return;
    setBusyId(id);
    try {
      const res = await fetch(`/api/issue-reports/${id}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Failed to delete');
      setReports((prev) => prev.filter((r) => r.id !== id));
    } catch {
      alert('Could not delete. Please try again.');
    } finally {
      setBusyId(null);
    }
  }

  if (reports.length === 0) {
    return (
      <div className="rounded-xl border border-gray-200 bg-white p-10 text-center text-sm text-gray-500 shadow-sm">
        No issue reports.
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {reports.map((r) => (
        <div
          key={r.id}
          className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm"
        >
          <div className="mb-2 flex items-start justify-between gap-3">
            <div>
              <p className="text-sm font-medium text-gray-900">{r.userName}</p>
              <p className="text-xs text-gray-500">{r.userPhone} · {r.userId}</p>
            </div>
            <div className="flex items-center gap-2">
              <span className={`rounded-full px-2 py-1 text-xs font-medium ${statusColor[r.status]}`}>
                {r.status}
              </span>
              <span className="text-xs text-gray-400">
                {new Date(r.createdAt).toLocaleString()}
              </span>
            </div>
          </div>
          <p className="mb-3 whitespace-pre-wrap text-sm text-gray-700">{r.message}</p>
          <div className="flex gap-2">
            {r.status === 'open' && (
              <button
                onClick={() => resolve(r.id)}
                disabled={busyId === r.id}
                className="rounded-lg bg-gray-900 px-3 py-1.5 text-xs font-medium text-white hover:bg-gray-800 disabled:opacity-50"
              >
                Mark resolved
              </button>
            )}
            <button
              onClick={() => remove(r.id)}
              disabled={busyId === r.id}
              className="rounded-lg border border-red-200 px-3 py-1.5 text-xs font-medium text-red-600 hover:bg-red-50 disabled:opacity-50"
            >
              Delete
            </button>
          </div>
        </div>
      ))}
    </div>
  );
}
