import { Component, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import {
  SlotsService,
  AdminSlot,
  CreateSlotRequest,
} from './slots.service';

@Component({
  selector: 'app-slots-page',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './slots-page.component.html',
  styleUrl: './slots-page.component.scss',
})
export class SlotsPageComponent {
  slots = signal<AdminSlot[]>([]);
  loading = signal(false);
  error = signal<string | null>(null);

  // ===== Modal =====
  modalOpen = signal(false);
  editing = signal<AdminSlot | null>(null);
  formStart = signal('09:00');
  formEnd = signal('11:00');
  formMax = signal<number | null>(10);
  formActive = signal(true);
  saving = signal(false);
  formError = signal<string | null>(null);

  sortedSlots = computed(() =>
    [...this.slots()].sort((a, b) => {
      if (a.sortOrder !== b.sortOrder) return a.sortOrder - b.sortOrder;
      return a.startTime.localeCompare(b.startTime);
    })
  );

  totalSlots = computed(() => this.slots().length);
  activeSlots = computed(() => this.slots().filter((s) => s.isActive).length);
  totalCapacity = computed(() =>
    this.slots()
      .filter((s) => s.isActive)
      .reduce((acc, s) => acc + s.maxOrders, 0)
  );

  constructor(private slotsApi: SlotsService) {
    this.load();
  }

  load() {
    this.loading.set(true);
    this.error.set(null);
    this.slotsApi.list().subscribe({
      next: (res) => {
        this.slots.set(res);
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set(err?.error?.message || 'Failed to load slots');
        this.loading.set(false);
      },
    });
  }

  // ===== Modal actions =====
  openNew() {
    this.editing.set(null);
    this.formStart.set('09:00');
    this.formEnd.set('11:00');
    this.formMax.set(10);
    this.formActive.set(true);
    this.formError.set(null);
    this.modalOpen.set(true);
  }

  openEdit(s: AdminSlot) {
    this.editing.set(s);
    this.formStart.set(s.startTime.slice(0, 5));
    this.formEnd.set(s.endTime.slice(0, 5));
    this.formMax.set(s.maxOrders);
    this.formActive.set(s.isActive);
    this.formError.set(null);
    this.modalOpen.set(true);
  }

  close() {
    if (this.saving()) return;
    this.modalOpen.set(false);
  }

  submit() {
    const max = this.formMax();
    if (max === null || max <= 0) {
      this.formError.set('Capacity must be greater than zero.');
      return;
    }
    if (max > 100) {
      this.formError.set('Capacity cannot exceed 100.');
      return;
    }
    if (this.formStart() >= this.formEnd()) {
      this.formError.set('End time must be after start time.');
      return;
    }
    this.saving.set(true);
    this.formError.set(null);
    const editing = this.editing();
    if (editing) {
      this.slotsApi
        .update(editing.id, {
          maxOrders: max,
          isActive: this.formActive(),
        })
        .subscribe({
          next: (updated) => {
            this.slots.update((arr) =>
              arr.map((s) => (s.id === updated.id ? updated : s))
            );
            this.saving.set(false);
            this.modalOpen.set(false);
          },
          error: (err) => {
            this.formError.set(err?.error?.message || 'Failed to save');
            this.saving.set(false);
          },
        });
    } else {
      const body: CreateSlotRequest = {
        startTime: `${this.formStart()}:00`,
        endTime: `${this.formEnd()}:00`,
        maxOrders: max,
      };
      this.slotsApi.create(body).subscribe({
        next: (created) => {
          this.slots.update((arr) => [...arr, created]);
          this.saving.set(false);
          this.modalOpen.set(false);
        },
        error: (err) => {
          this.formError.set(err?.error?.message || 'Failed to create');
          this.saving.set(false);
        },
      });
    }
  }

  toggleActive(s: AdminSlot) {
    this.slotsApi.update(s.id, { isActive: !s.isActive }).subscribe({
      next: (updated) => {
        this.slots.update((arr) =>
          arr.map((x) => (x.id === updated.id ? updated : x))
        );
      },
      error: (err) =>
        this.error.set(err?.error?.message || 'Failed to update'),
    });
  }

  timeLabel(t: string): string {
    // "HH:mm:ss" → "HH:mm"
    return t.slice(0, 5);
  }
}
