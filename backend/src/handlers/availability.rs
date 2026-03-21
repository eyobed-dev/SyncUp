use axum::{extract::State, Json};
use sqlx::{Row, SqlitePool};

use crate::{
    auth::ProfessorAuth,
    errors::AppError,
    models::{RecurringSlot, SetAvailabilityEntry},
    utils,
};

pub async fn get_my_availability(
    State(pool): State<SqlitePool>,
    ProfessorAuth(claims): ProfessorAuth,
) -> Result<Json<Vec<RecurringSlot>>, AppError> {
    let rows = sqlx::query(
        "SELECT id, professor_id, day_of_week, start_time, end_time
         FROM recurring_availability
         WHERE professor_id = ?
         ORDER BY day_of_week, start_time",
    )
    .bind(claims.sub)
    .fetch_all(&pool)
    .await?;

    let slots = rows
        .iter()
        .map(|r| RecurringSlot {
            id: r.get("id"),
            professor_id: r.get("professor_id"),
            day_of_week: r.get("day_of_week"),
            start_time: r.get("start_time"),
            end_time: r.get("end_time"),
        })
        .collect();

    Ok(Json(slots))
}

/// Replace the professor's recurring availability and generate concrete slots
/// for the next 8 weeks. Slots that already have bookings are untouched.
pub async fn set_my_availability(
    State(pool): State<SqlitePool>,
    ProfessorAuth(claims): ProfessorAuth,
    Json(req): Json<Vec<SetAvailabilityEntry>>,
) -> Result<Json<serde_json::Value>, AppError> {
    for entry in &req {
        if !(0..=4).contains(&entry.day_of_week) {
            return Err(AppError::BadRequest(
                "day_of_week must be 0–4".to_string(),
            ));
        }
    }

    let mut tx = pool.begin().await?;

    // 1. Replace recurring availability
    sqlx::query("DELETE FROM recurring_availability WHERE professor_id = ?")
        .bind(claims.sub)
        .execute(&mut *tx)
        .await?;

    for entry in &req {
        sqlx::query(
            "INSERT INTO recurring_availability (professor_id, day_of_week, start_time, end_time)
             VALUES (?, ?, ?, ?)",
        )
        .bind(claims.sub)
        .bind(entry.day_of_week)
        .bind(&entry.start_time)
        .bind(&entry.end_time)
        .execute(&mut *tx)
        .await?;
    }

    // 2. Generate concrete slots for the next 8 weeks
    for week_anchor in utils::next_n_week_anchors(8) {
        for entry in &req {
            // Don't overwrite slots that already have bookings
            let existing = sqlx::query(
                "SELECT id FROM slots WHERE professor_id = ? AND week_anchor = ? AND day_of_week = ? AND start_time = ?",
            )
            .bind(claims.sub)
            .bind(&week_anchor)
            .bind(entry.day_of_week)
            .bind(&entry.start_time)
            .fetch_optional(&mut *tx)
            .await?;

            if existing.is_none() {
                sqlx::query(
                    "INSERT INTO slots (professor_id, day_of_week, start_time, end_time, total_slots, available_slots, week_anchor)
                     VALUES (?, ?, ?, ?, 1, 1, ?)",
                )
                .bind(claims.sub)
                .bind(entry.day_of_week)
                .bind(&entry.start_time)
                .bind(&entry.end_time)
                .bind(&week_anchor)
                .execute(&mut *tx)
                .await?;
            }
        }
    }

    tx.commit().await?;

    Ok(Json(serde_json::json!({ "success": true, "weeks_generated": 8 })))
}
