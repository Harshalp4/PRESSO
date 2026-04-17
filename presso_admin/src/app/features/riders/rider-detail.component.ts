import { Component, OnInit, signal } from '@angular/core';
import { CommonModule, DatePipe } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import {
  RidersService,
  AdminRiderDetail,
} from './riders.service';
import { riderStatusLabel, riderStatusColor } from '../../shared/rider-status';

type ActionKind = 'approve' | 'reject' | 'suspend' | 'reinstate';

@Component({
  selector: 'app-rider-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, DatePipe],
  templateUrl: './rider-detail.component.html',
  styleUrl: './rider-detail.component.scss',
})
export class RiderDetailComponent implements OnInit {
  riderId = '';
  rider = signal<AdminRiderDetail | null>(null);
  loading = signal(false);
  error = signal<string | null>(null);

  // Action modal state.
  actionKind = signal<ActionKind | null>(null);
  actionReason = signal('');
  actionNotes = signal('');
  acting = signal(false);
  actionError = signal<string | null>(null);

  // Notes edit state.
  notesDraft = signal('');
  savingNotes = signal(false);

  readonly riderStatusLabel = riderStatusLabel;
  readonly riderStatusColor = riderStatusColor;

  constructor(
    private route: ActivatedRoute,
    private ridersService: RidersService
  ) {}

  ngOnInit(): void {
    this.riderId = this.route.snapshot.paramMap.get('id') ?? '';
    this.load();
  }

  load(): void {
    if (!this.riderId) return;
    this.loading.set(true);
    this.error.set(null);
    this.ridersService.detail(this.riderId).subscribe({
      next: (d) => {
        this.rider.set(d);
        this.notesDraft.set(d.adminNotes ?? '');
        this.loading.set(false);
      },
      error: (err) => {
        this.error.set(err?.error?.message || 'Failed to load rider');
        this.loading.set(false);
      },
    });
  }

  openAction(kind: ActionKind) {
    this.actionKind.set(kind);
    this.actionReason.set('');
    this.actionNotes.set('');
    this.actionError.set(null);
  }

  closeAction() {
    if (this.acting()) return;
    this.actionKind.set(null);
  }

  actionTitle(): string {
    switch (this.actionKind()) {
      case 'approve':
        return 'Approve rider';
      case 'reject':
        return 'Reject rider';
      case 'suspend':
        return 'Suspend rider';
      case 'reinstate':
        return 'Reinstate rider';
      default:
        return '';
    }
  }

  actionNeedsReason(): boolean {
    const k = this.actionKind();
    return k === 'reject' || k === 'suspend';
  }

  submitAction() {
    const kind = this.actionKind();
    if (!kind) return;
    if (this.actionNeedsReason() && !this.actionReason().trim()) {
      this.actionError.set('A reason is required.');
      return;
    }
    this.acting.set(true);
    this.actionError.set(null);
    const notes = this.actionNotes().trim() || null;
    const reason = this.actionReason().trim();

    const req =
      kind === 'approve'
        ? this.ridersService.approve(this.riderId, { adminNotes: notes })
        : kind === 'reject'
        ? this.ridersService.reject(this.riderId, { reason, adminNotes: notes })
        : kind === 'suspend'
        ? this.ridersService.suspend(this.riderId, { reason, adminNotes: notes })
        : this.ridersService.reinstate(this.riderId);

    req.subscribe({
      next: (d) => {
        this.rider.set(d);
        this.notesDraft.set(d.adminNotes ?? '');
        this.acting.set(false);
        this.actionKind.set(null);
      },
      error: (err) => {
        this.actionError.set(err?.error?.message || 'Action failed');
        this.acting.set(false);
      },
    });
  }

  saveNotes() {
    const r = this.rider();
    if (!r) return;
    const draft = this.notesDraft().trim();
    if ((r.adminNotes ?? '') === draft) return;
    this.savingNotes.set(true);
    this.ridersService
      .updateNotes(this.riderId, { adminNotes: draft || null })
      .subscribe({
        next: (d) => {
          this.rider.set(d);
          this.notesDraft.set(d.adminNotes ?? '');
          this.savingNotes.set(false);
        },
        error: () => {
          this.savingNotes.set(false);
        },
      });
  }
}
