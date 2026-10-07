import { getCrops } from '@/lib/backend';

export default async function CropsPage() {
  const crops = await getCrops();

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-gray-900">Crops ({crops.length})</h1>
      <div className="overflow-x-auto rounded-xl border border-gray-200 bg-white shadow-sm">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-gray-200 bg-gray-50 text-xs uppercase text-gray-500">
            <tr>
              <th className="px-4 py-3">Crop</th>
              <th className="px-4 py-3">Variety</th>
              <th className="px-4 py-3">Field ID</th>
              <th className="px-4 py-3">Season</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Sown</th>
              <th className="px-4 py-3">Expected harvest</th>
              <th className="px-4 py-3">Activities</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {crops.map((c) => (
              <tr key={c.id}>
                <td className="px-4 py-3 font-medium text-gray-900">{c.cropName}</td>
                <td className="px-4 py-3 text-gray-600">{c.variety}</td>
                <td className="px-4 py-3 text-gray-600">{c.fieldId}</td>
                <td className="px-4 py-3 text-gray-600">{c.season}</td>
                <td className="px-4 py-3 text-gray-600">{c.status}</td>
                <td className="px-4 py-3 text-gray-600">
                  {new Date(c.sownDate).toLocaleDateString()}
                </td>
                <td className="px-4 py-3 text-gray-600">
                  {c.expectedHarvestDate
                    ? new Date(c.expectedHarvestDate).toLocaleDateString()
                    : '—'}
                </td>
                <td className="px-4 py-3 text-gray-600">{c.activityCount}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
