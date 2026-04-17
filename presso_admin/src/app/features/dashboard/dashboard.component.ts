import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';

interface DashboardStats {
  totalOrders?: number;
  activeOrders?: number;
  totalRiders?: number;
  totalCustomers?: number;
  todayRevenue?: number;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss',
})
export class DashboardComponent {
  stats = signal<DashboardStats | null>(null);
  loading = signal(true);
  error = signal<string | null>(null);

  constructor(private http: HttpClient) {
    this.load();
  }

  load() {
    this.loading.set(true);
    this.error.set(null);
    this.http
      .get<{ data: DashboardStats } | DashboardStats>(`${environment.apiBaseUrl}/api/admin/dashboard`)
      .subscribe({
        next: (res: any) => {
          // Backend envelope may be { data: {...} } or bare
          this.stats.set(res?.data ?? res ?? {});
          this.loading.set(false);
        },
        error: (err) => {
          this.error.set(err?.error?.message || 'Failed to load dashboard');
          this.loading.set(false);
        },
      });
  }
}
