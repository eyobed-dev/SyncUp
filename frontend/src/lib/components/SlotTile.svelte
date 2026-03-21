<script lang="ts">
  import type { Slot } from '$lib/types';

  interface Props {
    slot: Slot | undefined;
    hour: number;
    dayOfWeek: number;
    mode: 'student' | 'professor';
    onclick?: (slot: Slot) => void;
  }

  let { slot, hour, dayOfWeek, mode, onclick }: Props = $props();

  let status = $derived.by(() => {
    if (!slot) return 'none' as const;
    if (mode === 'professor') return 'has_slot' as const;
    return slot.available_slots > 0 ? 'available' : 'booked' as const;
  });

  let clickable = $derived(mode === 'student' && !!slot && slot.available_slots > 0);

  function handleClick() {
    if (clickable && slot && onclick) onclick(slot);
  }
</script>

<button
  class="slot-tile {status}"
  class:clickable
  disabled={!clickable}
  onclick={handleClick}
  aria-label="{status} slot at {hour}:00"
>
  {#if slot && (status === 'booked' || (mode === 'professor'))}
    {#if status === 'booked'}
      <span class="star-icon">⊛</span>
      <span class="tile-label">Booked</span>
    {:else if mode === 'professor'}
      <!-- blue tile: professor view, just show empty blue -->
    {/if}
  {:else if slot && status === 'available'}
    <span class="tile-label">Available</span>
  {/if}
</button>

<style>
  .slot-tile {
    width: 100%;
    height: 52px;
    border-radius: 10px;
    border: none;
    cursor: default;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    font-size: 11px;
    font-weight: 600;
    color: white;
    transition: transform 0.1s ease, box-shadow 0.1s ease;
    background: #E8EAF0;
    color: #aaa;
  }

  .slot-tile.available {
    background: #4CAF50;
    color: white;
  }

  .slot-tile.booked {
    background: #9C8FD9;
    color: white;
  }

  .slot-tile.has_slot {
    background: #90CAF9;
    color: #1565C0;
  }

  .slot-tile.none {
    background: #E8EAF0;
    color: transparent;
  }

  .slot-tile.clickable {
    cursor: pointer;
  }

  .slot-tile.clickable:hover {
    transform: scale(1.05);
    box-shadow: 0 4px 16px rgba(76, 175, 80, 0.35);
  }

  .star-icon {
    font-size: 14px;
    line-height: 1;
  }

  .tile-label {
    font-size: 10px;
    margin-top: 1px;
  }
</style>
