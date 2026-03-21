<script lang="ts">
  import { goto } from '$app/navigation';
  import { authStore } from '$lib/stores.svelte';
  import { api } from '$lib/api';
  import type { Professor, Slot } from '$lib/types';
  import CalendarGrid from '$lib/components/CalendarGrid.svelte';
  import WeekNavigator from '$lib/components/WeekNavigator.svelte';
  import BottomBar from '$lib/components/BottomBar.svelte';
  import ProfileDrawer from '$lib/components/ProfileDrawer.svelte';

  $effect(() => {
    if (!authStore.user) goto('/');
    else if (authStore.user.role !== 'professor') goto('/student');
  });

  let professor = $state<Professor | null>(null);
  let slots = $state<Slot[]>([]);
  let weekAnchor = $state(currentMondayAnchor());
  let showDrawer = $state(false);
  let loading = $state(false);

  function currentMondayAnchor(): string {
    const now = new Date();
    const dow = now.getDay();
    const diff = (dow === 0 ? -6 : 1 - dow);
    const mon = new Date(now);
    mon.setDate(now.getDate() + diff);
    return mon.toISOString().slice(0, 10);
  }

  async function loadSchedule() {
    if (!authStore.user) return;
    loading = true;
    try {
      const [prof, sl] = await Promise.all([
        api.get<Professor>(`/api/professors/${authStore.user.user_id}`),
        api.get<Slot[]>(`/api/professors/me/schedule?week_anchor=${weekAnchor}`),
      ]);
      professor = prof;
      slots = sl;
    } catch (e) {
      console.error(e);
    } finally {
      loading = false;
    }
  }

  $effect(() => {
    if (authStore.user?.role === 'professor') {
      loadSchedule();
    }
  });

  $effect(() => {
    // eslint-disable-next-line @typescript-eslint/no-unused-expressions
    weekAnchor;
    if (authStore.user?.role === 'professor') {
      loadSchedule();
    }
  });

  function prevWeek() {
    const d = new Date(weekAnchor + 'T00:00:00');
    d.setDate(d.getDate() - 7);
    weekAnchor = d.toISOString().slice(0, 10);
  }

  function nextWeek() {
    const d = new Date(weekAnchor + 'T00:00:00');
    d.setDate(d.getDate() + 7);
    weekAnchor = d.toISOString().slice(0, 10);
  }
</script>

<div class="app-container">
  <header class="app-header">
    <span class="cal-icon">📅</span>
    <span class="app-title">Welcome, {professor?.name ?? authStore.user?.name ?? 'Prof.'}</span>
    <button class="icon-btn" onclick={() => showDrawer = true} id="btn-profile" aria-label="Profile">⊙</button>
  </header>

  <div class="week-nav-wrap">
    <WeekNavigator {weekAnchor} onPrev={prevWeek} onNext={nextWeek} />
  </div>

  {#if loading}
    <div class="loading">Loading schedule…</div>
  {:else}
    <div style="padding: 0 8px;">
      <CalendarGrid {slots} mode="professor" />
    </div>
  {/if}

  <BottomBar activeTab="schedule" />
</div>

{#if showDrawer && professor}
  <ProfileDrawer {professor} onClose={() => showDrawer = false} />
{/if}

<style>
  .cal-icon {
    font-size: 20px;
  }

  .week-nav-wrap {
    padding: 4px 12px 8px;
  }

  .loading {
    text-align: center;
    padding: 40px;
    color: #aaa;
    font-size: 15px;
  }
</style>
