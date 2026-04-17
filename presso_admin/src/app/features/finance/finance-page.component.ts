import { Component, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import {
  FinanceService,
  PnlData,
  Payment,
  PaginatedResponse,
} from './finance.service';

@Component({
  selector: 'app-finance-page',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './finance-page.component.html',
  styleUrl: './finance-page.component.scss',
})
export class FinancePageComponent {
  pnl = signal<PnlData | null>(null);
  loadingPnl = signal(false);
  pnlError = signal<string | null>(null);
  pnlDays = signal(30);

  payments = signal<PaginatedResponse<Payment> | null>(null);
  loadingPayments = signal(false);
  paymentsError = signal<string | null>(null);
  paymentPage = signal(1);
  paymentStatus = signal('');
  paymentSearch = signal('');

  chartBars = computed(() => {
    const p = this.pnl();
    if (!p || p.dailyRevenue.length === 0) return [];
    const max = Math.max(...p.dailyRevenue.map((d) => d.revenue), 1);
    return p.dailyRevenue.map((d) => ({
      date: d.date,
      label: this.shortDate(d.date),
      revenue: d.revenue,
      orders: d.orderCount,
      pct: Math.max(2, (d.revenue / max) * 100),
    }));
  });

  discountTotal = computed(() => {
    const p = this.pnl();
    if (!p) return 0;
    return p.totalCoinDiscount + p.totalStudentDiscount + p.totalAdminDiscount;
  });

  constructor(private api: FinanceService) {
    this.loadPnl();
    this.loadPayments();
  }

  loadPnl() {
    this.loadingPnl.set(true);
    this.pnlError.set(null);
    this.api.getPnl(this.pnlDays()).subscribe({
      next: (r) => {
        this.pnl.set(r);
        this.loadingPnl.set(false);
      },
      error: (err) => {
        this.pnlError.set(err?.error?.message || 'Failed to load P&L data');
        this.loadingPnl.set(false);
      },
    });
  }

  loadPayments() {
    this.loadingPayments.set(true);
    this.paymentsError.set(null);
    this.api
      .getPayments(
        this.paymentPage(),
        15,
        this.paymentStatus() || undefined,
        this.paymentSearch() || undefined
      )
      .subscribe({
        next: (r) => {
          this.payments.set(r);
          this.loadingPayments.set(false);
        },
        error: (err) => {
          this.paymentsError.set(
            err?.error?.message || 'Failed to load payments'
          );
          this.loadingPayments.set(false);
        },
      });
  }

  setDays(d: number) {
    this.pnlDays.set(d);
    this.loadPnl();
  }

  filterStatus(s: string) {
    this.paymentStatus.set(s);
    this.paymentPage.set(1);
    this.loadPayments();
  }

  searchPayments(term: string) {
    this.paymentSearch.set(term);
    this.paymentPage.set(1);
    this.loadPayments();
  }

  goPage(p: number) {
    this.paymentPage.set(p);
    this.loadPayments();
  }

  statusClass(s: string): string {
    switch (s.toLowerCase()) {
      case 'captured': return 'st-captured';
      case 'failed': return 'st-failed';
      case 'refunded': return 'st-refunded';
      case 'authorized': return 'st-authorized';
      default: return 'st-pending';
    }
  }

  shortDate(iso: string): string {
    const [, m, d] = iso.split('-').map(Number);
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${d} ${months[m]}`;
  }

  formatDate(iso: string): string {
    const dt = new Date(iso);
    return dt.toLocaleDateString('en-IN', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    });
  }

  formatCurrency(n: number): string {
    return '₹' + n.toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
  }
}
