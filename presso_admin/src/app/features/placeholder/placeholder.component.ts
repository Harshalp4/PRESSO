import { Component, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

@Component({
  selector: 'app-placeholder',
  standalone: true,
  template: `
    <div class="ph">
      <h1>{{ title }}</h1>
      <p>This screen is not built yet. Coming in the next iteration.</p>
    </div>
  `,
  styles: [
    `
      .ph {
        background: #0a1628;
        border: 1px dashed rgba(148, 163, 184, 0.2);
        border-radius: 14px;
        padding: 48px 28px;
        text-align: center;
        color: #94a3b8;
      }
      h1 {
        margin: 0 0 8px;
        font-size: 22px;
        color: #e2e8f0;
      }
      p {
        margin: 0;
        font-size: 13px;
      }
    `,
  ],
})
export class PlaceholderComponent {
  title = inject(ActivatedRoute).snapshot.data['title'] || 'Coming soon';
}
