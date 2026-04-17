import { Component, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { forkJoin } from 'rxjs';
import {
  CatalogService,
  AdminService,
  AdminGarment,
} from './catalog.service';
import {
  ZonesService,
  ServiceZone,
  CreateZoneRequest,
  UpdateZoneRequest,
} from './zones.service';

@Component({
  selector: 'app-pricing-matrix',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './pricing-matrix.component.html',
  styleUrl: './pricing-matrix.component.scss',
})
export class PricingMatrixComponent {
  services = signal<AdminService[]>([]);
  garments = signal<AdminGarment[]>([]);
  zones = signal<ServiceZone[]>([]);
  loading = signal(false);
  error = signal<string | null>(null);

  selectedServiceId = signal<string>('');

  activeServices = computed(() =>
    this.services().filter((s) => s.isActive)
  );

  activeZones = computed(() =>
    this.zones().filter((z) => z.isActive)
  );

  selectedService = computed(() =>
    this.services().find((s) => s.id === this.selectedServiceId()) || null
  );

  // Rows of the matrix = garments that belong to the selected service.
  matrixRows = computed(() => {
    const sid = this.selectedServiceId();
    if (!sid) return [];
    return this.garments().filter((g) => g.serviceId === sid);
  });

  // Base price for a garment = override OR parent service base price.
  basePrice(g: AdminGarment): number {
    const svc = this.services().find((s) => s.id === g.serviceId);
    return g.priceOverride ?? svc?.pricePerPiece ?? 0;
  }

  // ===== Zone modal =====
  zoneModalOpen = signal(false);
  editingZone = signal<ServiceZone | null>(null);
  zName = signal('');
  zPincode = signal('');
  zCity = signal('');
  zArea = signal('');
  zDescription = signal('');
  zActive = signal(true);
  zSort = signal<number | null>(0);
  zSaving = signal(false);
  zError = signal<string | null>(null);

  constructor(
    private catalog: CatalogService,
    private zonesApi: ZonesService
  ) {
    this.load();
  }

  load() {
    this.loading.set(true);
    this.error.set(null);
    forkJoin({
      services: this.catalog.listServices(),
      garments: this.catalog.listGarments(),
      zones: this.zonesApi.list(),
    }).subscribe({
      next: (res) => {
        this.services.set(res.services);
        this.garments.set(res.garments);
        this.zones.set(res.zones);
        const active = res.services.filter((s) => s.isActive);
        if (!this.selectedServiceId() && active.length) {
          this.selectedServiceId.set(active[0].id);
        }
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set(err?.error?.message || 'Failed to load pricing data');
        this.loading.set(false);
      },
    });
  }

  // ===== Zone CRUD =====
  openNewZone() {
    this.editingZone.set(null);
    this.zName.set('');
    this.zPincode.set('');
    this.zCity.set('');
    this.zArea.set('');
    this.zDescription.set('');
    this.zActive.set(true);
    this.zSort.set(0);
    this.zError.set(null);
    this.zoneModalOpen.set(true);
  }

  openEditZone(z: ServiceZone) {
    this.editingZone.set(z);
    this.zName.set(z.name);
    this.zPincode.set(z.pincode);
    this.zCity.set(z.city);
    this.zArea.set(z.area || '');
    this.zDescription.set(z.description || '');
    this.zActive.set(z.isActive);
    this.zSort.set(z.sortOrder);
    this.zError.set(null);
    this.zoneModalOpen.set(true);
  }

  closeZoneModal() {
    if (this.zSaving()) return;
    this.zoneModalOpen.set(false);
  }

  submitZone() {
    const name = this.zName().trim();
    const pincode = this.zPincode().trim();
    const city = this.zCity().trim();
    if (!name) {
      this.zError.set('Name is required.');
      return;
    }
    if (!/^\d{6}$/.test(pincode)) {
      this.zError.set('Pincode must be exactly 6 digits.');
      return;
    }
    if (!city) {
      this.zError.set('City is required.');
      return;
    }
    this.zSaving.set(true);
    this.zError.set(null);
    const editing = this.editingZone();
    if (editing) {
      const body: UpdateZoneRequest = {
        name,
        pincode,
        city,
        area: this.zArea().trim() || null,
        description: this.zDescription().trim() || null,
        isActive: this.zActive(),
        sortOrder: this.zSort() ?? 0,
      };
      this.zonesApi.update(editing.id, body).subscribe({
        next: (updated) => {
          this.zones.update((arr) =>
            arr.map((x) => (x.id === updated.id ? updated : x))
          );
          this.zSaving.set(false);
          this.zoneModalOpen.set(false);
        },
        error: (err) => {
          this.zError.set(err?.error?.message || 'Failed to save zone');
          this.zSaving.set(false);
        },
      });
    } else {
      const body: CreateZoneRequest = {
        name,
        pincode,
        city,
        area: this.zArea().trim() || null,
        description: this.zDescription().trim() || null,
        assignedStoreId: null,
      };
      this.zonesApi.create(body).subscribe({
        next: (created) => {
          this.zones.update((arr) => [...arr, created]);
          this.zSaving.set(false);
          this.zoneModalOpen.set(false);
        },
        error: (err) => {
          this.zError.set(err?.error?.message || 'Failed to create zone');
          this.zSaving.set(false);
        },
      });
    }
  }

  deactivateZone(z: ServiceZone) {
    if (!confirm(`Deactivate zone "${z.name}"?`)) return;
    this.zonesApi.delete(z.id).subscribe({
      next: () => {
        this.zones.update((arr) =>
          arr.map((x) => (x.id === z.id ? { ...x, isActive: false } : x))
        );
      },
      error: (err) =>
        this.error.set(err?.error?.message || 'Failed to deactivate zone'),
    });
  }
}
