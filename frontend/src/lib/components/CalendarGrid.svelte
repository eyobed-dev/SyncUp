<script lang="ts">
  import type { Slot } from '$lib/types';
  import SlotTile from './SlotTile.svelte';

  interface Props {
    slots: Slot[];
    mode: 'student' | 'professor';
    onSlotClick?: (slot: Slot) => void;
  }

  let { slots, mode, onSlotClick }: Props = $props();

  const DAYS = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
  const HOURS = [9, 10, 11, 12, 13, 14, 15, 16, 17];

  // Create lookup: day_of_week -> hour -> slot
  let slotMap = $derived.by(() => {
    const map = new Map<string, Slot>();
    for (const s of slots) {
      const hour = parseInt(s.start_time.split(':')[0]);
      map.set(`${s.day_of_week}_${hour}`, s);
    }
    return map;
  });

  function hourLabel(h: number): string {
    if (h < 12) return `${h} AM`;
    if (h === 12) return '12 PM';
    return `${h - 12 > 0 ? h - 12 : h} PM`;
  }
</script>

<div class="calendar-grid">
  <!-- Day headers -->
  <div class="grid-header">
    <div class="time-col"></div>
    {#each DAYS as day}
      <div class="day-header">{day}</div>
    {/each}
  </div>

  <!-- Hour rows -->
  {#each HOURS as hour}
    <div class="grid-row">
      <div class="time-label">{hourLabel(hour)}</div>
      {#each DAYS as _, dayIndex}
        <div class="tile-cell">
          <SlotTile
            slot={slotMap.get(`${dayIndex}_${hour}`)}
            {hour}
            dayOfWeek={dayIndex}
            {mode}
            onclick={onSlotClick}
          />
        </div>
      {/each}
    </div>
  {/each}
</div>

<style>
  .calendar-grid {
    width: 100%;
    overflow-x: auto;
  }

  .grid-header {
    display: grid;
    grid-template-columns: 52px repeat(5, 1fr);
    gap: 6px;
    margin-bottom: 4px;
    padding: 0 4px;
  }

  .time-col {
    /* empty */
  }

  .day-header {
    text-align: center;
    font-size: 12px;
    font-weight: 600;
    color: #999;
    letter-spacing: 0.5px;
  }

  .grid-row {
    display: grid;
    grid-template-columns: 52px repeat(5, 1fr);
    gap: 6px;
    margin-bottom: 6px;
    align-items: center;
    padding: 0 4px;
  }

  .time-label {
    font-size: 11px;
    color: #888;
    text-align: right;
    padding-right: 6px;
    font-weight: 500;
    white-space: nowrap;
  }

  .tile-cell {
    min-width: 48px;
  }
</style>
