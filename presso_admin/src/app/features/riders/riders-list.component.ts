import { Component, effect, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import {
  RidersService,
  AdminRiderListItem,
  AdminRiderStats,
  RiderListQuery,
} from './riders.service';
import { riderStatusLabel, riderStatusColor } from '../../shared/rider-status';

type Tab = 'all' | 'Pending' | 'Approved' | 'Suspended' | 'Rejected';

@Component({
  selector: 'app-riders-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, DatePipe],
  templateUrl: './riders-list.component.html',
  styleUrl: './riders-list.component.scss',
})
export class RidersListComponent {
  tab = signal<Tab>('all');
  search = signal('');
  page = signal(1);
  pageSize = signal(25);

  items = signal<AdminRiderListItem[]>([]);
  stats = signal<AdminRiderStats>({
    all: 0,
    pending: 0,
    approved: 0,
    suspended: 0,
    rejected: 0,
  });
  totalCount = signal(0);
  totalPages = signal(0);
  loading = signal(false);
  error = signal<string | null>(null);

  // Add-rider modal state
  addOpen = signal(false);
  addPhone = signal('');
  addName = signal('');
  addVehicle = signal('');
  addNotes = signal('');
  adding = signal(false);
  addError = signal<string | null>(null);

  readonly riderStatusLabel = riderStatusLabel;
  readonly riderStatusColor = riderStatusColor;

  constructor(
    private ridersService: RidersService,
    private router: Router
  ) {
    effect(
      () => {
        this.tab();
        this.page();
        this.load();
      },
      { allowSignalWrites: true }
    );
  }

  load(): void {
    this.loading.set(true);
    this.error.set(null);
    const query: RiderListQuery = {
      page: this.page(),
      pageSize: this.pageSize(),
      search: this.search().trim() || undefined,
      status: this.tab() === 'all' ? undefined : this.tab(),
    };
    this.ridersService.list(query).subscribe({
      next: (res) => {
        this.items.set(res.riders.items);
        this.totalCount.set(res.riders.totalCount);
        this.totalPages.set(res.riders.totalPages);
        this.stats.set(res.stats);
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set(err?.error?.message || 'Failed to load riders');
        this.loading.set(false);
      },
    });
  }

  setTab(t: Tab) {
    if (t === this.tab()) return;
    this.page.set(1);
    this.tab.set(t);
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

  openAdd() {
    this.addPhone.set('');
    this.addName.set('');
    this.addVehicle.set('');
    this.addNotes.set('');
    this.addError.set(null);
    this.addOpen.set(true);
  }

  closeAdd() {
    if (this.adding()) return;
    this.addOpen.set(false);
  }

  submitAdd() {
    const phone = this.addPhone().trim();
    if (!phone) {
      this.addError.set('Phone number is required.');
      return;
    }
    this.adding.set(true);
    this.addError.set(null);
    this.ridersService
      .create({
        phone,
        name: this.addName().trim() || null,
        vehicleNumber: this.addVehicle().trim() || null,
        adminNotes: this.addNotes().trim() || null,
      })
      .subscribe({
        next: (r) => {
          this.adding.set(false);
          this.addOpen.set(false);
          this.router.navigate(['/riders', r.id]);
        },
        error: (err) => {
          this.addError.set(err?.error?.message || 'Failed to create rider');
          this.adding.set(false);
        },
      });
  }
}
