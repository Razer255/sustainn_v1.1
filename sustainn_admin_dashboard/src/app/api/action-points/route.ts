import { NextResponse } from 'next/server';
import type { NewActionPoint } from '@/lib/backend';

const BACKEND_URL = process.env.BACKEND_URL;
const ADMIN_API_KEY = process.env.ADMIN_API_KEY;

export async function POST(req: Request) {
  if (!BACKEND_URL || !ADMIN_API_KEY) {
    return NextResponse.json({ error: 'BACKEND_URL or ADMIN_API_KEY is not configured' }, { status: 500 });
  }

  const data = (await req.json()) as NewActionPoint;

  const res = await fetch(`${BACKEND_URL}/api/admin/action-points`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-admin-key': ADMIN_API_KEY },
    body: JSON.stringify(data),
  });

  const body = await res.json().catch(() => ({}));
  return NextResponse.json(body, { status: res.status });
}
