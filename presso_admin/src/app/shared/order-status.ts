/**
 * Human labels, chip colors and timeline ordering for OrderStatus enum values
 * returned from the backend. Keep in sync with
 * Presso.API/Domain/Enums/OrderStatus.cs
 */

export const ORDER_STATUS_LABEL: Record<string, string> = {
  Pending: 'Pending',
  Confirmed: 'Confirmed',
  RiderAssigned: 'Rider assigned',
  PickupInProgress: 'Pickup in progress',
  PickedUp: 'Picked up',
  InProcess: 'In process',
  ReadyForDelivery: 'Ready',
  OutForDelivery: 'Out for delivery',
  Delivered: 'Delivered',
  Cancelled: 'Cancelled',
};

export const ORDER_STATUS_COLOR: Record<string, string> = {
  Pending: '#94a3b8',           // slate
  Confirmed: '#38bdf8',         // sky
  RiderAssigned: '#a855f7',     // purple
  PickupInProgress: '#a855f7',
  PickedUp: '#f59e0b',          // amber
  InProcess: '#f97316',         // orange
  ReadyForDelivery: '#eab308',  // yellow
  OutForDelivery: '#0ea5e9',    // bright blue
  Delivered: '#10b981',         // green
  Cancelled: '#ef4444',         // red
};

/** Ordered list of statuses for the timeline. Cancelled is not in the list. */
export const ORDER_TIMELINE_STEPS: string[] = [
  'Pending',
  'Confirmed',
  'RiderAssigned',
  'PickedUp',
  'InProcess',
  'ReadyForDelivery',
  'OutForDelivery',
  'Delivered',
];

export function statusLabel(status: string | null | undefined): string {
  if (!status) return '—';
  return ORDER_STATUS_LABEL[status] ?? status;
}

export function statusColor(status: string | null | undefined): string {
  if (!status) return '#94a3b8';
  return ORDER_STATUS_COLOR[status] ?? '#94a3b8';
}
