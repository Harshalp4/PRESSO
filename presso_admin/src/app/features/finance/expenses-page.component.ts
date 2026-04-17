import { Component, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import {
  FinanceService,
  Expense,
  PaginatedResponse,
} from './finance.service';

const CATEGORIES = [
  'Facility', 'Marketing', 'Operations', 'Supplies',
  'Logistics', 'Salaries', 'Rent', 'Utilities', 'Other',
];

@Component({
  selector: 'app-expenses-page',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './expenses-page.component.html',
  styleUrl: './expenses-page.component.scss',
})
export class ExpensesPageComponent {
  readonly categories = CATEGORIES;

  data = signal<PaginatedResponse<Expense> | null>(null);
  loading = signal(false);
  error = signal<string | null>(null);
  page = signal(1);
  filterCategory = signal('');

  // Modal
  modalOpen = signal(false);
  editing = signal<Expense | null>(null);
  formCategory = signal('Facility');
  formDescription = signal('');
  formAmount = signal<number | null>(null);
  formDate = signal(this.todayIso());
  formReference = signal('');
  saving = signal(false);
  formError = signal<string | null>(null);

  totalExpenses = computed(() => {
    const d = this.data();
    return d ? d.totalCount : 0;
  });

  constructor(private api: FinanceService) {
    this.load();
  }

  load() {
    this.loading.set(true);
    this.error.set(null);
    this.api
      .getExpenses(this.page(), 15, this.filterCategory() || undefined)
      .subscribe({
        next: (r) => {
          this.data.set(r);
          this.loading.set(false);
        },
        error: (err) => {
          this.error.set(err?.error?.message || 'Failed to load expenses');
          this.loading.set(false);
        },
      });
  }

  setCategory(c: string) {
    this.filterCategory.set(c);
    this.page.set(1);
    this.load();
  }

  goPage(p: number) {
    this.page.set(p);
    this.load();
  }

  openNew() {
    this.editing.set(null);
    this.formCategory.set('Facility');
    this.formDescription.set('');
    this.formAmount.set(null);
    this.formDate.set(this.todayIso());
    this.formReference.set('');
    this.formError.set(null);
    this.modalOpen.set(true);
  }

  openEdit(e: Expense) {
    this.editing.set(e);
    this.formCategory.set(e.category);
    this.formDescription.set(e.description);
    this.formAmount.set(e.amount);
    this.formDate.set(e.date);
    this.formReference.set(e.reference || '');
    this.formError.set(null);
    this.modalOpen.set(true);
  }

  close() {
    if (this.saving()) return;
    this.modalOpen.set(false);
  }

  submit() {
    if (!this.formDescription().trim()) {
      this.formError.set('Description is required.');
      return;
    }
    const amt = this.formAmount();
    if (!amt || amt <= 0) {
      this.formError.set('Amount must be greater than zero.');
      return;
    }
    this.saving.set(true);
    this.formError.set(null);

    const ed = this.editing();
    if (ed) {
      this.api
        .updateExpense(ed.id, {
          category: this.formCategory(),
          description: this.formDescription(),
          amount: amt,
          date: this.formDate(),
          reference: this.formReference() || null,
        })
        .subscribe({
          next: () => {
            this.saving.set(false);
            this.modalOpen.set(false);
            this.load();
          },
          error: (err) => {
            this.formError.set(err?.error?.message || 'Failed to save');
            this.saving.set(false);
          },
        });
    } else {
      this.api
        .createExpense({
          category: this.formCategory(),
          description: this.formDescription(),
          amount: amt,
          date: this.formDate(),
          reference: this.formReference() || undefined,
        })
        .subscribe({
          next: () => {
            this.saving.set(false);
            this.modalOpen.set(false);
            this.load();
          },
          error: (err) => {
            this.formError.set(err?.error?.message || 'Failed to create');
            this.saving.set(false);
          },
        });
    }
  }

  deleteExpense(e: Expense) {
    if (!confirm(`Delete "${e.description}"?`)) return;
    this.api.deleteExpense(e.id).subscribe({
      next: () => this.load(),
      error: (err) =>
        this.error.set(err?.error?.message || 'Failed to delete'),
    });
  }

  formatCurrency(n: number): string {
    return '₹' + n.toLocaleString('en-IN', { minimumFractionDigits: 0, maximumFractionDigits: 0 });
  }

  formatDate(iso: string): string {
    const [y, m, d] = iso.split('-').map(Number);
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${d} ${months[m]} ${y}`;
  }

  private todayIso(): string {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }
}
