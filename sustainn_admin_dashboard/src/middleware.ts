import { NextResponse, type NextRequest } from 'next/server';
import { COOKIE_NAME, verifySessionToken } from '@/lib/session';

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  if (pathname.startsWith('/login') || pathname.startsWith('/api/login')) {
    return NextResponse.next();
  }

  const token = req.cookies.get(COOKIE_NAME)?.value;
  const valid = token ? await verifySessionToken(token) : false;

  if (!valid) {
    const loginUrl = new URL('/login', req.url);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
