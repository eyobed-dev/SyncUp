<script lang="ts">
  import { goto } from '$app/navigation';
  import { authStore } from '$lib/stores.svelte';
  import { api } from '$lib/api';
  import type { BookingWithDetails, Professor } from '$lib/types';
  import SearchBar from '$lib/components/SearchBar.svelte';
  import AppointmentCard from '$lib/components/AppointmentCard.svelte';
  import StudentDrawer from '$lib/components/StudentDrawer.svelte';

  $effect(() => {
    if (!authStore.user) goto('/');
    else if (authStore.user.role !== 'student') goto('/professor');
  });

  let bookings = $state<BookingWithDetails[]>([]);
  let showDrawer = $state(false);

  async function loadBookings() {
    try {
      bookings = await api.get<BookingWithDetails[]>('/api/students/me/bookings');
    } catch {
      bookings = [];
    }
  }

  $effect(() => {
    if (authStore.user?.role === 'student') {
      loadBookings();
    }
  });

  function handleSelectProfessor(prof: Professor) {
    goto(`/student/professor/${prof.id}`);
  }

  function handleView(booking: BookingWithDetails) {
    goto(`/student/professor/${booking.professor_id}`);
  }
</script>

<div class="app-container">
  <header class="app-header">
    <h1 class="app-title">Find a Professor</h1>
    <button class="icon-btn" onclick={() => showDrawer = true} aria-label="Profile">⊙</button>
  </header>

  {#if showDrawer}
    <StudentDrawer onClose={() => showDrawer = false} />
  {/if}

  <div class="search-section">
    <SearchBar onSelect={handleSelectProfessor} />
  </div>

  <section class="appointments-section">
    <h2 class="section-title">My Appointments</h2>

    {#if bookings.length === 0}
      <div class="empty-state">
        <p>No appointments yet.</p>
        <p>Search for a professor and book a slot!</p>
      </div>
    {:else}
      {#each bookings as booking (booking.id)}
        <AppointmentCard
          {booking}
          onCancelled={loadBookings}
          onView={() => handleView(booking)}
        />
      {/each}
    {/if}
  </section>
</div>

<style>
  .search-section {
    padding: 0 20px 16px;
  }

  .appointments-section {
    padding: 0 20px;
  }

  .section-title {
    font-size: 22px;
    font-weight: 600;
    color: #1a1a2e;
    text-align: center;
    margin-bottom: 16px;
  }

  .empty-state {
    text-align: center;
    padding: 40px 20px;
    color: #aaa;
    font-size: 15px;
    line-height: 1.8;
  }
</style>
