<script lang="ts">
  let { children } = $props();
</script>

<svelte:head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>SyncUp — Professor Appointment Booking</title>
  <meta name="description" content="University professor appointment scheduling system" />
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="" />
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
</svelte:head>

{@render children()}

<style>
  :global(*) {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  :global(body) {
    font-family: 'DM Sans', system-ui, sans-serif;
    background: #F5F5F7;
    color: #1a1a2e;
    min-height: 100vh;
    display: flex;
    justify-content: center;
  }

  :global(#svelte) {
    width: 100%;
    display: flex;
    justify-content: center;
  }

  :global(.app-container) {
    width: 100%;
    max-width: 480px;
    min-height: 100vh;
    background: #F5F5F7;
    position: relative;
    padding-bottom: 72px;
  }

  :global(.app-header) {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 20px 20px 12px;
    background: #F5F5F7;
  }

  :global(.app-title) {
    font-size: 20px;
    font-weight: 600;
    color: #1a1a2e;
  }

  :global(.icon-btn) {
    background: none;
    border: none;
    cursor: pointer;
    font-size: 24px;
    padding: 4px;
    color: #333;
    border-radius: 50%;
    transition: background 0.15s;
  }

  :global(.icon-btn:hover) {
    background: rgba(0,0,0,0.06);
  }
</style>
