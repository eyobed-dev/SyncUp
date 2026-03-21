/// Shared date/time helpers used across handlers

use std::time::{SystemTime, UNIX_EPOCH};

/// Returns the ISO date (YYYY-MM-DD) of the Monday of the current week
pub fn current_week_anchor() -> String {
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    let days = secs / 86400;
    // Unix epoch (1970-01-01) was a Thursday. (days + 3) % 7 gives 0=Mon.
    let dow = (days + 3) % 7;
    let monday_days = days - dow;
    days_to_date(monday_days)
}

/// Returns the Monday of each of the next `n` weeks (including current week).
pub fn next_n_week_anchors(n: u64) -> Vec<String> {
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    let days = secs / 86400;
    let dow = (days + 3) % 7;
    let monday = days - dow;

    (0..n).map(|i| days_to_date(monday + i * 7)).collect()
}

/// Convert days-since-epoch to YYYY-MM-DD string
pub fn days_to_date(days: u64) -> String {
    let mut y = 1970u32;
    let mut d = days as u32;
    loop {
        let ydays = if is_leap(y) { 366 } else { 365 };
        if d < ydays {
            break;
        }
        d -= ydays;
        y += 1;
    }
    let months = [
        31u32,
        if is_leap(y) { 29 } else { 28 },
        31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
    ];
    let mut m = 0usize;
    for &mdays in &months {
        if d < mdays {
            break;
        }
        d -= mdays;
        m += 1;
    }
    format!("{:04}-{:02}-{:02}", y, m + 1, d + 1)
}

fn is_leap(y: u32) -> bool {
    (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
}
