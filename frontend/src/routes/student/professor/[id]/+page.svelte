<script lang="ts">
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { authStore } from '$lib/stores.svelte';
  import { api } from '$lib/api';
  import type { Professor, Slot, BookingWithDetails } from '$lib/types';
  import CalendarGrid from '$lib/components/CalendarGrid.svelte';
  import WeekNavigator from '$lib/components/WeekNavigator.svelte';
  import BookingPanel from '$lib/components/BookingPanel.svelte';

  $effect(() => {
    if (!authStore.user) goto('/');
    else if (authStore.user.role !== 'student') goto('/professor');
  });

  let professorId = $derived(parseInt($page.params.id));

  let professor = $state<Professor | null>(null);
  let slots = $state<Slot[]>([]);
  let myBookings = $state<BookingWithDetails[]>([]);
  let weekAnchor = $state(currentMondayAnchor());
  let selectedSlot = $state<Slot | null>(null);
  let loading = $state(false);

  function currentMondayAnchor(): string {
    const now = new Date();
    const dow = now.getDay();
    const diff = (dow === 0 ? -6 : 1 - dow);
    const mon = new Date(now);
    mon.setDate(now.getDate() + diff);
    return mon.toISOString().slice(0, 10);
  }

  async function loadData() {
    if (!authStore.user) return;
    loading = true;
    try {
      const [prof, sl, bk] = await Promise.all([
        api.get<Professor>(`/api/professors/${professorId}`),
        api.get<Slot[]>(`/api/professors/${professorId}/slots?week_anchor=${weekAnchor}`),
        api.get<BookingWithDetails[]>('/api/students/me/bookings'),
      ]);
      professor = prof;
      slots = sl;
      myBookings = bk;
    } catch (e) {
      console.error(e);
    } finally {
      loading = false;
    }
  }

  $effect(() => {
    if (authStore.user?.role === 'student' && professorId) {
      loadData();
    }
  });

  $effect(() => {
    // eslint-disable-next-line @typescript-eslint/no-unused-expressions
    weekAnchor;
    if (authStore.user?.role === 'student' && professorId) {
      loadData();
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

  function handleSlotClick(slot: Slot) {
    selectedSlot = slot;
  }

  function handleBooked() {
    selectedSlot = null;
    loadData();
  }

  let currentBooking = $derived(
    myBookings.find(b => b.professor_id === professorId && b.week_anchor === weekAnchor)
  );

  const MONTH_NAMES = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  function dateLabel(b: BookingWithDetails): string {
    const mon = new Date(b.week_anchor + 'T00:00:00');
    const d = new Date(mon);
    d.setDate(mon.getDate() + b.day_of_week);
    return `${MONTH_NAMES[d.getMonth()]} ${d.getDate()}`;
  }
</script>

<div class="app-container" style="max-width: 700px;">
  <header class="app-header">
    <h1 class="app-title">SyncUp</h1>
    <button class="icon-btn" onclick={() => goto('/student')} aria-label="Back">⊙</button>
  </header>

  {#if professor}
    <div class="prof-card">
      <div class="prof-avatar">{professor.name.charAt(0)}</div>
      <div>
        <div class="prof-name">{professor.name}</div>
        <div class="prof-dept">{professor.department}</div>
      </div>
    </div>

    {#if currentBooking}
      <div class="booking-summary">
        <div class="bs-row">Date: {dateLabel(currentBooking)}</div>
        <div class="bs-row">Time: {currentBooking.start_time}–{currentBooking.end_time}</div>
        <div class="bs-row">Topic: {currentBooking.topic}</div>
      </div>
    {/if}
  {/if}

  <div class="calendar-panel-wrap">
    <div class="calendar-col">
      <div class="week-header">
        <WeekNavigator {weekAnchor} onPrev={prevWeek} onNext={nextWeek} />
      </div>

      {#if loading}
        <div class="loading">Loading…</div>
      {:else}
        <CalendarGrid {slots} mode="student" onSlotClick={handleSlotClick} />
      {/if}
    </div>

    {#if selectedSlot}
      <div class="booking-col">
        <BookingPanel
          slot={selectedSlot}
          professorId={professorId}
          onClose={() => selectedSlot = null}
          onBooked={handleBooked}
        />
      </div>
    {/if}
  </div>
</div>

<style>
  .prof-card {
    margin: 0 20px 16px;
    background: white;
    border-radius: 16px;
    padding: 16px 20px;
    display: flex;
    align-items: center;
    gap: 14px;
    box-shadow: 0 2px 12px rgba(0,0,0,0.06);
  }

  .prof-avatar {
    width: 48px;
    height: 48px;
    border-radius: 50%;
    background: #E8E0FF;
    color: #6B4EFF;
    font-size: 20px;
    font-weight: 700;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .prof-name {
    font-weight: 700;
    font-size: 16px;
    color: #1a1a2e;
  }

  .prof-dept {
    font-size: 13px;
    color: #888;
  }

  .booking-summary {
    margin: 0 20px 16px;
    background: white;
    border-radius: 16px;
    padding: 14px 18px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.06);
    border-left: 4px solid #6B4EFF;
  }

  .bs-row {
    font-size: 14px;
    color: #555;
    line-height: 1.7;
  }

  .calendar-panel-wrap {
    display: flex;
    gap: 16px;
    padding: 0 12px;
  }

  .calendar-col {
    flex: 1;
    min-width: 0;
  }

  .booking-col {
    width: 260px;
    flex-shrink: 0;
  }

  .week-header {
    margin-bottom: 8px;
  }

  .loading {
    text-align: center;
    padding: 40px;
    color: #aaa;
  }
</style>
