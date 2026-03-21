<script lang="ts">
  import type { Professor } from '$lib/types';
  import { clearAuth } from '$lib/stores.svelte';

  interface Props {
    professor: Professor;
    onClose: () => void;
  }

  let { professor, onClose }: Props = $props();

  function logout() {
    clearAuth();
  }

  // Click outside to close
  function handleBackdropClick(e: MouseEvent) {
    if ((e.target as HTMLElement).classList.contains('drawer-backdrop')) {
      onClose();
    }
  }
</script>

<div class="drawer-backdrop" onclick={handleBackdropClick} role="presentation">
  <div class="drawer">
    <div class="prof-avatar-lg">
      <span class="prof-icon">⊙</span>
    </div>

    <div class="prof-name-pill">{professor.name}</div>

    <ul class="info-list">
      <li>
        <span class="info-icon">▷</span>
        <span class="info-text">{professor.role}</span>
      </li>
      {#if professor.phone}
        <li>
          <span class="info-icon">✆</span>
          <a href="tel:{professor.phone}" class="info-link">{professor.phone}</a>
        </li>
      {/if}
      {#if professor.email}
        <li>
          <span class="info-icon">✉</span>
          <a href="mailto:{professor.email}" class="info-link">{professor.email}</a>
        </li>
      {/if}
      {#if professor.office}
        <li>
          <span class="info-icon">⊞</span>
          <span class="info-text">{professor.office}</span>
        </li>
      {/if}
      {#if professor.personal_id}
        <li>
          <span class="info-icon">#</span>
          <span class="info-text">{professor.personal_id} personal ID</span>
        </li>
      {/if}
    </ul>

    <button class="logout-btn" onclick={logout}>
      <span>↪</span> Logout
    </button>
  </div>
</div>

<style>
  .drawer-backdrop {
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.18);
    z-index: 200;
    display: flex;
    justify-content: flex-end;
  }

  .drawer {
    background: #F5F5FF;
    width: 280px;
    height: 100vh;
    padding: 40px 24px 32px;
    display: flex;
    flex-direction: column;
    align-items: center;
    box-shadow: -4px 0 24px rgba(107,78,255,0.12);
    animation: slideIn 0.25s ease;
  }

  @keyframes slideIn {
    from { transform: translateX(100%); }
    to { transform: translateX(0); }
  }

  .prof-avatar-lg {
    width: 64px;
    height: 64px;
    border-radius: 50%;
    background: #E8E0FF;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 16px;
  }

  .prof-icon {
    font-size: 28px;
    color: #6B4EFF;
  }

  .prof-name-pill {
    background: #DDD6FF;
    color: #3D1FA8;
    font-weight: 600;
    font-size: 15px;
    padding: 8px 20px;
    border-radius: 20px;
    margin-bottom: 28px;
    text-align: center;
  }

  .info-list {
    list-style: none;
    padding: 0;
    margin: 0 0 auto;
    width: 100%;
    display: flex;
    flex-direction: column;
    gap: 18px;
  }

  .info-list li {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .info-icon {
    font-size: 16px;
    color: #6B4EFF;
    width: 20px;
    flex-shrink: 0;
  }

  .info-text {
    font-size: 14px;
    color: #333;
  }

  .info-link {
    font-size: 14px;
    color: #6B4EFF;
    text-decoration: underline;
  }

  .logout-btn {
    margin-top: 32px;
    display: flex;
    align-items: center;
    gap: 8px;
    background: none;
    border: none;
    color: #555;
    font-size: 15px;
    cursor: pointer;
    font-family: inherit;
    padding: 8px 0;
  }

  .logout-btn:hover {
    color: #6B4EFF;
  }
</style>
