<script lang="ts">
  import { goto } from '$app/navigation';

  interface Props {
    activeTab?: 'schedule' | 'add-slots';
  }

  let { activeTab = 'schedule' }: Props = $props();

  function goSchedule() {
    goto('/professor');
  }

  function goAddSlots() {
    goto('/professor/add-slots');
  }
</script>

<div class="bottom-bar">
  <button
    class="tab-btn"
    class:active={activeTab === 'schedule'}
    onclick={goSchedule}
    id="nav-schedule"
  >
    <span class="tab-icon">⊙</span>
    <span class="tab-label">Schedule</span>
  </button>

  <button
    class="add-slot-btn"
    onclick={goAddSlots}
    id="nav-add-slot"
  >
    <span class="add-label">Add New Slot</span>
    <span class="plus-icon">+</span>
  </button>
</div>

<style>
  .bottom-bar {
    position: fixed;
    bottom: 0;
    left: 50%;
    transform: translateX(-50%);
    width: 100%;
    max-width: 480px;
    background: white;
    border-top: 1px solid #eee;
    padding: 12px 24px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    box-shadow: 0 -4px 20px rgba(0,0,0,0.06);
    z-index: 100;
  }

  .tab-btn {
    background: none;
    border: none;
    display: flex;
    align-items: center;
    gap: 6px;
    cursor: pointer;
    color: #999;
    font-family: inherit;
    font-size: 14px;
    padding: 4px;
    transition: color 0.15s;
  }

  .tab-btn.active {
    color: #6B4EFF;
  }

  .tab-icon {
    font-size: 18px;
  }

  .add-slot-btn {
    background: #6B4EFF;
    border: none;
    color: white;
    border-radius: 20px;
    padding: 8px 18px;
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 14px;
    font-weight: 600;
    cursor: pointer;
    font-family: inherit;
    transition: opacity 0.15s, transform 0.15s;
  }

  .add-slot-btn:hover {
    opacity: 0.9;
    transform: scale(1.03);
  }

  .plus-icon {
    font-size: 20px;
    line-height: 1;
    font-weight: 300;
  }
</style>
