/**
 * Human labels and chip colors for RiderStatus values from the backend.
 * Keep in sync with Presso.API/Domain/Enums/RiderStatus.cs
 */

export const RIDER_STATUS_LABEL: Record<string, string> = {
  Pending: 'Pending review',
  Approved: 'Approved',
  Suspended: 'Suspended',
  Rejected: 'Rejected',
};

export const RIDER_STATUS_COLOR: Record<string, string> = {
  Pending: '#f59e0b',   // amber
  Approved: '#10b981',  // green
  Suspended: '#ef4444', // red
  Rejected: '#64748b',  // slate
};

export function riderStatusLabel(status: string | null | undefined): string {
  if (!status) return '—';
  return RIDER_STATUS_LABEL[status] ?? status;
}

export function riderStatusColor(status: string | null | undefined): string {
  if (!status) return '#94a3b8';
  return RIDER_STATUS_COLOR[status] ?? '#94a3b8';
}
