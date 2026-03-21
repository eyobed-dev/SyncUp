<script lang="ts">
  import type { Slot } from '$lib/types';
  import { api } from '$lib/api';

  interface Props {
    slot: Slot;
    professorId: number;
    onClose: () => void;
    onBooked: () => void;
  }

  let { slot, professorId, onClose, onBooked }: Props = $props();

  let name = $state('');
  let surname = $state('');
  let topic = $state('');
  let errors = $state<Record<string, string>>({});
  let loading = $state(false);
  let serverError = $state('');

  function validate(): boolean {
    const errs: Record<string, string> = {};
    if (!name.trim()) errs.name = 'Name is required';
    if (!surname.trim()) errs.surname = 'Surname is required';
    if (!topic.trim()) errs.topic = 'Meeting topic is required';
    errors = errs;
    return Object.keys(errs).length === 0;
  }

  async function handleBook() {
    if (!validate()) return;
    loading = true;
    serverError = '';
    try {
      await api.post('/api/bookings', {
        slot_id: slot.id,
        topic: topic.trim(),
      });
      onBooked();
    } catch (e: any) {
      serverError = e.message || 'Booking failed';
    } finally {
      loading = false;
    }
  }
</script>

<div class="panel">
  <h2 class="panel-title">Booking Page</h2>
  <p class="panel-subtitle">Please fill the required fields</p>

  {#if serverError}
    <div class="server-error">{serverError}</div>
  {/if}

  <div class="field">
    <label for="bp-name">Name:</label>
    <input id="bp-name" type="text" bind:value={name} placeholder="" />
    {#if errors.name}<span class="err">{errors.name}</span>{/if}
  </div>

  <div class="field">
    <label for="bp-surname">Surname:</label>
    <input id="bp-surname" type="text" bind:value={surname} placeholder="" />
    {#if errors.surname}<span class="err">{errors.surname}</span>{/if}
  </div>

  <div class="field">
    <label for="bp-topic">Meeting Topic:</label>
    <input id="bp-topic" type="text" bind:value={topic} placeholder="" />
    {#if errors.topic}<span class="err">{errors.topic}</span>{/if}
  </div>

  <div class="actions">
    <button class="btn-book" onclick={handleBook} disabled={loading}>
      {loading ? 'Booking...' : 'Book'}
    </button>
    <button class="btn-cancel" onclick={onClose}>Cancel</button>
  </div>
</div>

<style>
  .panel {
    background: #F0EEFF;
    border-radius: 16px;
    padding: 28px 24px;
    min-width: 280px;
  }

  .panel-title {
    font-size: 22px;
    font-weight: 600;
    color: #1a1a2e;
    margin: 0 0 6px;
  }

  .panel-subtitle {
    font-size: 13px;
    color: #777;
    margin: 0 0 24px;
  }

  .field {
    margin-bottom: 20px;
  }

  label {
    display: block;
    font-size: 14px;
    color: #333;
    margin-bottom: 4px;
    font-weight: 500;
  }

  input {
    width: 100%;
    border: none;
    border-bottom: 1.5px solid #ccc;
    background: transparent;
    font-size: 15px;
    padding: 6px 0;
    outline: none;
    font-family: inherit;
    transition: border-color 0.2s;
    box-sizing: border-box;
  }

  input:focus {
    border-bottom-color: #6B4EFF;
  }

  .err {
    font-size: 11px;
    color: #e53935;
    margin-top: 2px;
    display: block;
  }

  .actions {
    display: flex;
    justify-content: flex-end;
    gap: 24px;
    margin-top: 28px;
  }

  .btn-book {
    background: none;
    border: none;
    color: #6B4EFF;
    font-weight: 600;
    font-size: 16px;
    cursor: pointer;
    font-family: inherit;
    transition: opacity 0.2s;
  }

  .btn-book:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-cancel {
    background: none;
    border: none;
    color: #999;
    font-size: 16px;
    cursor: pointer;
    font-family: inherit;
    transition: opacity 0.2s;
  }

  .btn-cancel:hover {
    opacity: 0.7;
  }

  .server-error {
    background: #ffeaea;
    color: #c62828;
    border-radius: 8px;
    padding: 8px 12px;
    font-size: 13px;
    margin-bottom: 16px;
  }
</style>
