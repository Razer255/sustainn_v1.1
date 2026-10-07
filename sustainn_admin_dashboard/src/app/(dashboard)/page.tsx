import { getStats } from '@/lib/backend';

export default async function OverviewPage() {
  const stats = await getStats();

  const cards = [
    { label: 'Farmers', value: stats.userCount },
    { label: 'Fields', value: stats.fieldCount },
    { label: 'Crops', value: stats.cropCount },
    { label: 'Activities logged', value: stats.activityCount },
    { label: 'Open action points', value: stats.openActionPointCount },
  ];

  return (
    <div>
      <h1 className="mb-6 text-2xl font-semibold text-gray-900">Overview</h1>
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
        {cards.map((card) => (
          <div
            key={card.label}
            className="rounded-xl border border-gray-200 bg-white p-5 shadow-sm"
          >
            <p className="text-sm text-gray-500">{card.label}</p>
            <p className="mt-1 text-2xl font-semibold text-gray-900">{card.value}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
