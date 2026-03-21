use axum::{
    extract::{Path, State},
    Json,
};
use sqlx::{Row, SqlitePool};

use crate::{
    auth::ProfessorAuth,
    errors::AppError,
    models::{CreateSlotRequest, Slot},
};

fn row_to_slot(r: &sqlx::sqlite::SqliteRow) -> Slot {
    Slot {
        id: r.get("id"),
        professor_id: r.get("professor_id"),
        day_of_week: r.get("day_of_week"),
        start_time: r.get("start_time"),
        end_time: r.get("end_time"),
        total_slots: r.get("total_slots"),
        available_slots: r.get("available_slots"),
        week_anchor: r.get("week_anchor"),
    }
}

pub async fn add_slots(
    State(pool): State<SqlitePool>,
    ProfessorAuth(claims): ProfessorAuth,
    Json(req): Json<Vec<CreateSlotRequest>>,
) -> Result<Json<Vec<Slot>>, AppError> {
    let mut inserted = Vec::new();

    for slot_req in &req {
        if slot_req.day_of_week < 0 || slot_req.day_of_week > 4 {
            return Err(AppError::BadRequest("day_of_week must be 0-4".to_string()));
        }
        if slot_req.total_slots < 1 {
            return Err(AppError::BadRequest("total_slots must be >= 1".to_string()));
        }

        let result = sqlx::query(
            "INSERT INTO slots (professor_id, day_of_week, start_time, end_time, total_slots, available_slots, week_anchor)
             VALUES (?, ?, ?, ?, ?, ?, ?)"
        )
        .bind(claims.sub)
        .bind(slot_req.day_of_week)
        .bind(&slot_req.start_time)
        .bind(&slot_req.end_time)
        .bind(slot_req.total_slots)
        .bind(slot_req.total_slots) // available = total initially
        .bind(&slot_req.week_anchor)
        .execute(&pool)
        .await?;

        let slot_row = sqlx::query(
            "SELECT id, professor_id, day_of_week, start_time, end_time, total_slots, available_slots, week_anchor
             FROM slots WHERE id = ?"
        )
        .bind(result.last_insert_rowid())
        .fetch_one(&pool)
        .await?;

        inserted.push(row_to_slot(&slot_row));
    }

    Ok(Json(inserted))
}

pub async fn delete_slot(
    State(pool): State<SqlitePool>,
    ProfessorAuth(claims): ProfessorAuth,
    Path(id): Path<i64>,
) -> Result<Json<serde_json::Value>, AppError> {
    let row = sqlx::query("SELECT professor_id FROM slots WHERE id = ?")
        .bind(id)
        .fetch_one(&pool)
        .await?;

    let professor_id: i64 = row.get("professor_id");
    if professor_id != claims.sub {
        return Err(AppError::Forbidden("Not your slot".to_string()));
    }

    sqlx::query("DELETE FROM bookings WHERE slot_id = ?")
        .bind(id)
        .execute(&pool)
        .await?;

    sqlx::query("DELETE FROM slots WHERE id = ?")
        .bind(id)
        .execute(&pool)
        .await?;

    Ok(Json(serde_json::json!({ "deleted": true })))
}
