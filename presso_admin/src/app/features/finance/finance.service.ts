import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

// ──── P&L ────
export interface PnlData {
  totalRevenue: number;
  todayRevenue: number;
  weekRevenue: number;
  monthRevenue: number;
  capturedCount: number;
  pendingCount: number;
  failedCount: number;
  refundedCount: number;
  avgOrderValue: number;
  totalCoinDiscount: number;
  totalStudentDiscount: number;
  totalAdminDiscount: number;
  totalExpressCharge: number;
  totalExpenses: number;
  totalRiderPayouts: number;
  netEarnings: number;
  dailyRevenue: DailyRevenue[];
}

export interface DailyRevenue {
  date: string;
  revenue: number;
  orderCount: number;
}

// ──── Payments ────
export interface Payment {
  orderId: string;
  orderNumber: string;
  amount: number;
  paymentStatus: string;
  razorpayPaymentId: string | null;
  createdAt: string;
}

// ──── Expenses ────
export interface Expense {
  id: string;
  category: string;
  description: string;
  amount: number;
  date: string;
  reference: string | null;
  createdAt: string;
}

export interface CreateExpenseRequest {
  category: string;
  description: string;
  amount: number;
  date: string;
  reference?: string | null;
}

export interface UpdateExpenseRequest {
  category?: string | null;
  description?: string | null;
  amount?: number | null;
  date?: string | null;
  reference?: string | null;
}

// ──── Payouts ────
export interface RiderPayout {
  id: string;
  riderId: string;
  riderName: string;
  riderPhone: string;
  amount: number;
  deliveryCount: number;
  periodStart: string;
  periodEnd: string;
  status: string;
  paidAt: string | null;
  reference: string | null;
  notes: string | null;
  createdAt: string;
}

export interface RiderPayoutSummary {
  riderId: string;
  name: string;
  phone: string;
  completedDeliveries: number;
  amountOwed: number;
  amountPaid: number;
}

// ──── Shared ────
export interface PaginatedResponse<T> {
  items: T[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
  hasNext: boolean;
  hasPrevious: boolean;
}

interface ApiEnvelope<T> {
  success: boolean;
  message: string | null;
  data: T;
}

@Injectable({ providedIn: 'root' })
export class FinanceService {
  private readonly base = `${environment.apiBaseUrl}/api/admin`;

  constructor(private http: HttpClient) {}

  // P&L
  getPnl(days = 30): Observable<PnlData> {
    return this.http
      .get<ApiEnvelope<PnlData>>(`${this.base}/finance/pnl`, {
        params: new HttpParams().set('days', days),
      })
      .pipe(map((r) => r.data));
  }

  // Payments
  getPayments(
    page: number,
    pageSize: number,
    status?: string,
    search?: string
  ): Observable<PaginatedResponse<Payment>> {
    let params = new HttpParams()
      .set('page', page)
      .set('pageSize', pageSize);
    if (status) params = params.set('status', status);
    if (search) params = params.set('search', search);
    return this.http
      .get<ApiEnvelope<PaginatedResponse<Payment>>>(`${this.base}/payments`, {
        params,
      })
      .pipe(map((r) => r.data));
  }

  // Expenses
  getExpenses(
    page: number,
    pageSize: number,
    category?: string
  ): Observable<PaginatedResponse<Expense>> {
    let params = new HttpParams()
      .set('page', page)
      .set('pageSize', pageSize);
    if (category) params = params.set('category', category);
    return this.http
      .get<ApiEnvelope<PaginatedResponse<Expense>>>(
        `${this.base}/finance/expenses`,
        { params }
      )
      .pipe(map((r) => r.data));
  }

  createExpense(body: CreateExpenseRequest): Observable<Expense> {
    return this.http
      .post<ApiEnvelope<Expense>>(`${this.base}/finance/expenses`, body)
      .pipe(map((r) => r.data));
  }

  updateExpense(id: string, body: UpdateExpenseRequest): Observable<Expense> {
    return this.http
      .patch<ApiEnvelope<Expense>>(`${this.base}/finance/expenses/${id}`, body)
      .pipe(map((r) => r.data));
  }

  deleteExpense(id: string): Observable<boolean> {
    return this.http
      .delete<ApiEnvelope<boolean>>(`${this.base}/finance/expenses/${id}`)
      .pipe(map((r) => r.data));
  }

  // Payouts
  getPayouts(
    page: number,
    pageSize: number,
    status?: string
  ): Observable<PaginatedResponse<RiderPayout>> {
    let params = new HttpParams()
      .set('page', page)
      .set('pageSize', pageSize);
    if (status) params = params.set('status', status);
    return this.http
      .get<ApiEnvelope<PaginatedResponse<RiderPayout>>>(
        `${this.base}/finance/payouts`,
        { params }
      )
      .pipe(map((r) => r.data));
  }

  createPayout(body: {
    riderId: string;
    periodStart: string;
    periodEnd: string;
    notes?: string;
  }): Observable<RiderPayout> {
    return this.http
      .post<ApiEnvelope<RiderPayout>>(`${this.base}/finance/payouts`, body)
      .pipe(map((r) => r.data));
  }

  updatePayoutStatus(
    id: string,
    body: { status: string; reference?: string }
  ): Observable<RiderPayout> {
    return this.http
      .patch<ApiEnvelope<RiderPayout>>(
        `${this.base}/finance/payouts/${id}`,
        body
      )
      .pipe(map((r) => r.data));
  }

  getRiderSummaries(
    from: string,
    to: string
  ): Observable<RiderPayoutSummary[]> {
    const params = new HttpParams().set('from', from).set('to', to);
    return this.http
      .get<ApiEnvelope<RiderPayoutSummary[]>>(
        `${this.base}/finance/rider-summaries`,
        { params }
      )
      .pipe(map((r) => r.data));
  }
}
