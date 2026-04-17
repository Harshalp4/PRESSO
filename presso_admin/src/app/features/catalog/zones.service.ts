import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface ServiceZone {
  id: string;
  name: string;
  pincode: string;
  city: string;
  area: string | null;
  description: string | null;
  isActive: boolean;
  sortOrder: number;
  assignedStoreId: string | null;
  assignedStoreName: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface CreateZoneRequest {
  name: string;
  pincode: string;
  city: string;
  area: string | null;
  description: string | null;
  assignedStoreId: string | null;
}

export interface UpdateZoneRequest {
  name?: string | null;
  pincode?: string | null;
  city?: string | null;
  area?: string | null;
  description?: string | null;
  isActive?: boolean | null;
  sortOrder?: number | null;
  assignedStoreId?: string | null;
}

interface ApiEnvelope<T> {
  success: boolean;
  message: string | null;
  data: T;
  errors?: string[] | null;
}

@Injectable({ providedIn: 'root' })
export class ZonesService {
  private readonly base = `${environment.apiBaseUrl}/api/admin/service-zones`;

  constructor(private http: HttpClient) {}

  list(isActive?: boolean): Observable<ServiceZone[]> {
    const url =
      isActive === undefined ? this.base : `${this.base}?isActive=${isActive}`;
    return this.http
      .get<ApiEnvelope<ServiceZone[]>>(url)
      .pipe(map((r) => r.data));
  }

  create(body: CreateZoneRequest): Observable<ServiceZone> {
    return this.http
      .post<ApiEnvelope<ServiceZone>>(this.base, body)
      .pipe(map((r) => r.data));
  }

  update(id: string, body: UpdateZoneRequest): Observable<ServiceZone> {
    return this.http
      .patch<ApiEnvelope<ServiceZone>>(`${this.base}/${id}`, body)
      .pipe(map((r) => r.data));
  }

  delete(id: string): Observable<boolean> {
    return this.http
      .delete<ApiEnvelope<boolean>>(`${this.base}/${id}`)
      .pipe(map((r) => r.data));
  }
}
