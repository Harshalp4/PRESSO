import { Component, OnInit, signal, computed, effect } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { OrdersService, OrderListItem, OrderStats, OrderListQuery } from './orders.service';
import { statusLabel, statusColor } from '../../shared/order-status';

type Tab = 'all' | 'active' | 'delivered' | 'cancelled';

@Component({
  selector: 'app-orders-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, DatePipe],
  templateUrl: './orders-list.component.html',
  styleUrl: './orders-list.component.scss',
})
export class OrdersListComponent implements OnInit {
  // filter state
  tab = signal<Tab>('all');
  search = signal('');
  statusFilter = signal<string>(''); // exact OrderStatus value
  dateRange = signal<'7d' | '30d' | 'month' | 'all' | 'custom'>('30d');
  customFrom = signal<string>(''); // yyyy-MM-dd
  customTo = signal<string>('');   // yyyy-MM-dd
  page = signal(1);
  pageSize = signal(25);

  // data state
  items = signal<OrderListItem[]>([]);
  stats = signal<OrderStats>({ all: 0, active: 0, delivered: 0, cancelled: 0 });
  totalCount = signal(0);
  totalPages = signal(0);
  loading = signal(false);
  error = signal<string | null>(null);

  // status options the backend accepts
  readonly statusOptions = [
    { value: '', label: 'Any status' },
    { value: 'Pending', label: 'Pending' },
    { value: 'Confirmed', label: 'Confirmed' },
    { value: 'RiderAssigned', label: 'Rider assigned' },
    { value: 'PickupInProgress', label: 'Pickup in progress' },
    { value: 'PickedUp', label: 'Picked up' },
    { value: 'InProcess', label: 'In process' },
    { value: 'ReadyForDelivery', label: 'Ready' },
    { value: 'OutForDelivery', label: 'Out for delivery' },
    { value: 'Delivered', label: 'Delivered' },
    { value: 'Cancelled', label: 'Cancelled' },
  ];

  readonly statusLabel = statusLabel;
  readonly statusColor = statusColor;

  constructor(private ordersService: OrdersService) {
    // Reload whenever any filter changes. Debounce isn't strictly needed
    // because the user drives filter changes by dropdown/tab clicks; the
    // search input has its own debounced handler below.
    effect(
      () => {
        // touch signals to subscribe
        this.tab();
        this.statusFilter();
        this.dateRange();
        this.customFrom();
        this.customTo();
        this.page();
        // For custom range, only fire when BOTH ends are set.
        if (this.dateRange() === 'custom' && (!this.customFrom() || !this.customTo())) {
          return;
        }
        this.load();
      },
      { allowSignalWrites: true }
    );
  }

  ngOnInit(): void {
    // initial fetch handled by effect
  }

  /** Tab status narrows the list; explicit status filter overrides tab. */
  private tabToStatus(): string | undefined {
    if (this.statusFilter()) return this.statusFilter();
    switch (this.tab()) {
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'active':
        // "Active" is everything that's not delivered/cancelled. The backend
        // doesn't currently have a composite filter for this — we fetch
        // without a status param and filter client-side is wrong because it
        // would break pagination. Instead, the backend stats already give us
        // the "active" count, and the `all` tab without a status param
        // already returns everything ordered by recency. For the "active"
        // tab we currently filter to `RiderAssigned` as a compromise until
        // the backend grows a dedicated "non-terminal" filter. For now we
        // leave it undefined (same as All) so the count tab acts as a
        // badge rather than a hard filter.
        return undefined;
      default:
        return undefined;
    }
  }

  load(): void {
    this.loading.set(true);
    this.error.set(null);
    const query: OrderListQuery = {
      page: this.page(),
      pageSize: this.pageSize(),
      search: this.search().trim() || undefined,
      status: this.tabToStatus(),
      range: this.dateRange(),
    };
    if (this.dateRange() === 'custom') {
      // yyyy-MM-dd → ISO so .NET DateTime binds correctly.
      if (this.customFrom()) query.from = new Date(this.customFrom()).toISOString();
      if (this.customTo()) query.to = new Date(this.customTo()).toISOString();
    }
    this.ordersService.list(query).subscribe({
      next: (res) => {
        this.items.set(res.orders.items);
        this.totalCount.set(res.orders.totalCount);
        this.totalPages.set(res.orders.totalPages);
        this.stats.set(res.stats);
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set(err?.error?.message || 'Failed to load orders');
        this.loading.set(false);
      },
    });
  }

  setTab(t: Tab) {
    if (t === this.tab()) return;
    this.statusFilter.set('');
    this.page.set(1);
    this.tab.set(t);
  }

  setStatus(s: string) {
    this.statusFilter.set(s);
    this.page.set(1);
  }

  setRange(r: '7d' | '30d' | 'month' | 'all' | 'custom') {
    this.dateRange.set(r);
    this.page.set(1);
    // Clear custom dates when leaving custom mode so the next entry is clean.
    if (r !== 'custom') {
      this.customFrom.set('');
      this.customTo.set('');
    }
  }

  setCustomFrom(v: string) {
    this.customFrom.set(v);
    this.page.set(1);
  }

  setCustomTo(v: string) {
    this.customTo.set(v);
    this.page.set(1);
  }

  private searchTimer: any;
  onSearchInput(v: string) {
    this.search.set(v);
    clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => {
      this.page.set(1);
      this.load();
    }, 300);
  }

  prev() {
    if (this.page() > 1) this.page.set(this.page() - 1);
  }
  next() {
    if (this.page() < this.totalPages()) this.page.set(this.page() + 1);
  }
}
