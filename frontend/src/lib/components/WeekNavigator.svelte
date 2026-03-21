<script lang="ts">
  interface Props {
    weekAnchor: string; // "YYYY-MM-DD" Monday of the current week
    onPrev: () => void;
    onNext: () => void;
  }

  let { weekAnchor, onPrev, onNext }: Props = $props();

  let label = $derived(() => {
    const monday = new Date(weekAnchor + 'T00:00:00');
    const friday = new Date(monday);
    friday.setDate(monday.getDate() + 4);

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    const monStr = `${monday.getDate().toString().padStart(2, '0')}`;
    const friStr = `${friday.getDate().toString().padStart(2, '0')}`;
    const month = months[friday.getMonth()];
    const year = friday.getFullYear();

    return `${monStr}–${friStr} ${month} ${year}`;
  });
</script>

<div class="week-nav">
  <button class="nav-btn" onclick={onPrev} aria-label="Previous week">&#8249;</button>
  <span class="week-label">{label()}</span>
  <button class="nav-btn" onclick={onNext} aria-label="Next week">&#8250;</button>
</div>

<style>
  .week-nav {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 16px;
    padding: 8px 0;
  }

  .nav-btn {
    background: none;
    border: none;
    font-size: 26px;
    color: #6B4EFF;
    cursor: pointer;
    padding: 0 8px;
    line-height: 1;
    border-radius: 50%;
    transition: background 0.15s;
  }

  .nav-btn:hover {
    background: rgba(107, 78, 255, 0.1);
  }

  .week-label {
    font-size: 15px;
    font-weight: 500;
    color: #333;
    min-width: 140px;
    text-align: center;
  }
</style>
