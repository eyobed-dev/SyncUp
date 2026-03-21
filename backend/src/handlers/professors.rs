use axum::{
    extract::{Path, Query, State},
    Json,
};
use sqlx::{Row, SqlitePool};

use crate::{
    auth::ProfessorAuth,
    errors::AppError,
    models::{ProfessorPublic, SearchQuery, WeekQuery, Slot},
    utils,
};

pub async fn list_professors(
    State(pool): State<SqlitePool>,
    Query(params): Query<SearchQuery>,
) -> Result<Json<Vec<ProfessorPublic>>, AppError> {
    let rows = if let Some(q) = params.q.filter(|s| !s.is_empty()) {
        let pattern = format!("%{}%", q);
        sqlx::query(
            "SELECT id, name, department, role, phone, email, office, personal_id
             FROM professors WHERE name LIKE ? OR department LIKE ?"
        )
        .bind(&pattern)
        .bind(&pattern)
        .fetch_all(&pool)
        .await?
    } else {
        sqlx::query(
            "SELECT id, name, department, role, phone, email, office, personal_id FROM professors"
        )
        .fetch_all(&pool)
        .await?
    };

    let professors = rows.iter().map(|r| ProfessorPublic {
        id: r.get("id"),
        name: r.get("name"),
        department: r.get("department"),
        role: r.get("role"),
        phone: r.get("phone"),
        email: r.get("email"),
        office: r.get("office"),
        personal_id: r.get("personal_id"),
    }).collect();

    Ok(Json(professors))
}

pub async fn get_professor(
    State(pool): State<SqlitePool>,
    Path(id): Path<i64>,
) -> Result<Json<ProfessorPublic>, AppError> {
    let row = sqlx::query(
        "SELECT id, name, department, role, phone, email, office, personal_id FROM professors WHERE id = ?"
    )
    .bind(id)
    .fetch_one(&pool)
    .await?;

    Ok(Json(ProfessorPublic {
        id: row.get("id"),
        name: row.get("name"),
        department: row.get("department"),
        role: row.get("role"),
        phone: row.get("phone"),
        email: row.get("email"),
        office: row.get("office"),
        personal_id: row.get("personal_id"),
    }))
}

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

pub async fn get_professor_slots(
    State(pool): State<SqlitePool>,
    Path(id): Path<i64>,
    Query(params): Query<WeekQuery>,
) -> Result<Json<Vec<Slot>>, AppError> {
    let week_anchor = params.week_anchor.unwrap_or_else(utils::current_week_anchor);
    let rows = sqlx::query(
        "SELECT id, professor_id, day_of_week, start_time, end_time, total_slots, available_slots, week_anchor
         FROM slots WHERE professor_id = ? AND week_anchor = ?"
    )
    .bind(id)
    .bind(&week_anchor)
    .fetch_all(&pool)
    .await?;

    Ok(Json(rows.iter().map(row_to_slot).collect()))
}

pub async fn get_my_schedule(
    State(pool): State<SqlitePool>,
    ProfessorAuth(claims): ProfessorAuth,
    Query(params): Query<WeekQuery>,
) -> Result<Json<Vec<Slot>>, AppError> {
    let week_anchor = params.week_anchor.unwrap_or_else(utils::current_week_anchor);
    let rows = sqlx::query(
        "SELECT id, professor_id, day_of_week, start_time, end_time, total_slots, available_slots, week_anchor
         FROM slots WHERE professor_id = ? AND week_anchor = ?"
    )
    .bind(claims.sub)
    .bind(&week_anchor)
    .fetch_all(&pool)
    .await?;

    Ok(Json(rows.iter().map(row_to_slot).collect()))
}
