import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink, RouterLinkActive, RouterOutlet, Router } from '@angular/router';
import { AuthService } from '../../core/auth.service';

interface NavItem {
  label: string;
  icon: string;
  route: string;
  section: string;
}

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './shell.component.html',
  styleUrl: './shell.component.scss',
})
export class ShellComponent {
  readonly nav: NavItem[] = [
    { section: 'Overview', label: 'Dashboard', icon: '📊', route: '/dashboard' },
    { section: 'Operations', label: 'Orders', icon: '📦', route: '/orders' },
    { section: 'Operations', label: 'Riders', icon: '🛵', route: '/riders' },
    { section: 'Operations', label: 'Pickup Slots', icon: '⏰', route: '/slots' },
    { section: 'Operations', label: 'Customers', icon: '👥', route: '/customers' },
    { section: 'Finance', label: 'P&L / Earnings', icon: '💰', route: '/finance/pnl' },
    { section: 'Finance', label: 'Expenses', icon: '🧾', route: '/finance/expenses' },
    { section: 'Finance', label: 'Payouts', icon: '💸', route: '/finance/payouts' },
    { section: 'Catalog & Content', label: 'Services & Items', icon: '🧺', route: '/catalog' },
    { section: 'Catalog & Content', label: 'Pricing Matrix', icon: '💰', route: '/catalog/pricing' },
  ];

  readonly sections = ['Overview', 'Operations', 'Finance', 'Catalog & Content'];

  constructor(public auth: AuthService, private router: Router) {}

  itemsFor(section: string): NavItem[] {
    return this.nav.filter((n) => n.section === section);
  }

  logout(): void {
    this.auth.logout();
    this.router.navigate(['/login']);
  }
}
