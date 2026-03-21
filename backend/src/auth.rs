use axum::{
    async_trait,
    extract::FromRequestParts,
    http::{request::Parts, HeaderMap},
};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};

use crate::errors::AppError;

const JWT_SECRET: &str = "syncup_super_secret_jwt_key_2026";
const JWT_EXPIRY_SECS: u64 = 86400 * 7; // 7 days

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: i64,       // user id
    pub role: String,   // "professor" or "student"
    pub exp: usize,
}

pub fn create_token(user_id: i64, role: &str) -> anyhow::Result<String> {
    let exp = SystemTime::now()
        .duration_since(UNIX_EPOCH)?
        .as_secs() + JWT_EXPIRY_SECS;
    
    let claims = Claims {
        sub: user_id,
        role: role.to_string(),
        exp: exp as usize,
    };
    
    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(JWT_SECRET.as_bytes()),
    )?;
    Ok(token)
}

pub fn verify_token(token: &str) -> Result<Claims, AppError> {
    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(JWT_SECRET.as_bytes()),
        &Validation::default(),
    )
    .map_err(|_| AppError::Unauthorized("Invalid or expired token".to_string()))?;
    Ok(token_data.claims)
}

fn extract_bearer_token(headers: &HeaderMap) -> Option<String> {
    headers
        .get("Authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.strip_prefix("Bearer "))
        .map(|s| s.to_string())
}

/// Extractor for any authenticated user
#[derive(Debug, Clone)]
pub struct AuthUser(pub Claims);

#[async_trait]
impl<S> FromRequestParts<S> for AuthUser
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let token = extract_bearer_token(&parts.headers)
            .ok_or_else(|| AppError::Unauthorized("Missing Authorization header".to_string()))?;
        let claims = verify_token(&token)?;
        Ok(AuthUser(claims))
    }
}

/// Extractor that requires professor role
#[derive(Debug, Clone)]
pub struct ProfessorAuth(pub Claims);

#[async_trait]
impl<S> FromRequestParts<S> for ProfessorAuth
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let token = extract_bearer_token(&parts.headers)
            .ok_or_else(|| AppError::Unauthorized("Missing Authorization header".to_string()))?;
        let claims = verify_token(&token)?;
        if claims.role != "professor" {
            return Err(AppError::Forbidden("Professor role required".to_string()));
        }
        Ok(ProfessorAuth(claims))
    }
}

/// Extractor that requires student role
#[derive(Debug, Clone)]
pub struct StudentAuth(pub Claims);

#[async_trait]
impl<S> FromRequestParts<S> for StudentAuth
where
    S: Send + Sync,
{
    type Rejection = AppError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        let token = extract_bearer_token(&parts.headers)
            .ok_or_else(|| AppError::Unauthorized("Missing Authorization header".to_string()))?;
        let claims = verify_token(&token)?;
        if claims.role != "student" {
            return Err(AppError::Forbidden("Student role required".to_string()));
        }
        Ok(StudentAuth(claims))
    }
}
