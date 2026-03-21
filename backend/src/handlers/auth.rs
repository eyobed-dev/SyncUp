use axum::{extract::State, Json};
use sqlx::SqlitePool;

use crate::{
    auth::create_token,
    errors::AppError,
    models::{LoginRequest, LoginResponse},
};

pub async fn login(
    State(pool): State<SqlitePool>,
    Json(req): Json<LoginRequest>,
) -> Result<Json<LoginResponse>, AppError> {
    match req.role.as_str() {
        "professor" => {
            let row = sqlx::query(
                "SELECT id, name, password_hash FROM professors WHERE email = ?"
            )
            .bind(&req.email)
            .fetch_one(&pool)
            .await
            .map_err(|_| AppError::Unauthorized("Invalid email or password".to_string()))?;

            let id: i64 = sqlx::Row::get(&row, "id");
            let name: String = sqlx::Row::get(&row, "name");
            let password_hash: String = sqlx::Row::get(&row, "password_hash");

            let valid = bcrypt::verify(&req.password, &password_hash)
                .map_err(|e| AppError::Internal(anyhow::anyhow!(e)))?;
            if !valid {
                return Err(AppError::Unauthorized("Invalid email or password".to_string()));
            }

            let token = create_token(id, "professor")
                .map_err(|e| AppError::Internal(e))?;
            Ok(Json(LoginResponse { token, role: "professor".to_string(), user_id: id, name }))
        }
        "student" => {
            let row = sqlx::query(
                "SELECT id, name, surname, password_hash FROM students WHERE email = ?"
            )
            .bind(&req.email)
            .fetch_one(&pool)
            .await
            .map_err(|_| AppError::Unauthorized("Invalid email or password".to_string()))?;

            let id: i64 = sqlx::Row::get(&row, "id");
            let name: String = sqlx::Row::get(&row, "name");
            let surname: String = sqlx::Row::get(&row, "surname");
            let password_hash: String = sqlx::Row::get(&row, "password_hash");

            let valid = bcrypt::verify(&req.password, &password_hash)
                .map_err(|e| AppError::Internal(anyhow::anyhow!(e)))?;
            if !valid {
                return Err(AppError::Unauthorized("Invalid email or password".to_string()));
            }

            let token = create_token(id, "student")
                .map_err(|e| AppError::Internal(e))?;
            Ok(Json(LoginResponse {
                token,
                role: "student".to_string(),
                user_id: id,
                name: format!("{} {}", name, surname),
            }))
        }
        _ => Err(AppError::BadRequest("Role must be 'professor' or 'student'".to_string())),
    }
}
