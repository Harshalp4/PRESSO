import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

// Templates are now date-less: a single row represents "8-10 AM, max 10"
// regardless of day. Per-day booking counts live on Orders and are not
// surfaced here — the admin page just manages the shape of the windows.
export interface AdminSlot {
  id: string;
  startTime: string; // "HH:mm:ss"
  endTime: string;
  maxOrders: number;
  isActive: boolean;
  sortOrder: number;
}

export interface CreateSlotRequest {
  startTime: string;
  endTime: string;
  maxOrders: number;
  sortOrder?: number | null;
}

export interface UpdateSlotRequest {
  maxOrders?: number | null;
  isActive?: boolean | null;
  sortOrder?: number | null;
}

interface ApiEnvelope<T> {
  success: boolean;
  message: string | null;
  data: T;
}

@Injectable({ providedIn: 'root' })
export class SlotsService {
  private readonly base = `${environment.apiBaseUrl}/api/admin/slots`;

  constructor(private http: HttpClient) {}

  list(): Observable<AdminSlot[]> {
    return this.http
      .get<ApiEnvelope<AdminSlot[]>>(this.base)
      .pipe(map((r) => r.data));
  }

  create(body: CreateSlotRequest): Observable<AdminSlot> {
    return this.http
      .post<ApiEnvelope<AdminSlot>>(this.base, body)
      .pipe(map((r) => r.data));
  }

  update(id: string, body: UpdateSlotRequest): Observable<AdminSlot> {
    return this.http
      .patch<ApiEnvelope<AdminSlot>>(`${this.base}/${id}`, body)
      .pipe(map((r) => r.data));
  }
}
