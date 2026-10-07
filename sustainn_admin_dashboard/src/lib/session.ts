import { SignJWT, jwtVerify } from 'jose';

const COOKIE_NAME = 'sustainn_admin_session';
const ALG = 'HS256';

function getSecretKey() {
  const secret = process.env.SESSION_SECRET;
  if (!secret) throw new Error('SESSION_SECRET is not set');
  return new TextEncoder().encode(secret);
}

export async function createSessionToken(): Promise<string> {
  return new SignJWT({ role: 'admin' })
    .setProtectedHeader({ alg: ALG })
    .setIssuedAt()
    .setExpirationTime('12h')
    .sign(getSecretKey());
}

export async function verifySessionToken(token: string): Promise<boolean> {
  try {
    await jwtVerify(token, getSecretKey());
    return true;
  } catch {
    return false;
  }
}

export { COOKIE_NAME };
