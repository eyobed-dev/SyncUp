<script lang="ts">
  import { goto } from '$app/navigation';
  import { api } from '$lib/api';
  import { setAuth, authStore } from '$lib/stores.svelte';
  import type { LoginResponse } from '$lib/types';

  let email = $state('');
  let password = $state('');
  let role = $state<'professor' | 'student'>('student');
  let error = $state('');
  let loading = $state(false);

  $effect(() => {
    if (authStore.user) {
      goto(authStore.user.role === 'professor' ? '/professor' : '/student');
    }
  });

  async function handleLogin(e: SubmitEvent) {
    e.preventDefault();
    error = '';
    loading = true;
    try {
      const res = await api.post<LoginResponse>('/api/auth/login', { email, password, role });
      setAuth({ token: res.token, role: res.role as 'professor' | 'student', user_id: res.user_id, name: res.name });
      goto(res.role === 'professor' ? '/professor' : '/student');
    } catch (e: any) {
      error = e.message || 'Login failed';
    } finally {
      loading = false;
    }
  }
</script>

<main class="login-page">
  <div class="login-card">
    <div class="logo-area">
      <div class="logo-icon">⊙</div>
      <h1 class="logo-title">SyncUp</h1>
      <p class="logo-sub">University Appointment Scheduling</p>
    </div>

    <form onsubmit={handleLogin}>
      {#if error}
        <div class="error-msg">{error}</div>
      {/if}

      <div class="role-switch">
        <button
          type="button"
          class="role-btn"
          class:active={role === 'student'}
          onclick={() => role = 'student'}
          id="btn-role-student"
        >Student</button>
        <button
          type="button"
          class="role-btn"
          class:active={role === 'professor'}
          onclick={() => role = 'professor'}
          id="btn-role-professor"
        >Professor</button>
      </div>

      <div class="field">
        <label for="login-email">Email</label>
        <input id="login-email" type="email" bind:value={email} required autocomplete="email" />
      </div>

      <div class="field">
        <label for="login-password">Password</label>
        <input id="login-password" type="password" bind:value={password} required autocomplete="current-password" />
      </div>

      <button type="submit" class="submit-btn" disabled={loading} id="btn-login">
        {loading ? 'Signing in…' : 'Sign In'}
      </button>
    </form>

    <div class="demo-creds">
      <p><strong>Professor:</strong> herout@fit.vut.cz / <code>herout123</code></p>
      <p><strong>Student:</strong> jan.novak@stud.fit.vut.cz / <code>student123</code></p>
    </div>
  </div>
</main>

<style>
  .login-page {
    min-height: 100vh;
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    background: linear-gradient(135deg, #f5f3ff 0%, #ede9fe 50%, #e0d9ff 100%);
    padding: 24px;
  }

  .login-card {
    background: white;
    border-radius: 24px;
    padding: 40px 36px;
    width: 100%;
    max-width: 400px;
    box-shadow: 0 20px 60px rgba(107,78,255,0.15);
  }

  .logo-area {
    text-align: center;
    margin-bottom: 32px;
  }

  .logo-icon {
    font-size: 48px;
    color: #6B4EFF;
    margin-bottom: 8px;
  }

  .logo-title {
    font-size: 32px;
    font-weight: 700;
    color: #1a1a2e;
    margin-bottom: 6px;
  }

  .logo-sub {
    font-size: 14px;
    color: #888;
  }

  .role-switch {
    display: flex;
    background: #f0eeff;
    border-radius: 12px;
    padding: 4px;
    margin-bottom: 24px;
    gap: 4px;
  }

  .role-btn {
    flex: 1;
    border: none;
    background: transparent;
    border-radius: 9px;
    padding: 10px;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    font-family: inherit;
    color: #666;
    transition: all 0.2s;
  }

  .role-btn.active {
    background: white;
    color: #6B4EFF;
    font-weight: 600;
    box-shadow: 0 2px 8px rgba(107,78,255,0.15);
  }

  .field {
    margin-bottom: 20px;
  }

  label {
    display: block;
    font-size: 13px;
    font-weight: 500;
    color: #555;
    margin-bottom: 6px;
  }

  input {
    width: 100%;
    border: 1.5px solid #e0e0e0;
    border-radius: 10px;
    padding: 12px 14px;
    font-size: 15px;
    font-family: inherit;
    outline: none;
    transition: border-color 0.2s;
  }

  input:focus {
    border-color: #6B4EFF;
  }

  .submit-btn {
    width: 100%;
    background: #6B4EFF;
    color: white;
    border: none;
    border-radius: 12px;
    padding: 14px;
    font-size: 16px;
    font-weight: 600;
    cursor: pointer;
    font-family: inherit;
    transition: opacity 0.2s, transform 0.1s;
    margin-top: 8px;
  }

  .submit-btn:hover:not(:disabled) {
    opacity: 0.92;
    transform: translateY(-1px);
  }

  .submit-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .error-msg {
    background: #fff0f0;
    color: #c62828;
    border-radius: 8px;
    padding: 10px 14px;
    font-size: 13px;
    margin-bottom: 16px;
  }

  .demo-creds {
    margin-top: 24px;
    padding: 14px;
    background: #f9f9f9;
    border-radius: 10px;
    font-size: 12px;
    color: #666;
    line-height: 1.8;
  }

  .demo-creds code {
    background: #ede9fe;
    padding: 1px 5px;
    border-radius: 4px;
    color: #6B4EFF;
    font-family: monospace;
  }
</style>
