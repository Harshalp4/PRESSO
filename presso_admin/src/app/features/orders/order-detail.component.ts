import { Component, OnInit, signal, computed } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { OrdersService, OrderDetail } from './orders.service';
import { statusLabel, statusColor, ORDER_TIMELINE_STEPS } from '../../shared/order-status';

interface TimelineEntry {
  status: string;
  label: string;
  at: string | null;
  done: boolean;
  current: boolean;
}

@Component({
  selector: 'app-order-detail',
  standalone: true,
  imports: [CommonModule, RouterLink, DatePipe],
  templateUrl: './order-detail.component.html',
  styleUrl: './order-detail.component.scss',
})
export class OrderDetailComponent implements OnInit {
  order = signal<OrderDetail | null>(null);
  loading = signal(true);
  error = signal<string | null>(null);

  /** Non-null accessor for use in templates where we've already guarded on order(). */
  o = computed<OrderDetail>(() => this.order()!);

  readonly statusLabel = statusLabel;
  readonly statusColor = statusColor;

  constructor(
    private route: ActivatedRoute,
    private ordersService: OrdersService
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) {
      this.error.set('No order id');
      this.loading.set(false);
      return;
    }
    this.load(id);
  }

  load(id: string): void {
    this.loading.set(true);
    this.error.set(null);
    this.ordersService.detail(id).subscribe({
      next: (o) => {
        this.order.set(o);
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set(err?.error?.message || 'Failed to load order');
        this.loading.set(false);
      },
    });
  }

  /**
   * Build the timeline entries from the detail payload. Each step is "done"
   * when we have a concrete timestamp for it — we synthesize per-status
   * timestamps from the flat `pickedUpAt/facilityReceivedAt/...` fields
   * returned by the API.
   */
  timeline = computed<TimelineEntry[]>(() => {
    const o = this.order();
    if (!o) return [];

    // Map each timeline step to the best-available timestamp.
    const tsByStep: Record<string, string | null> = {
      Pending: o.createdAt,
      Confirmed: o.createdAt, // best-effort; confirmed = placed for now
      RiderAssigned:
        o.assignments.find((a) => a.type === 'Pickup')?.assignedAt ?? null,
      PickedUp: o.pickedUpAt,
      InProcess: o.facilityReceivedAt ?? o.processingStartedAt,
      ReadyForDelivery: o.readyAt,
      OutForDelivery: o.outForDeliveryAt,
      Delivered: o.deliveredAt,
    };

    // Determine how far the order has progressed. If cancelled, only show
    // the steps up to where it was cancelled (we don't have a cancel
    // timestamp so we just mark the whole thing as terminal).
    const isCancelled = o.status === 'Cancelled';
    const currentIdx = ORDER_TIMELINE_STEPS.indexOf(o.status);

    return ORDER_TIMELINE_STEPS.map((step, idx) => ({
      status: step,
      label: statusLabel(step),
      at: tsByStep[step],
      done: !isCancelled && idx < currentIdx,
      current: !isCancelled && idx === currentIdx,
    }));
  });

  /** Summed effective discounts for the charges card. */
  totalDiscount = computed<number>(() => {
    const o = this.order();
    if (!o) return 0;
    return o.coinDiscount + o.studentDiscount + o.adminDiscount;
  });
}
