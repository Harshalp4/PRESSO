import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, map } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface OrderListItem {
  id: string;
  orderNumber: string;
  status: string;
  facilityStage: string | null;
  paymentStatus: string;
  totalAmount: number;
  itemCount: number;
  customerId: string;
  customerName: string | null;
  customerPhone: string;
  currentRiderName: string | null;
  assignedStoreId: string | null;
  assignedStoreName: string | null;
  isExpressDelivery: boolean;
  createdAt: string;
}

export interface OrderStats {
  all: number;
  active: number;
  delivered: number;
  cancelled: number;
}

export interface PagedOrders {
  items: OrderListItem[];
  totalCount: number;
  page: number;
  pageSize: number;
  totalPages: number;
  hasNext: boolean;
  hasPrevious: boolean;
}

export interface OrderListResponse {
  orders: PagedOrders;
  stats: OrderStats;
}

export interface OrderListQuery {
  page?: number;
  pageSize?: number;
  search?: string;
  status?: string;
  storeId?: string;
  range?: '7d' | '30d' | 'month' | 'all' | 'custom';
  from?: string; // ISO, only used when range === 'custom'
  to?: string;   // ISO, only used when range === 'custom'
}

export interface OrderItem {
  id: string;
  serviceName: string;
  garmentTypeName: string | null;
  treatmentName: string | null;
  treatmentMultiplier: number;
  quantity: number;
  pricePerPiece: number;
  subtotal: number;
}

export interface Assignment {
  riderId: string;
  riderName: string | null;
  type: string;
  status: string;
  assignedAt: string;
}

export interface AddressInfo {
  id: string;
  label: string | null;
  addressLine1: string;
  addressLine2: string | null;
  city: string;
  pincode: string;
  lat: number | null;
  lng: number | null;
}

export interface SlotInfo {
  id: string;
  date: string;
  startTime: string;
  endTime: string;
}

export interface OrderDetail {
  id: string;
  orderNumber: string;
  status: string;
  paymentStatus: string;
  subTotal: number;
  coinDiscount: number;
  studentDiscount: number;
  adminDiscount: number;
  expressCharge: number;
  totalAmount: number;
  isExpressDelivery: boolean;
  specialInstructions: string | null;
  coinsEarned: number;
  coinsRedeemed: number;
  pickupPhotoUrls: string[];
  razorpayOrderId: string | null;
  pickedUpAt: string | null;
  deliveredAt: string | null;
  createdAt: string;
  address: AddressInfo;
  pickupSlot: SlotInfo | null;
  items: OrderItem[];
  assignments: Assignment[];
  facilityInfo: { id: string; name: string } | null;
  facilityStage: string | null;
  facilityReceivedAt: string | null;
  processingStartedAt: string | null;
  readyAt: string | null;
  outForDeliveryAt: string | null;
  deliveryOtp: string | null;
}

interface ApiEnvelope<T> {
  success: boolean;
  message: string | null;
  data: T;
}

@Injectable({ providedIn: 'root' })
export class OrdersService {
  private readonly base = `${environment.apiBaseUrl}/api/admin/orders`;

  constructor(private http: HttpClient) {}

  list(query: OrderListQuery): Observable<OrderListResponse> {
    let params = new HttpParams();
    if (query.page) params = params.set('page', query.page);
    if (query.pageSize) params = params.set('pageSize', query.pageSize);
    if (query.search) params = params.set('search', query.search);
    if (query.status) params = params.set('status', query.status);
    if (query.storeId) params = params.set('storeId', query.storeId);
    if (query.range) params = params.set('range', query.range);
    if (query.from) params = params.set('from', query.from);
    if (query.to) params = params.set('to', query.to);

    return this.http
      .get<ApiEnvelope<OrderListResponse>>(this.base, { params })
      .pipe(map((r) => r.data));
  }

  detail(id: string): Observable<OrderDetail> {
    return this.http
      .get<ApiEnvelope<OrderDetail>>(`${this.base}/${id}`)
      .pipe(map((r) => r.data));
  }
}
