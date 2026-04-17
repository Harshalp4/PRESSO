import { Component, effect, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import {
  CustomersService,
  CustomerListItem,
  CustomerListQuery,
} from './customers.service';

@Component({
  selector: 'app-customers-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, DatePipe],
  templateUrl: './customers-list.component.html',
  styleUrl: './customers-list.component.scss',
})
export class CustomersListComponent {
  search = signal('');
  page = signal(1);
  pageSize = signal(25);

  items = signal<CustomerListItem[]>([]);
  totalCount = signal(0);
  totalPages = signal(0);
  loading = signal(false);
  error = signal<string | null>(null);

  constructor(private customersService: CustomersService) {
    effect(
      () => {
        this.page();
        this.load();
      },
      { allowSignalWrites: true }
    );
  }

  load(): void {
    this.loading.set(true);
    this.error.set(null);
    const query: CustomerListQuery = {
      page: this.page(),
      pageSize: this.pageSize(),
      search: this.search().trim() || undefined,
    };
    this.customersService.list(query).subscribe({
      next: (res) => {
        this.items.set(res.items);
        this.totalCount.set(res.totalCount);
        this.totalPages.set(res.totalPages);
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set(err?.error?.message || 'Failed to load customers');
        this.loading.set(false);
      },
    });
  }

  private searchTimer: any;
  onSearchInput(v: string) {
    this.search.set(v);
    clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => {
      this.page.set(1);
      this.load();
    }, 300);
  }

  prev() {
    if (this.page() > 1) this.page.set(this.page() - 1);
  }
  next() {
    if (this.page() < this.totalPages()) this.page.set(this.page() + 1);
  }
}
