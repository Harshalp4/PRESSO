import { Component, computed, signal, ElementRef, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { forkJoin } from 'rxjs';
import {
  CatalogService,
  AdminService,
  AdminGarment,
  AdminTreatment,
} from './catalog.service';

type Tab = 'services' | 'garments' | 'treatments';

@Component({
  selector: 'app-catalog-page',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './catalog-page.component.html',
  styleUrl: './catalog-page.component.scss',
})
export class CatalogPageComponent {
  services = signal<AdminService[]>([]);
  garments = signal<AdminGarment[]>([]);
  treatments = signal<AdminTreatment[]>([]);
  loading = signal(false);
  error = signal<string | null>(null);

  activeTab = signal<Tab>('services');

  @ViewChild('servicesSection') servicesSection?: ElementRef<HTMLElement>;
  @ViewChild('garmentsSection') garmentsSection?: ElementRef<HTMLElement>;
  @ViewChild('treatmentsSection') treatmentsSection?: ElementRef<HTMLElement>;

  // Slug is derived from name for the card subtitle — the schema doesn't
  // persist slugs today.
  slug(s: AdminService): string {
    return s.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');
  }

  // Map a service id to its base price for use in the garment section's
  // helper text (avoids an extra query).
  servicePrice = computed(() => {
    const map = new Map<string, number>();
    for (const s of this.services()) map.set(s.id, s.pricePerPiece);
    return map;
  });

  // ============ Service modal ============
  svcModalOpen = signal(false);
  editingService = signal<AdminService | null>(null);
  svcName = signal('');
  svcDescription = signal('');
  svcCategory = signal('');
  svcPrice = signal<number | null>(null);
  svcEmoji = signal('');
  svcSort = signal<number | null>(null);
  svcActive = signal(true);
  svcSaving = signal(false);
  svcError = signal<string | null>(null);

  // ============ Garment modal ============
  grmModalOpen = signal(false);
  editingGarment = signal<AdminGarment | null>(null);
  grmServiceId = signal('');
  grmName = signal('');
  grmEmoji = signal('');
  grmPriceOverride = signal<number | null>(null);
  grmSort = signal<number | null>(null);
  grmSaving = signal(false);
  grmError = signal<string | null>(null);

  // ============ Treatment modal ============
  trtModalOpen = signal(false);
  editingTreatment = signal<AdminTreatment | null>(null);
  trtServiceId = signal('');
  trtName = signal('');
  trtDescription = signal('');
  trtMultiplier = signal<number | null>(null);
  trtSort = signal<number | null>(null);
  trtActive = signal(true);
  trtSaving = signal(false);
  trtError = signal<string | null>(null);

  activeServices = computed(() =>
    this.services().filter((s) => s.isActive)
  );

  constructor(private catalog: CatalogService) {
    this.load();
  }

  load() {
    this.loading.set(true);
    this.error.set(null);
    forkJoin({
      services: this.catalog.listServices(),
      garments: this.catalog.listGarments(),
      treatments: this.catalog.listTreatments(),
    }).subscribe({
      next: (res) => {
        this.services.set(res.services);
        this.garments.set(res.garments);
        this.treatments.set(res.treatments);
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set(err?.error?.message || 'Failed to load catalog');
        this.loading.set(false);
      },
    });
  }

  // Tabs behave like scroll-anchors — clicking scrolls the section into
  // view while also marking it as "active" for the underline state.
  setTab(t: Tab) {
    this.activeTab.set(t);
    const el =
      t === 'services'
        ? this.servicesSection?.nativeElement
        : t === 'garments'
          ? this.garmentsSection?.nativeElement
          : this.treatmentsSection?.nativeElement;
    el?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  // ============ Service ============
  openNewService() {
    this.editingService.set(null);
    this.svcName.set('');
    this.svcDescription.set('');
    this.svcCategory.set('');
    this.svcPrice.set(null);
    this.svcEmoji.set('');
    this.svcSort.set(0);
    this.svcActive.set(true);
    this.svcError.set(null);
    this.svcModalOpen.set(true);
  }

  openEditService(s: AdminService) {
    this.editingService.set(s);
    this.svcName.set(s.name);
    this.svcDescription.set(s.description || '');
    this.svcCategory.set(s.category || '');
    this.svcPrice.set(s.pricePerPiece);
    this.svcEmoji.set(s.emoji || '');
    this.svcSort.set(s.sortOrder);
    this.svcActive.set(s.isActive);
    this.svcError.set(null);
    this.svcModalOpen.set(true);
  }

  closeSvcModal() {
    if (this.svcSaving()) return;
    this.svcModalOpen.set(false);
  }

  submitService() {
    const name = this.svcName().trim();
    const price = this.svcPrice();
    if (!name) {
      this.svcError.set('Name is required.');
      return;
    }
    if (price === null || price < 0) {
      this.svcError.set('Price must be zero or positive.');
      return;
    }
    this.svcSaving.set(true);
    this.svcError.set(null);
    const body = {
      name,
      description: this.svcDescription().trim() || null,
      category: this.svcCategory().trim() || null,
      pricePerPiece: price,
      emoji: this.svcEmoji().trim() || null,
      sortOrder: this.svcSort() ?? 0,
    };
    const editing = this.editingService();
    const req = editing
      ? this.catalog.updateService(editing.id, {
          ...body,
          isActive: this.svcActive(),
        })
      : this.catalog.createService(body);
    req.subscribe({
      next: (res) => {
        if (editing) {
          this.services.update((arr) =>
            arr.map((s) => (s.id === res.id ? res : s))
          );
        } else {
          this.services.update((arr) => [...arr, res]);
        }
        this.svcSaving.set(false);
        this.svcModalOpen.set(false);
      },
      error: (err) => {
        this.svcError.set(err?.error?.message || 'Failed to save');
        this.svcSaving.set(false);
      },
    });
  }

  toggleServiceActive(s: AdminService) {
    this.catalog.updateService(s.id, { isActive: !s.isActive }).subscribe({
      next: (updated) =>
        this.services.update((arr) =>
          arr.map((x) => (x.id === updated.id ? updated : x))
        ),
      error: (err) =>
        this.error.set(err?.error?.message || 'Failed to update'),
    });
  }

  // ============ Garment ============
  openNewGarment() {
    this.editingGarment.set(null);
    const first = this.activeServices()[0];
    this.grmServiceId.set(first?.id || '');
    this.grmName.set('');
    this.grmEmoji.set('');
    this.grmPriceOverride.set(null);
    this.grmSort.set(0);
    this.grmError.set(null);
    this.grmModalOpen.set(true);
  }

  openEditGarment(g: AdminGarment) {
    this.editingGarment.set(g);
    this.grmServiceId.set(g.serviceId);
    this.grmName.set(g.name);
    this.grmEmoji.set(g.emoji || '');
    this.grmPriceOverride.set(g.priceOverride);
    this.grmSort.set(g.sortOrder);
    this.grmError.set(null);
    this.grmModalOpen.set(true);
  }

  closeGrmModal() {
    if (this.grmSaving()) return;
    this.grmModalOpen.set(false);
  }

  submitGarment() {
    const name = this.grmName().trim();
    if (!name) {
      this.grmError.set('Name is required.');
      return;
    }
    const editing = this.editingGarment();
    if (!editing && !this.grmServiceId()) {
      this.grmError.set('Pick a parent service.');
      return;
    }
    this.grmSaving.set(true);
    this.grmError.set(null);
    const priceOverride =
      this.grmPriceOverride() === null ? null : Number(this.grmPriceOverride());
    if (editing) {
      this.catalog
        .updateGarment(editing.id, {
          name,
          emoji: this.grmEmoji().trim() || null,
          priceOverride,
          sortOrder: this.grmSort() ?? 0,
        })
        .subscribe({
          next: (updated) => {
            this.garments.update((arr) =>
              arr.map((g) => (g.id === updated.id ? updated : g))
            );
            this.grmSaving.set(false);
            this.grmModalOpen.set(false);
          },
          error: (err) => {
            this.grmError.set(err?.error?.message || 'Failed to save');
            this.grmSaving.set(false);
          },
        });
    } else {
      this.catalog
        .createGarment({
          serviceId: this.grmServiceId(),
          name,
          emoji: this.grmEmoji().trim() || null,
          priceOverride,
          sortOrder: this.grmSort() ?? 0,
        })
        .subscribe({
          next: (created) => {
            this.garments.update((arr) => [...arr, created]);
            this.services.update((arr) =>
              arr.map((s) =>
                s.id === created.serviceId
                  ? { ...s, garmentCount: s.garmentCount + 1 }
                  : s
              )
            );
            this.grmSaving.set(false);
            this.grmModalOpen.set(false);
          },
          error: (err) => {
            this.grmError.set(err?.error?.message || 'Failed to create');
            this.grmSaving.set(false);
          },
        });
    }
  }

  deleteGarment(g: AdminGarment) {
    if (!confirm(`Delete garment "${g.name}"?`)) return;
    this.catalog.deleteGarment(g.id).subscribe({
      next: () => {
        this.garments.update((arr) => arr.filter((x) => x.id !== g.id));
        this.services.update((arr) =>
          arr.map((s) =>
            s.id === g.serviceId
              ? { ...s, garmentCount: Math.max(0, s.garmentCount - 1) }
              : s
          )
        );
      },
      error: (err) =>
        this.error.set(err?.error?.message || 'Failed to delete'),
    });
  }

  // ============ Treatment ============
  openNewTreatment() {
    this.editingTreatment.set(null);
    const first = this.activeServices()[0];
    this.trtServiceId.set(first?.id || '');
    this.trtName.set('');
    this.trtDescription.set('');
    this.trtMultiplier.set(1);
    this.trtSort.set(0);
    this.trtActive.set(true);
    this.trtError.set(null);
    this.trtModalOpen.set(true);
  }

  openEditTreatment(t: AdminTreatment) {
    this.editingTreatment.set(t);
    this.trtServiceId.set(t.serviceId);
    this.trtName.set(t.name);
    this.trtDescription.set(t.description || '');
    this.trtMultiplier.set(t.priceMultiplier);
    this.trtSort.set(t.sortOrder);
    this.trtActive.set(t.isActive);
    this.trtError.set(null);
    this.trtModalOpen.set(true);
  }

  closeTrtModal() {
    if (this.trtSaving()) return;
    this.trtModalOpen.set(false);
  }

  submitTreatment() {
    const name = this.trtName().trim();
    const mult = this.trtMultiplier();
    if (!name) {
      this.trtError.set('Name is required.');
      return;
    }
    if (mult === null || mult <= 0) {
      this.trtError.set('Multiplier must be greater than zero.');
      return;
    }
    const editing = this.editingTreatment();
    if (!editing && !this.trtServiceId()) {
      this.trtError.set('Pick a parent service.');
      return;
    }
    this.trtSaving.set(true);
    this.trtError.set(null);
    if (editing) {
      this.catalog
        .updateTreatment(editing.id, {
          name,
          description: this.trtDescription().trim() || null,
          priceMultiplier: mult,
          isActive: this.trtActive(),
          sortOrder: this.trtSort() ?? 0,
        })
        .subscribe({
          next: (updated) => {
            this.treatments.update((arr) =>
              arr.map((x) => (x.id === updated.id ? updated : x))
            );
            this.trtSaving.set(false);
            this.trtModalOpen.set(false);
          },
          error: (err) => {
            this.trtError.set(err?.error?.message || 'Failed to save');
            this.trtSaving.set(false);
          },
        });
    } else {
      this.catalog
        .createTreatment({
          serviceId: this.trtServiceId(),
          name,
          description: this.trtDescription().trim() || null,
          priceMultiplier: mult,
          sortOrder: this.trtSort() ?? 0,
        })
        .subscribe({
          next: (created) => {
            this.treatments.update((arr) => [...arr, created]);
            this.services.update((arr) =>
              arr.map((s) =>
                s.id === created.serviceId
                  ? { ...s, treatmentCount: s.treatmentCount + 1 }
                  : s
              )
            );
            this.trtSaving.set(false);
            this.trtModalOpen.set(false);
          },
          error: (err) => {
            this.trtError.set(err?.error?.message || 'Failed to create');
            this.trtSaving.set(false);
          },
        });
    }
  }

  toggleTreatmentActive(t: AdminTreatment) {
    this.catalog.updateTreatment(t.id, { isActive: !t.isActive }).subscribe({
      next: (updated) =>
        this.treatments.update((arr) =>
          arr.map((x) => (x.id === updated.id ? updated : x))
        ),
      error: (err) =>
        this.error.set(err?.error?.message || 'Failed to update'),
    });
  }
}
