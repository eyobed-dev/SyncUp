<script lang="ts">
  import { goto } from '$app/navigation';
  import { authStore } from '$lib/stores.svelte';
  import { api } from '$lib/api';
  import type { Slot } from '$lib/types';
  import CalendarGrid from '$lib/components/CalendarGrid.svelte';
  import WeekNavigator from '$lib/components/WeekNavigator.svelte';
  import BottomBar from '$lib/components/BottomBar.svelte';

  $effect(() => {
    if (!authStore.user) goto('/');
    else if (authStore.user.role !== 'professor') goto('/student');
  });

  const DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  interface SlotRow {
    day: number;
    from: string;
    to: string;
    count: number;
  }

  let rows = $state<SlotRow[]>(
    DAYS.map((_, i) => ({ day: i, from: '13:00', to: '14:00', count: 1 }))
  );

  let slots = $state<Slot[]>([]);
  let weekAnchor = $state(currentMondayAnchor());
  let saving = $state(false);
  let saveError = $state('');
  let saveSuccess = $state(false);

  function currentMondayAnchor(): string {
    const now = new Date();
    const dow = now.getDay();
    const diff = (dow === 0 ? -6 : 1 - dow);
    const mon = new Date(now);
    mon.setDate(now.getDate() + diff);
    return mon.toISOString().slice(0, 10);
  }

  async function loadSlots() {
    try {
      slots = await api.get<Slot[]>(`/api/professors/me/schedule?week_anchor=${weekAnchor}`);
    } catch {
      slots = [];
    }
  }

  $effect(() => {
    if (authStore.user?.role === 'professor') {
      loadSlots();
    }
  });

  $effect(() => {
    // eslint-disable-next-line @typescript-eslint/no-unused-expressions
    weekAnchor;
    if (authStore.user?.role === 'professor') {
      loadSlots();
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

  async function handleAdd() {
    if (!authStore.user) return;
    saving = true;
    saveError = '';
    saveSuccess = false;

    const payload = rows
      .filter(r => r.from && r.to && r.count >= 1)
      .map(r => ({
        day_of_week: r.day,
        start_time: r.from,
        end_time: r.to,
        total_slots: r.count,
        week_anchor: weekAnchor,
      }));

    if (payload.length === 0) {
      saveError = 'At least one row must be filled.';
      saving = false;
      return;
    }

    try {
      await api.post(`/api/professors/${authStore.user.user_id}/slots`, payload);
      await loadSlots();
      saveSuccess = true;
    } catch (e: any) {
      saveError = e.message || 'Failed to save slots';
    } finally {
      saving = false;
    }
  }
</script>

<div class="app-container">
  <header class="app-header">
    <button class="icon-btn" onclick={() => goto('/professor')} aria-label="Back">←</button>
    <h1 class="app-title">Add Available Slots</h1>
    <div></div>
  </header>

  <div class="form-card">
    <div class="table-header">
      <span class="col-day">Day</span>
      <span class="col-time">From</span>
      <span class="dash">–</span>
      <span class="col-time">To</span>
      <span class="col-count">Number of Slots</span>
    </div>

    {#each rows as row, i}
      <div class="table-row">
        <span class="col-day day-label">{DAYS[i]}</span>
        <input class="time-pill col-time" type="time" bind:value={row.from} id="from-{i}" />
        <span class="dash">–</span>
        <input class="time-pill col-time" type="time" bind:value={row.to} id="to-{i}" />
        <input class="count-pill col-count" type="number" min="1" max="20" bind:value={row.count} id="count-{i}" />
      </div>
    {/each}

    {#if saveError}
      <div class="save-error">{saveError}</div>
    {/if}
    {#if saveSuccess}
      <div class="save-success">Slots added successfully!</div>
    {/if}

    <div class="add-row">
      <button class="add-btn" onclick={handleAdd} disabled={saving} id="btn-add-slots">
        {saving ? 'Saving…' : 'Add'}
        <span class="plus-circle">⊕</span>
      </button>
    </div>
  </div>

  <div class="calendar-section">
    <div class="week-nav-row">
      <WeekNavigator {weekAnchor} onPrev={prevWeek} onNext={nextWeek} />
    </div>
    <div style="padding: 0 8px;">
      <CalendarGrid {slots} mode="student" />
    </div>
  </div>

  <BottomBar activeTab="add-slots" />
</div>

<style>
  .form-card {
    margin: 8px 16px 16px;
    background: white;
    border-radius: 16px;
    padding: 16px;
    box-shadow: 0 2px 12px rgba(0,0,0,0.06);
  }

  .table-header,
  .table-row {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 12px;
  }

  .table-header {
    font-size: 12px;
    font-weight: 600;
    color: #888;
    text-transform: uppercase;
    letter-spacing: 0.3px;
    margin-bottom: 8px;
  }

  .col-day { flex: 1.2; min-width: 80px; }
  .col-time { flex: 1; }
  .col-count { flex: 0.8; min-width: 60px; }
  .dash { flex-shrink: 0; color: #bbb; font-size: 13px; }

  .day-label { font-size: 14px; color: #333; }

  .time-pill,
  .count-pill {
    border: 1.5px solid #e0e0e0;
    border-radius: 20px;
    padding: 7px 12px;
    font-size: 13px;
    font-family: inherit;
    text-align: center;
    outline: none;
    width: 100%;
    transition: border-color 0.2s;
  }

  .time-pill:focus,
  .count-pill:focus {
    border-color: #6B4EFF;
  }

  .add-row {
    display: flex;
    justify-content: flex-end;
    margin-top: 8px;
  }

  .add-btn {
    background: none;
    border: none;
    color: #333;
    font-size: 15px;
    font-weight: 500;
    cursor: pointer;
    font-family: inherit;
    display: flex;
    align-items: center;
    gap: 6px;
    transition: color 0.2s;
  }

  .add-btn:hover:not(:disabled) { color: #6B4EFF; }
  .add-btn:disabled { opacity: 0.5; cursor: not-allowed; }

  .plus-circle { font-size: 20px; color: #6B4EFF; }

  .save-error { color: #c62828; font-size: 13px; margin-top: 4px; }
  .save-success { color: #2e7d32; font-size: 13px; margin-top: 4px; }

  .calendar-section { padding: 0 8px; }

  .week-nav-row {
    display: flex;
    align-items: center;
    justify-content: center;
    padding-bottom: 8px;
  }
</style>
