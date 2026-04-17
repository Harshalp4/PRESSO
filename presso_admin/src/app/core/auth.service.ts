import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap, map } from 'rxjs';
import { environment } from '../../environments/environment';

const TOKEN_KEY = 'presso_admin_token';
const USER_KEY = 'presso_admin_user';

export interface AdminUser {
  id: string;
  name: string;
  phone: string;
  role: string;
}

interface ApiEnvelope<T> {
  success: boolean;
  message: string | null;
  data: T;
}

interface AuthResponseData {
  accessToken: string;
  refreshToken: string;
  user: AdminUser;
}

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly _token = signal<string | null>(localStorage.getItem(TOKEN_KEY));
  private readonly _user = signal<AdminUser | null>(
    JSON.parse(localStorage.getItem(USER_KEY) || 'null')
  );

  readonly token = this._token.asReadonly();
  readonly user = this._user.asReadonly();
  readonly isAuthenticated = computed(() => !!this._token());

  constructor(private http: HttpClient) {}

  login(username: string, password: string): Observable<AuthResponseData> {
    return this.http
      .post<ApiEnvelope<AuthResponseData>>(
        `${environment.apiBaseUrl}/api/auth/admin-login`,
        { username, password }
      )
      .pipe(
        map((res) => res.data),
        tap((data) => {
          if (data?.user?.role !== 'Admin') {
            throw new Error('This account is not an admin.');
          }
          localStorage.setItem(TOKEN_KEY, data.accessToken);
          localStorage.setItem(USER_KEY, JSON.stringify(data.user));
          this._token.set(data.accessToken);
          this._user.set(data.user);
        })
      );
  }

  logout(): void {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    this._token.set(null);
    this._user.set(null);
  }
}
