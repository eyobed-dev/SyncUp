use serde::{Deserialize, Serialize};
use sqlx::FromRow;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Professor {
    pub id: i64,
    pub name: String,
    pub department: String,
    pub role: String,
    pub phone: Option<String>,
    pub email: String,
    pub office: Option<String>,
    pub personal_id: Option<String>,
    #[serde(skip_serializing)]
    pub password_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ProfessorPublic {
    pub id: i64,
    pub name: String,
    pub department: String,
    pub role: String,
    pub phone: Option<String>,
    pub email: String,
    pub office: Option<String>,
    pub personal_id: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Student {
    pub id: i64,
    pub name: String,
    pub surname: String,
    pub email: String,
    #[serde(skip_serializing)]
    pub password_hash: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Slot {
    pub id: i64,
    pub professor_id: i64,
    pub day_of_week: i64,
    pub start_time: String,
    pub end_time: String,
    pub total_slots: i64,
    pub available_slots: i64,
    pub week_anchor: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct Booking {
    pub id: i64,
    pub slot_id: i64,
    pub student_id: i64,
    pub topic: String,
    pub booked_at: String,
}

// Extended booking with joined info
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct BookingWithDetails {
    pub id: i64,
    pub slot_id: i64,
    pub student_id: i64,
    pub topic: String,
    pub booked_at: String,
    pub professor_id: i64,
    pub professor_name: String,
    pub professor_department: String,
    pub day_of_week: i64,
    pub start_time: String,
    pub end_time: String,
    pub week_anchor: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct RecurringSlot {
    pub id: i64,
    pub professor_id: i64,
    pub day_of_week: i64,
    pub start_time: String,
    pub end_time: String,
}

// Request DTOs
#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
    pub role: String, // "professor" or "student"
}

#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub token: String,
    pub role: String,
    pub user_id: i64,
    pub name: String,
}

#[derive(Debug, Deserialize)]
pub struct CreateSlotRequest {
    pub day_of_week: i64,
    pub start_time: String,
    pub end_time: String,
    pub total_slots: i64,
    pub week_anchor: String,
}

#[derive(Debug, Deserialize)]
pub struct CreateBookingRequest {
    pub slot_id: i64,
    pub topic: String,
}

#[derive(Debug, Deserialize)]
pub struct SearchQuery {
    pub q: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct WeekQuery {
    pub week_anchor: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct SetAvailabilityEntry {
    pub day_of_week: i64,
    pub start_time: String,
    pub end_time: String,
}
