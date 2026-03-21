use axum::{
    extract::{Path, State},
    Json,
};
use sqlx::{Row, SqlitePool};

use crate::{
    auth::StudentAuth,
    errors::AppError,
    models::{Booking, BookingWithDetails, CreateBookingRequest},
};

fn row_to_booking(r: &sqlx::sqlite::SqliteRow) -> Booking {
    Booking {
        id: r.get("id"),
        slot_id: r.get("slot_id"),
        student_id: r.get("student_id"),
        topic: r.get("topic"),
        booked_at: r.get("booked_at"),
    }
}

pub async fn create_booking(
    State(pool): State<SqlitePool>,
    StudentAuth(claims): StudentAuth,
    Json(req): Json<CreateBookingRequest>,
) -> Result<Json<Booking>, AppError> {
    // Check slot exists and has availability
    let slot_row = sqlx::query("SELECT id, available_slots FROM slots WHERE id = ?")
        .bind(req.slot_id)
        .fetch_one(&pool)
        .await
        .map_err(|_| AppError::NotFound("Slot not found".to_string()))?;

    let available_slots: i64 = slot_row.get("available_slots");
    if available_slots <= 0 {
        return Err(AppError::BadRequest("No available slots".to_string()));
    }

    // Check if student already booked this slot
    let existing = sqlx::query(
        "SELECT id FROM bookings WHERE slot_id = ? AND student_id = ?"
    )
    .bind(req.slot_id)
    .bind(claims.sub)
    .fetch_optional(&pool)
    .await?;

    if existing.is_some() {
        return Err(AppError::BadRequest("You already have a booking for this slot".to_string()));
    }

    // Create booking
    let result = sqlx::query(
        "INSERT INTO bookings (slot_id, student_id, topic, booked_at) VALUES (?, ?, ?, datetime('now'))"
    )
    .bind(req.slot_id)
    .bind(claims.sub)
    .bind(&req.topic)
    .execute(&pool)
    .await?;

    // Decrement available_slots
    sqlx::query("UPDATE slots SET available_slots = available_slots - 1 WHERE id = ?")
        .bind(req.slot_id)
        .execute(&pool)
        .await?;

    let booking_row = sqlx::query(
        "SELECT id, slot_id, student_id, topic, booked_at FROM bookings WHERE id = ?"
    )
    .bind(result.last_insert_rowid())
    .fetch_one(&pool)
    .await?;

    Ok(Json(row_to_booking(&booking_row)))
}

pub async fn cancel_booking(
    State(pool): State<SqlitePool>,
    StudentAuth(claims): StudentAuth,
    Path(id): Path<i64>,
) -> Result<Json<serde_json::Value>, AppError> {
    let booking_row = sqlx::query("SELECT id, slot_id, student_id FROM bookings WHERE id = ?")
        .bind(id)
        .fetch_one(&pool)
        .await?;

    let student_id: i64 = booking_row.get("student_id");
    let slot_id: i64 = booking_row.get("slot_id");

    if student_id != claims.sub {
        return Err(AppError::Forbidden("Not your booking".to_string()));
    }

    // Restore slot availability
    sqlx::query("UPDATE slots SET available_slots = available_slots + 1 WHERE id = ?")
        .bind(slot_id)
        .execute(&pool)
        .await?;

    sqlx::query("DELETE FROM bookings WHERE id = ?")
        .bind(id)
        .execute(&pool)
        .await?;

    Ok(Json(serde_json::json!({ "cancelled": true })))
}

pub async fn get_my_bookings(
    State(pool): State<SqlitePool>,
    StudentAuth(claims): StudentAuth,
) -> Result<Json<Vec<BookingWithDetails>>, AppError> {
    let rows = sqlx::query(
        r#"SELECT
            b.id, b.slot_id, b.student_id, b.topic, b.booked_at,
            s.professor_id, p.name as professor_name, p.department as professor_department,
            s.day_of_week, s.start_time, s.end_time, s.week_anchor
           FROM bookings b
           JOIN slots s ON b.slot_id = s.id
           JOIN professors p ON s.professor_id = p.id
           WHERE b.student_id = ?
           ORDER BY s.week_anchor, s.day_of_week, s.start_time"#
    )
    .bind(claims.sub)
    .fetch_all(&pool)
    .await?;

    let bookings = rows.iter().map(|r| BookingWithDetails {
        id: r.get("id"),
        slot_id: r.get("slot_id"),
        student_id: r.get("student_id"),
        topic: r.get("topic"),
        booked_at: r.get("booked_at"),
        professor_id: r.get("professor_id"),
        professor_name: r.get("professor_name"),
        professor_department: r.get("professor_department"),
        day_of_week: r.get("day_of_week"),
        start_time: r.get("start_time"),
        end_time: r.get("end_time"),
        week_anchor: r.get("week_anchor"),
    }).collect();

    Ok(Json(bookings))
}
