'use client';

import { useState } from 'react';
import type { AdminUser, AdminField, AdminCrop } from '@/lib/backend';

type Scope = 'farmer' | 'field' | 'crop';

export default function NewActionPointForm({ users }: { users: AdminUser[] }) {
  const [userId, setUserId] = useState('');
  const [scope, setScope] = useState<Scope>('farmer');
  const [refId, setRefId] = useState('');
  const [message, setMessage] = useState('');
  const [priority, setPriority] = useState<'high' | 'medium' | 'low'>('medium');
  const [category, setCategory] = useState('');
  const [dueDate, setDueDate] = useState('');

  const [fields, setFields] = useState<AdminField[]>([]);
  const [crops, setCrops] = useState<AdminCrop[]>([]);
  const [loadingDetail, setLoadingDetail] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  async function onUserChange(id: string) {
    setUserId(id);
    setRefId(scope === 'farmer' ? id : '');
    setFields([]);
    setCrops([]);
    if (!id) return;

    setLoadingDetail(true);
    try {
      const res = await fetch(`/api/users/${id}/detail`);
      if (!res.ok) throw new Error('Failed to load farmer details');
      const detail = await res.json();
      setFields(detail.fields);
      setCrops(detail.crops);
    } catch {
      setResult({ type: 'error', text: "Couldn't load this farmer's fields/crops." });
    } finally {
      setLoadingDetail(false);
    }
  }

  function onScopeChange(next: Scope) {
    setScope(next);
    setRefId(next === 'farmer' ? userId : '');
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!refId || !message.trim()) {
      setResult({ type: 'error', text: 'Please fill in all required fields.' });
      return;
    }

    setSubmitting(true);
    setResult(null);
    try {
      const res = await fetch('/api/action-points', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          scope,
          refId,
          message: message.trim(),
          priority,
          category: category.trim() || undefined,
          dueDate: dueDate ? new Date(dueDate).toISOString() : undefined,
        }),
      });
      const body = await res.json();
      if (!res.ok) throw new Error(body.error ?? 'Failed to create action point');

      setResult({ type: 'success', text: 'Action point created.' });
      setMessage('');
      setCategory('');
      setDueDate('');
    } catch (err) {
      setResult({ type: 'error', text: (err as Error).message });
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form
      onSubmit={onSubmit}
      className="max-w-xl space-y-4 rounded-xl border border-gray-200 bg-white p-5 shadow-sm"
    >
      <div>
        <label className="mb-1 block text-xs font-medium text-gray-500">Farmer</label>
        <select
          value={userId}
          onChange={(e) => onUserChange(e.target.value)}
          required
          className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm text-gray-900 focus:border-gray-400 focus:outline-none"
        >
          <option value="">Select a farmer…</option>
          {users.map((u) => (
            <option key={u.id} value={u.id}>
              {u.name} — {u.phone}
            </option>
          ))}
        </select>
      </div>

      <div>
        <label className="mb-1 block text-xs font-medium text-gray-500">Applies to</label>
        <div className="flex gap-2">
          {(['farmer', 'field', 'crop'] as Scope[]).map((s) => (
            <button
              key={s}
              type="button"
              onClick={() => onScopeChange(s)}
              className={`rounded-lg border px-3 py-1.5 text-sm font-medium capitalize ${
                scope === s
                  ? 'border-gray-900 bg-gray-900 text-white'
                  : 'border-gray-200 text-gray-600 hover:bg-gray-50'
              }`}
            >
              {s}
            </button>
          ))}
        </div>
      </div>

      {scope === 'field' && (
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-500">Field</label>
          <select
            value={refId}
            onChange={(e) => setRefId(e.target.value)}
            required
            disabled={!userId || loadingDetail}
            className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm text-gray-900 focus:border-gray-400 focus:outline-none disabled:opacity-50"
          >
            <option value="">
              {loadingDetail ? 'Loading…' : !userId ? 'Select a farmer first' : 'Select a field…'}
            </option>
            {fields.map((f) => (
              <option key={f.id} value={f.id}>
                {f.name}
              </option>
            ))}
          </select>
        </div>
      )}

      {scope === 'crop' && (
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-500">Crop</label>
          <select
            value={refId}
            onChange={(e) => setRefId(e.target.value)}
            required
            disabled={!userId || loadingDetail}
            className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm text-gray-900 focus:border-gray-400 focus:outline-none disabled:opacity-50"
          >
            <option value="">
              {loadingDetail ? 'Loading…' : !userId ? 'Select a farmer first' : 'Select a crop…'}
            </option>
            {crops.map((c) => {
              const field = fields.find((f) => f.id === c.fieldId);
              return (
                <option key={c.id} value={c.id}>
                  {c.cropName} ({field?.name ?? 'unknown field'})
                </option>
              );
            })}
          </select>
        </div>
      )}

      <div>
        <label className="mb-1 block text-xs font-medium text-gray-500">Message</label>
        <textarea
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          required
          rows={3}
          placeholder="e.g. Apply second dose of Urea fertilizer — optimal window in 3 days"
          className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm text-gray-900 placeholder:text-gray-400 focus:border-gray-400 focus:outline-none"
        />
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-500">Priority</label>
          <select
            value={priority}
            onChange={(e) => setPriority(e.target.value as 'high' | 'medium' | 'low')}
            className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm text-gray-900 focus:border-gray-400 focus:outline-none"
          >
            <option value="high">High</option>
            <option value="medium">Medium</option>
            <option value="low">Low</option>
          </select>
        </div>
        <div>
          <label className="mb-1 block text-xs font-medium text-gray-500">Due date (optional)</label>
          <input
            type="date"
            value={dueDate}
            onChange={(e) => setDueDate(e.target.value)}
            className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm text-gray-900 focus:border-gray-400 focus:outline-none"
          />
        </div>
      </div>

      <div>
        <label className="mb-1 block text-xs font-medium text-gray-500">Category (optional)</label>
        <input
          type="text"
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          placeholder="e.g. fertilizer, weather, pest, soil"
          className="w-full rounded-lg border border-gray-200 px-3 py-2 text-sm text-gray-900 placeholder:text-gray-400 focus:border-gray-400 focus:outline-none"
        />
      </div>

      {result && (
        <p className={`text-sm ${result.type === 'success' ? 'text-green-600' : 'text-red-600'}`}>
          {result.text}
        </p>
      )}

      <button
        type="submit"
        disabled={submitting}
        className="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800 disabled:opacity-50"
      >
        {submitting ? 'Creating…' : 'Create action point'}
      </button>
    </form>
  );
}
