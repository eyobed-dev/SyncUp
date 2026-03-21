<script lang="ts">
  import type { Professor } from '$lib/types';
  import { api } from '$lib/api';

  interface Props {
    onSelect: (prof: Professor) => void;
  }

  let { onSelect }: Props = $props();

  let query = $state('');
  let results = $state<Professor[]>([]);
  let open = $state(false);
  let debounceTimer: ReturnType<typeof setTimeout>;

  $effect(() => {
    clearTimeout(debounceTimer);
    if (query.trim().length < 1) {
      results = [];
      open = false;
      return;
    }
    debounceTimer = setTimeout(async () => {
      try {
        results = await api.get<Professor[]>(`/api/professors?q=${encodeURIComponent(query)}`);
        open = results.length > 0;
      } catch {
        results = [];
        open = false;
      }
    }, 250);
  });

  function selectProfessor(prof: Professor) {
    query = '';
    open = false;
    results = [];
    onSelect(prof);
  }

  function clearQuery() {
    query = '';
    open = false;
    results = [];
  }
</script>

<div class="search-wrapper">
  <div class="search-box" class:focused={open}>
    <span class="search-icon">🔍</span>
    <input
      id="search-professors"
      type="text"
      bind:value={query}
      placeholder="Search by department, name…"
      autocomplete="off"
    />
    {#if query}
      <button class="clear-btn" onclick={clearQuery} aria-label="Clear search">✕</button>
    {/if}
  </div>

  {#if open}
    <div class="dropdown">
      {#each results as prof}
        <button class="menu-item" onclick={() => selectProfessor(prof)}>
          <span class="item-name">{prof.name}</span>
          <span class="item-dept">{prof.department}</span>
        </button>
      {/each}
    </div>
  {/if}
</div>

<style>
  .search-wrapper {
    position: relative;
    width: 100%;
  }

  .search-box {
    display: flex;
    align-items: center;
    border: 1.5px solid #6B4EFF;
    border-radius: 10px;
    padding: 10px 12px;
    background: white;
    gap: 8px;
    transition: box-shadow 0.2s;
  }

  .search-box.focused {
    box-shadow: 0 2px 12px rgba(107,78,255,0.15);
  }

  .search-icon {
    font-size: 16px;
    flex-shrink: 0;
  }

  input {
    flex: 1;
    border: none;
    outline: none;
    font-size: 15px;
    font-family: inherit;
    color: #333;
    background: transparent;
  }

  input::placeholder {
    color: #bbb;
  }

  .clear-btn {
    background: none;
    border: none;
    color: #999;
    cursor: pointer;
    font-size: 14px;
    padding: 2px;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    transition: background 0.15s;
  }

  .clear-btn:hover {
    background: #eee;
  }

  .dropdown {
    position: absolute;
    top: calc(100% + 4px);
    left: 0;
    right: 0;
    background: white;
    border-radius: 10px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.12);
    z-index: 50;
    overflow: hidden;
  }

  .menu-item {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    padding: 14px 16px;
    border: none;
    background: none;
    cursor: pointer;
    width: 100%;
    text-align: left;
    font-family: inherit;
    border-bottom: 1px solid #f0f0f0;
    transition: background 0.15s;
  }

  .menu-item:last-child {
    border-bottom: none;
  }

  .menu-item:hover {
    background: #f8f5ff;
  }

  .item-name {
    font-size: 14px;
    font-weight: 500;
    color: #1a1a2e;
  }

  .item-dept {
    font-size: 12px;
    color: #888;
    margin-top: 2px;
  }
</style>
