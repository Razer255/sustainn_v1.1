import Link from 'next/link';
import { getUsers } from '@/lib/backend';

export default async function UsersPage() {
  const users = await getUsers();

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-gray-900">Users ({users.length})</h1>
      <div className="overflow-x-auto rounded-xl border border-gray-200 bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-gray-200 bg-gray-50 text-xs uppercase text-gray-500">
            <tr>
              <th className="px-4 py-3">Name</th>
              <th className="px-4 py-3">Phone</th>
              <th className="px-4 py-3">Region</th>
              <th className="px-4 py-3">Language</th>
              <th className="px-4 py-3">Joined</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {users.map((u) => (
              <tr key={u.id} className="cursor-pointer hover:bg-gray-50">
                <td className="px-4 py-3 font-medium text-gray-900">
                  <Link href={`/users/${u.id}`} className="block hover:underline">
                    {u.name}
                  </Link>
                </td>
                <td className="px-4 py-3 text-gray-600">
                  <Link href={`/users/${u.id}`} className="block">{u.phone}</Link>
                </td>
                <td className="px-4 py-3 text-gray-600">
                  <Link href={`/users/${u.id}`} className="block">{u.region}</Link>
                </td>
                <td className="px-4 py-3 text-gray-600">
                  <Link href={`/users/${u.id}`} className="block">{u.language}</Link>
                </td>
                <td className="px-4 py-3 text-gray-600">
                  <Link href={`/users/${u.id}`} className="block">
                    {new Date(u.createdAt).toLocaleDateString()}
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
