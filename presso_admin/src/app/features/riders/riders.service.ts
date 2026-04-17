import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface AdminRiderListItem {
  id: string;
  userId: string;
  name: string | null;
  phone: string;
  vehicleNumber: string | null;
  status: string;
  isActive: boolean;
  isAvailable: boolean;
  todayEarnings: number;
  completedDeliveries: number;
  createdAt: string;
  approvedAt: string | null;
}

export interface AdminRiderStats {
  all: number;
  pending: number;
  approved: number;
  suspended: number;
  rejected: number;
}

export interface PagedRiders {
  items: AdminRiderListItem[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
  hasNext: boolean;
  hasPrevious: boolean;
}

export interface AdminRiderListResponse {
  riders: PagedRiders;
  stats: AdminRiderStats;
}

export interface AdminRiderDetail {
  id: string;
  userId: string;
  name: string | null;
  phone: string;
  vehicleNumber: string | null;
  status: string;
  isActive: boolean;
  isAvailable: boolean;
  todayEarnings: number;
  completedDeliveries: number;
  inFlightAssignments: number;
  currentLat: number | null;
  currentLng: number | null;
  lastLocationUpdate: string | null;
  createdAt: string;
  approvedAt: string | null;
  suspendedAt: string | null;
  rejectionReason: string | null;
  adminNotes: string | null;
}

export interface RiderListQuery {
  page?: number;
  pageSize?: number;
  search?: string;
  status?: string;
}

export interface CreateAdminRiderRequest {
  phone: string;
  name?: string | null;
  vehicleNumber?: string | null;
  adminNotes?: string | null;
}

export interface ApproveRiderRequest {
  adminNotes?: string | null;
}
export interface RejectRiderRequest {
  reason: string;
  adminNotes?: string | null;
}
export interface SuspendRiderRequest {
  reason: string;
  adminNotes?: string | null;
}
export interface UpdateRiderNotesRequest {
  adminNotes?: string | null;
}

interface ApiEnvelope<T> {
  success: boolean;
  message: string | null;
  data: T;
}

@Injectable({ providedIn: 'root' })
export class RidersService {
  private readonly base = `${environment.apiBaseUrl}/api/admin/riders`;

  constructor(private http: HttpClient) {}

  list(query: RiderListQuery): Observable<AdminRiderListResponse> {
    let params = new HttpParams();
    if (query.page) params = params.set('page', query.page);
    if (query.pageSize) params = params.set('pageSize', query.pageSize);
    if (query.search) params = params.set('search', query.search);
    if (query.status) params = params.set('status', query.status);
    return this.http
      .get<ApiEnvelope<AdminRiderListResponse>>(this.base, { params })
      .pipe(map((r) => r.data));
  }

  create(body: CreateAdminRiderRequest): Observable<AdminRiderDetail> {
    return this.http
      .post<ApiEnvelope<AdminRiderDetail>>(this.base, body)
      .pipe(map((r) => r.data));
  }

  detail(id: string): Observable<AdminRiderDetail> {
    return this.http
      .get<ApiEnvelope<AdminRiderDetail>>(`${this.base}/${id}`)
      .pipe(map((r) => r.data));
  }

  approve(id: string, body: ApproveRiderRequest): Observable<AdminRiderDetail> {
    return this.http
      .post<ApiEnvelope<AdminRiderDetail>>(`${this.base}/${id}/approve`, body)
      .pipe(map((r) => r.data));
  }

  reject(id: string, body: RejectRiderRequest): Observable<AdminRiderDetail> {
    return this.http
      .post<ApiEnvelope<AdminRiderDetail>>(`${this.base}/${id}/reject`, body)
      .pipe(map((r) => r.data));
  }

  suspend(id: string, body: SuspendRiderRequest): Observable<AdminRiderDetail> {
    return this.http
      .post<ApiEnvelope<AdminRiderDetail>>(`${this.base}/${id}/suspend`, body)
      .pipe(map((r) => r.data));
  }

  reinstate(id: string): Observable<AdminRiderDetail> {
    return this.http
      .post<ApiEnvelope<AdminRiderDetail>>(`${this.base}/${id}/reinstate`, {})
      .pipe(map((r) => r.data));
  }

  updateNotes(
    id: string,
    body: UpdateRiderNotesRequest
  ): Observable<AdminRiderDetail> {
    return this.http
      .patch<ApiEnvelope<AdminRiderDetail>>(`${this.base}/${id}/notes`, body)
      .pipe(map((r) => r.data));
  }
}
