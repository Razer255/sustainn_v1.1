'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';

const links = [
  { href: '/', label: 'Overview' },
  { href: '/users', label: 'Users' },
  { href: '/fields', label: 'Fields' },
  { href: '/crops', label: 'Crops' },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  async function logout() {
    await fetch('/api/login', { method: 'DELETE' });
    router.push('/login');
    router.refresh();
  }

  return (
    <aside className="flex h-screen w-56 flex-col border-r border-gray-200 bg-white px-4 py-6">
      <h2 className="mb-6 px-2 text-lg font-semibold text-gray-900">Sustainn Admin</h2>
      <nav className="flex-1 space-y-1">
        {links.map((link) => (
          <Link
            key={link.href}
            href={link.href}
            className={`block rounded-lg px-3 py-2 text-sm font-medium ${
              pathname === link.href
                ? 'bg-gray-900 text-white'
                : 'text-gray-600 hover:bg-gray-100'
            }`}
          >
            {link.label}
          </Link>
        ))}
      </nav>
      <button
        onClick={logout}
        className="rounded-lg px-3 py-2 text-left text-sm font-medium text-gray-500 hover:bg-gray-100"
      >
        Log out
      </button>
    </aside>
  );
}
