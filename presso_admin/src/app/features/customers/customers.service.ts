import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface CustomerListItem {
  id: string;
  name: string | null;
  phone: string;
  email: string | null;
  isStudentVerified: boolean;
  coinBalance: number;
  orderCount: number;
  totalSpent: number;
  lastOrderAt: string | null;
  createdAt: string;
}

export interface PagedCustomers {
  items: CustomerListItem[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
  hasNext: boolean;
  hasPrevious: boolean;
}

export interface CustomerRecentOrder {
  id: string;
  orderNumber: string;
  status: string;
  totalAmount: number;
  itemCount: number;
  createdAt: string;
}

export interface CustomerDetail {
  id: string;
  name: string | null;
  phone: string;
  email: string | null;
  isStudentVerified: boolean;
  coinBalance: number;
  orderCount: number;
  totalSpent: number;
  averageOrderValue: number;
  firstOrderAt: string | null;
  lastOrderAt: string | null;
  createdAt: string;
  recentOrders: CustomerRecentOrder[];
}

export interface CustomerListQuery {
  page?: number;
  pageSize?: number;
  search?: string;
}

interface ApiEnvelope<T> {
  success: boolean;
  message: string | null;
  data: T;
}

@Injectable({ providedIn: 'root' })
export class CustomersService {
  private readonly base = `${environment.apiBaseUrl}/api/admin/customers`;

  constructor(private http: HttpClient) {}

  list(query: CustomerListQuery): Observable<PagedCustomers> {
    let params = new HttpParams();
    if (query.page) params = params.set('page', query.page);
    if (query.pageSize) params = params.set('pageSize', query.pageSize);
    if (query.search) params = params.set('search', query.search);
    return this.http
      .get<ApiEnvelope<PagedCustomers>>(this.base, { params })
      .pipe(map((r) => r.data));
  }

  detail(id: string): Observable<CustomerDetail> {
    return this.http
      .get<ApiEnvelope<CustomerDetail>>(`${this.base}/${id}`)
      .pipe(map((r) => r.data));
  }
}
