export interface Professor {
  id: number;
  name: string;
  department: string;
  role: string;
  phone?: string;
  email: string;
  office?: string;
  personal_id?: string;
}

export interface Slot {
  id: number;
  professor_id: number;
  day_of_week: number; // 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri
  start_time: string;  // "HH:MM"
  end_time: string;
  total_slots: number;
  available_slots: number;
  week_anchor: string; // "YYYY-MM-DD" (Monday of that week)
}

export interface Booking {
  id: number;
  slot_id: number;
  student_id: number;
  topic: string;
  booked_at: string;
}

export interface BookingWithDetails {
  id: number;
  slot_id: number;
  student_id: number;
  topic: string;
  booked_at: string;
  professor_id: number;
  professor_name: string;
  professor_department: string;
  day_of_week: number;
  start_time: string;
  end_time: string;
  week_anchor: string;
}

export interface AuthUser {
  token: string;
  role: 'professor' | 'student';
  user_id: number;
  name: string;
}

export interface LoginResponse {
  token: string;
  role: string;
  user_id: number;
  name: string;
}

/** Slot status as seen in student view */
export type SlotStatus = 'available' | 'booked' | 'none';

/** Slot status as seen in professor view */
export type ProfSlotStatus = 'has_slot' | 'none';
