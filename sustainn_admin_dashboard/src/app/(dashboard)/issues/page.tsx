import { getIssueReports } from '@/lib/backend';
import IssueReportsTable from './IssueReportsTable';

export default async function IssuesPage() {
  const reports = await getIssueReports();
  const openCount = reports.filter((r) => r.status === 'open').length;

  return (
    <div>
      <h1 className="mb-1 text-2xl font-semibold text-gray-900">Issue Reports</h1>
      <p className="mb-6 text-sm text-gray-500">
        {openCount} open · {reports.length} total
      </p>
      <IssueReportsTable initialReports={reports} />
    </div>
  );
}
