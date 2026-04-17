import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface AdminService {
  id: string;
  name: string;
  description: string | null;
  category: string;
  pricePerPiece: number;
  emoji: string | null;
  iconUrl: string | null;
  isActive: boolean;
  sortOrder: number;
  garmentCount: number;
  treatmentCount: number;
}

export interface CreateServiceRequest {
  name: string;
  description: string | null;
  category: string | null;
  pricePerPiece: number;
  emoji: string | null;
  sortOrder: number | null;
}

export interface UpdateServiceRequest {
  name?: string | null;
  description?: string | null;
  category?: string | null;
  pricePerPiece?: number | null;
  emoji?: string | null;
  isActive?: boolean | null;
  sortOrder?: number | null;
}

export interface AdminGarment {
  id: string;
  serviceId: string;
  serviceName: string;
  name: string;
  emoji: string | null;
  priceOverride: number | null;
  sortOrder: number;
}

export interface CreateGarmentRequest {
  serviceId: string;
  name: string;
  emoji: string | null;
  priceOverride: number | null;
  sortOrder: number | null;
}

export interface UpdateGarmentRequest {
  name?: string | null;
  emoji?: string | null;
  priceOverride?: number | null;
  sortOrder?: number | null;
}

export interface AdminTreatment {
  id: string;
  serviceId: string;
  serviceName: string;
  name: string;
  description: string | null;
  priceMultiplier: number;
  isActive: boolean;
  sortOrder: number;
}

export interface CreateTreatmentRequest {
  serviceId: string;
  name: string;
  description: string | null;
  priceMultiplier: number;
  sortOrder: number | null;
}

export interface UpdateTreatmentRequest {
  name?: string | null;
  description?: string | null;
  priceMultiplier?: number | null;
  isActive?: boolean | null;
  sortOrder?: number | null;
}

interface ApiEnvelope<T> {
  success: boolean;
  message: string | null;
  data: T;
}

@Injectable({ providedIn: 'root' })
export class CatalogService {
  private readonly base = `${environment.apiBaseUrl}/api/admin/catalog`;

  constructor(private http: HttpClient) {}

  // Services
  listServices(): Observable<AdminService[]> {
    return this.http
      .get<ApiEnvelope<AdminService[]>>(`${this.base}/services`)
      .pipe(map((r) => r.data));
  }
  createService(body: CreateServiceRequest): Observable<AdminService> {
    return this.http
      .post<ApiEnvelope<AdminService>>(`${this.base}/services`, body)
      .pipe(map((r) => r.data));
  }
  updateService(id: string, body: UpdateServiceRequest): Observable<AdminService> {
    return this.http
      .patch<ApiEnvelope<AdminService>>(`${this.base}/services/${id}`, body)
      .pipe(map((r) => r.data));
  }

  // Garments
  listGarments(serviceId?: string): Observable<AdminGarment[]> {
    const url = serviceId
      ? `${this.base}/garments?serviceId=${serviceId}`
      : `${this.base}/garments`;
    return this.http
      .get<ApiEnvelope<AdminGarment[]>>(url)
      .pipe(map((r) => r.data));
  }
  createGarment(body: CreateGarmentRequest): Observable<AdminGarment> {
    return this.http
      .post<ApiEnvelope<AdminGarment>>(`${this.base}/garments`, body)
      .pipe(map((r) => r.data));
  }
  updateGarment(id: string, body: UpdateGarmentRequest): Observable<AdminGarment> {
    return this.http
      .patch<ApiEnvelope<AdminGarment>>(`${this.base}/garments/${id}`, body)
      .pipe(map((r) => r.data));
  }
  deleteGarment(id: string): Observable<boolean> {
    return this.http
      .delete<ApiEnvelope<boolean>>(`${this.base}/garments/${id}`)
      .pipe(map((r) => r.data));
  }

  // Treatments
  listTreatments(serviceId?: string): Observable<AdminTreatment[]> {
    const url = serviceId
      ? `${this.base}/treatments?serviceId=${serviceId}`
      : `${this.base}/treatments`;
    return this.http
      .get<ApiEnvelope<AdminTreatment[]>>(url)
      .pipe(map((r) => r.data));
  }
  createTreatment(body: CreateTreatmentRequest): Observable<AdminTreatment> {
    return this.http
      .post<ApiEnvelope<AdminTreatment>>(`${this.base}/treatments`, body)
      .pipe(map((r) => r.data));
  }
  updateTreatment(id: string, body: UpdateTreatmentRequest): Observable<AdminTreatment> {
    return this.http
      .patch<ApiEnvelope<AdminTreatment>>(`${this.base}/treatments/${id}`, body)
      .pipe(map((r) => r.data));
  }
}
