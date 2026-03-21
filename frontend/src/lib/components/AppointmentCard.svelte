<script lang="ts">
  import type { BookingWithDetails } from '$lib/types';
  import { api } from '$lib/api';

  interface Props {
    booking: BookingWithDetails;
    onCancelled: () => void;
    onView?: () => void;
  }

  let { booking, onCancelled, onView }: Props = $props();

  let loading = $state(false);

  const DAY_NAMES = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  const MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  let dateLabel = $derived(() => {
    const mon = new Date(booking.week_anchor + 'T00:00:00');
    const date = new Date(mon);
    date.setDate(mon.getDate() + booking.day_of_week);
    return `${MONTH_NAMES[date.getMonth()]} ${date.getDate()}`;
  });

  let initial = $derived(() => booking.professor_name.charAt(0));

  async function cancel() {
    loading = true;
    try {
      await api.delete(`/api/bookings/${booking.id}`);
      onCancelled();
    } finally {
      loading = false;
    }
  }
</script>

<div class="card">
  <div class="card-header">
    <div class="avatar">{initial()}</div>
    <div class="prof-info">
      <div class="prof-name">{booking.professor_name}</div>
      <div class="prof-dept">{booking.professor_department}</div>
    </div>
  </div>

  <div class="card-body">
    <div class="meta-line">Date: {dateLabel()}</div>
    <div class="meta-line">Time: {booking.start_time}–{booking.end_time}</div>
    <div class="meta-line">Topic: {booking.topic}</div>
  </div>

  <div class="card-actions">
    <button class="btn-view" onclick={onView}>View</button>
    <button class="btn-cancel" onclick={cancel} disabled={loading}>
      {loading ? '...' : 'Cancel'}
    </button>
  </div>
</div>

<style>
  .card {
    background: white;
    border-radius: 16px;
    padding: 20px;
    box-shadow: 0 2px 12px rgba(0,0,0,0.07);
    margin-bottom: 12px;
  }

  .card-header {
    display: flex;
    align-items: center;
    gap: 14px;
    margin-bottom: 14px;
  }

  .avatar {
    width: 42px;
    height: 42px;
    border-radius: 50%;
    background: #E8E0FF;
    color: #6B4EFF;
    font-size: 18px;
    font-weight: 700;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
  }

  .prof-name {
    font-weight: 700;
    font-size: 15px;
    color: #1a1a2e;
  }

  .prof-dept {
    font-size: 13px;
    color: #777;
  }

  .card-body {
    margin-bottom: 16px;
  }

  .meta-line {
    font-size: 13px;
    color: #444;
    line-height: 1.7;
  }

  .card-actions {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
  }

  .btn-view {
    background: white;
    border: 1.5px solid #6B4EFF;
    color: #6B4EFF;
    border-radius: 20px;
    padding: 6px 20px;
    font-size: 14px;
    cursor: pointer;
    font-family: inherit;
    font-weight: 500;
    transition: background 0.15s;
  }

  .btn-view:hover {
    background: #f0eeff;
  }

  .btn-cancel {
    background: #6B4EFF;
    border: none;
    color: white;
    border-radius: 20px;
    padding: 6px 20px;
    font-size: 14px;
    cursor: pointer;
    font-family: inherit;
    font-weight: 500;
    transition: opacity 0.15s;
  }

  .btn-cancel:disabled {
    opacity: 0.6;
  }

  .btn-cancel:hover:not(:disabled) {
    opacity: 0.85;
  }
</style>
