import type { AuthUser } from './types';

// Svelte 5: use a class-based store to allow mutation from outside
class AuthStore {
  user = $state<AuthUser | null>(null);

  constructor() {
    if (typeof window !== 'undefined') {
      const stored = localStorage.getItem('syncup_auth');
      if (stored) {
        try {
          this.user = JSON.parse(stored) as AuthUser;
        } catch {
          this.user = null;
        }
      }
    }
  }

  setAuth(u: AuthUser) {
    this.user = u;
    if (typeof window !== 'undefined') {
      localStorage.setItem('syncup_auth', JSON.stringify(u));
    }
  }

  clearAuth() {
    this.user = null;
    if (typeof window !== 'undefined') {
      localStorage.removeItem('syncup_auth');
    }
  }
}

export const authStore = new AuthStore();

// Convenience helpers
export function setAuth(u: AuthUser) {
  authStore.setAuth(u);
}

export function clearAuth() {
  authStore.clearAuth();
  if (typeof window !== 'undefined') {
    window.location.href = '/';
  }
}
