use axum::{
    http::Method,
    routing::{delete, get, post},
    Router,
};
use sqlx::SqlitePool;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

mod auth;
mod db;
mod errors;
mod handlers;
mod models;

#[derive(Clone)]
pub struct AppState {
    pub pool: SqlitePool,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "syncup_backend=debug,tower_http=debug".into()))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load .env if present
    let _ = dotenvy::dotenv();

    let database_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "sqlite:./syncup.db".to_string());

    tracing::info!("Connecting to database: {}", database_url);
    let pool = db::create_pool(&database_url).await?;
    tracing::info!("Running migrations...");
    db::run_migrations(&pool).await?;
    tracing::info!("Migrations complete.");

    let cors = CorsLayer::new()
        .allow_methods([Method::GET, Method::POST, Method::DELETE, Method::PUT, Method::OPTIONS])
        .allow_headers(Any)
        .allow_origin(Any);

    let app = Router::new()
        // Auth
        .route("/api/auth/login", post(handlers::auth::login))
        // Professors (public)
        .route("/api/professors", get(handlers::professors::list_professors))
        .route("/api/professors/:id", get(handlers::professors::get_professor))
        .route("/api/professors/:id/slots", get(handlers::professors::get_professor_slots))
        // Professors (protected)
        .route("/api/professors/:id/slots", post(handlers::slots::add_slots))
        .route("/api/professors/me/schedule", get(handlers::professors::get_my_schedule))
        // Slots
        .route("/api/slots/:id", delete(handlers::slots::delete_slot))
        // Bookings
        .route("/api/bookings", post(handlers::bookings::create_booking))
        .route("/api/bookings/:id", delete(handlers::bookings::cancel_booking))
        .route("/api/students/me/bookings", get(handlers::bookings::get_my_bookings))
        .layer(cors)
        .layer(TraceLayer::new_for_http())
        .with_state(pool);

    let addr = "0.0.0.0:3000";
    tracing::info!("SyncUp backend listening on http://{}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;
    Ok(())
}
