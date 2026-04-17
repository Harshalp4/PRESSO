import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import {
  FinanceService,
  RiderPayout,
  RiderPayoutSummary,
  PaginatedResponse,
} from './finance.service';

@Component({
  selector: 'app-payouts-page',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './payouts-page.component.html',
  styleUrl: './payouts-page.component.scss',
})
export class PayoutsPageComponent {
  // Payout list
  data = signal<PaginatedResponse<RiderPayout> | null>(null);
  loading = signal(false);
  error = signal<string | null>(null);
  page = signal(1);
  filterStatus = signal('');

  // Rider summaries
  summaries = signal<RiderPayoutSummary[]>([]);
  loadingSummaries = signal(false);
  summaryFrom = signal(this.monthStartIso());
  summaryTo = signal(this.todayIso());

  // Create payout modal
  createModal = signal(false);
  createRiderId = signal('');
  createFrom = signal(this.monthStartIso());
  createTo = signal(this.todayIso());
  createNotes = signal('');
  creating = signal(false);
  createError = signal<string | null>(null);

  // Mark paid modal
  markPaidModal = signal(false);
  markPaidPayout = signal<RiderPayout | null>(null);
  markPaidRef = signal('');
  marking = signal(false);
  markError = signal<string | null>(null);

  constructor(private api: FinanceService) {
    this.load();
    this.loadSummaries();
  }

  load() {
    this.loading.set(true);
    this.error.set(null);
    this.api
      .getPayouts(this.page(), 15, this.filterStatus() || undefined)
      .subscribe({
        next: (r) => { this.data.set(r); this.loading.set(false); },
        error: (err) => { this.error.set(err?.error?.message || 'Failed to load payouts'); this.loading.set(false); },
      });
  }

  loadSummaries() {
    this.loadingSummaries.set(true);
    this.api
      .getRiderSummaries(this.summaryFrom(), this.summaryTo())
      .subscribe({
        next: (r) => { this.summaries.set(r); this.loadingSummaries.set(false); },
        error: () => this.loadingSummaries.set(false),
      });
  }

  setStatus(s: string) {
    this.filterStatus.set(s);
    this.page.set(1);
    this.load();
  }

  goPage(p: number) { this.page.set(p); this.load(); }

  refreshSummaries() { this.loadSummaries(); }

  // Create payout
  openCreate(riderId?: string) {
    this.createRiderId.set(riderId || '');
    this.createFrom.set(this.monthStartIso());
    this.createTo.set(this.todayIso());
    this.createNotes.set('');
    this.createError.set(null);
    this.createModal.set(true);
  }

  closeCreate() { if (!this.creating()) this.createModal.set(false); }

  submitCreate() {
    if (!this.createRiderId()) { this.createError.set('Select a rider.'); return; }
    this.creating.set(true);
    this.createError.set(null);
    this.api
      .createPayout({
        riderId: this.createRiderId(),
        periodStart: this.createFrom(),
        periodEnd: this.createTo(),
        notes: this.createNotes() || undefined,
      })
      .subscribe({
        next: () => {
          this.creating.set(false);
          this.createModal.set(false);
          this.load();
          this.loadSummaries();
        },
        error: (err) => {
          this.createError.set(err?.error?.message || 'Failed to create payout');
          this.creating.set(false);
        },
      });
  }

  // Mark as paid
  openMarkPaid(p: RiderPayout) {
    this.markPaidPayout.set(p);
    this.markPaidRef.set('');
    this.markError.set(null);
    this.markPaidModal.set(true);
  }

  closeMarkPaid() { if (!this.marking()) this.markPaidModal.set(false); }

  submitMarkPaid() {
    const p = this.markPaidPayout();
    if (!p) return;
    this.marking.set(true);
    this.markError.set(null);
    this.api
      .updatePayoutStatus(p.id, {
        status: 'Paid',
        reference: this.markPaidRef() || undefined,
      })
      .subscribe({
        next: () => {
          this.marking.set(false);
          this.markPaidModal.set(false);
          this.load();
          this.loadSummaries();
        },
        error: (err) => {
          this.markError.set(err?.error?.message || 'Failed to update');
          this.marking.set(false);
        },
      });
  }

  cancelPayout(p: RiderPayout) {
    if (!confirm(`Cancel payout for ${p.riderName}?`)) return;
    this.api.updatePayoutStatus(p.id, { status: 'Cancelled' }).subscribe({
      next: () => { this.load(); this.loadSummaries(); },
      error: (err) => this.error.set(err?.error?.message || 'Failed to cancel'),
    });
  }

  formatCurrency(n: number): string {
    return '₹' + n.toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
  }

  formatDate(iso: string | null): string {
    if (!iso) return '—';
    const dt = new Date(iso);
    return dt.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
  }

  statusClass(s: string): string {
    switch (s.toLowerCase()) {
      case 'paid': return 'st-paid';
      case 'cancelled': return 'st-cancelled';
      default: return 'st-pending';
    }
  }

  private todayIso(): string {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  private monthStartIso(): string {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-01`;
  }
}
