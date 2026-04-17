import { Routes } from '@angular/router';
import { authGuard } from './core/auth.guard';

export const routes: Routes = [
  {
    path: 'login',
    loadComponent: () =>
      import('./features/login/login.component').then((m) => m.LoginComponent),
  },
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () =>
      import('./features/shell/shell.component').then((m) => m.ShellComponent),
    children: [
      { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./features/dashboard/dashboard.component').then(
            (m) => m.DashboardComponent
          ),
      },
      {
        path: 'orders',
        loadComponent: () =>
          import('./features/orders/orders-list.component').then(
            (m) => m.OrdersListComponent
          ),
      },
      {
        path: 'orders/:id',
        loadComponent: () =>
          import('./features/orders/order-detail.component').then(
            (m) => m.OrderDetailComponent
          ),
      },
      {
        path: 'riders',
        loadComponent: () =>
          import('./features/riders/riders-list.component').then(
            (m) => m.RidersListComponent
          ),
      },
      {
        path: 'riders/:id',
        loadComponent: () =>
          import('./features/riders/rider-detail.component').then(
            (m) => m.RiderDetailComponent
          ),
      },
      {
        path: 'slots',
        loadComponent: () =>
          import('./features/slots/slots-page.component').then(
            (m) => m.SlotsPageComponent
          ),
      },
      {
        path: 'customers',
        loadComponent: () =>
          import('./features/customers/customers-list.component').then(
            (m) => m.CustomersListComponent
          ),
      },
      {
        path: 'customers/:id',
        loadComponent: () =>
          import('./features/customers/customer-detail.component').then(
            (m) => m.CustomerDetailComponent
          ),
      },
      {
        path: 'finance/pnl',
        loadComponent: () =>
          import('./features/finance/finance-page.component').then(
            (m) => m.FinancePageComponent
          ),
      },
      {
        path: 'finance/expenses',
        loadComponent: () =>
          import('./features/finance/expenses-page.component').then(
            (m) => m.ExpensesPageComponent
          ),
      },
      {
        path: 'finance/payouts',
        loadComponent: () =>
          import('./features/finance/payouts-page.component').then(
            (m) => m.PayoutsPageComponent
          ),
      },
      {
        path: 'catalog',
        loadComponent: () =>
          import('./features/catalog/catalog-page.component').then(
            (m) => m.CatalogPageComponent
          ),
      },
      {
        path: 'catalog/pricing',
        loadComponent: () =>
          import('./features/catalog/pricing-matrix.component').then(
            (m) => m.PricingMatrixComponent
          ),
      },
    ],
  },
  { path: '**', redirectTo: '' },
];
