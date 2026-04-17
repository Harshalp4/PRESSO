import { Component, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { CustomersService, CustomerDetail } from './customers.service';
import { statusLabel, statusColor } from '../../shared/order-status';

@Component({
  selector: 'app-customer-detail',
  standalone: true,
  imports: [CommonModule, RouterLink, DatePipe],
  templateUrl: './customer-detail.component.html',
  styleUrl: './customer-detail.component.scss',
})
export class CustomerDetailComponent implements OnInit {
  customerId = '';
  customer = signal<CustomerDetail | null>(null);
  loading = signal(false);
  error = signal<string | null>(null);

  readonly statusLabel = statusLabel;
  readonly statusColor = statusColor;

  constructor(
    private route: ActivatedRoute,
    private customersService: CustomersService
  ) {}

  ngOnInit(): void {
    this.customerId = this.route.snapshot.paramMap.get('id') ?? '';
    this.load();
  }

  load(): void {
    if (!this.customerId) return;
    this.loading.set(true);
    this.error.set(null);
    this.customersService.detail(this.customerId).subscribe({
      next: (d) => {
        this.customer.set(d);
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set(err?.error?.message || 'Failed to load customer');
        this.loading.set(false);
      },
    });
  }
}
