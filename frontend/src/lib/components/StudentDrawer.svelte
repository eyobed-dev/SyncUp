<script lang="ts">
  import { authStore } from '$lib/stores.svelte';

  interface Props {
    onClose: () => void;
  }

  let { onClose }: Props = $props();

  function logout() {
    authStore.clearAuth();
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

    <div class="prof-name-pill">{authStore.user?.name ?? 'Student'}</div>

    <div class="role-badge">Student</div>

    <div class="info-spacer"></div>

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
    margin-bottom: 12px;
    text-align: center;
  }

  .role-badge {
    background: #E8EAF0;
    color: #666;
    font-size: 13px;
    padding: 4px 12px;
    border-radius: 12px;
    margin-bottom: 28px;
  }

  .info-spacer {
    flex-grow: 1;
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
