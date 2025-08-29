#!/usr/bin/env -S rust-script
//! ```cargo
//! [package]
//! name = "weather-waybar"
//! version = "0.1.0"
//! edition = "2021"
//!
//! [dependencies]
//! reqwest = { version = "0.12", features = ["json","rustls-tls"] }
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! tokio = { version = "1.37", features = ["rt-multi-thread","macros"] }
//! chrono = { version = "0.4", features = ["alloc"] }
//! dirs = "5"
//! ```

use chrono::{Local, NaiveTime, Timelike};
use serde_json::{json, Value};
use std::collections::HashMap;
use std::fs::File;
use std::io::{BufRead, BufReader};

#[tokio::main]
async fn main() {
    // Overrides from files are kept in a local map
    let mut overrides: HashMap<String, String> = HashMap::new();
    if let Some(home) = dirs::home_dir() {
        load_env_file_into(
            home.join(".rlocal/state/hyde/staterc").to_string_lossy().as_ref(),
            &mut overrides,
        );
        load_env_file_into(
            home.join(".local/state/hyde/config").to_string_lossy().as_ref(),
            &mut overrides,
        );
    }

    // Settings with defaults
    let temp_unit = read_str(&overrides, "WEATHER_TEMPERATURE_UNIT", "c").to_lowercase();
    let time_format = read_str(&overrides, "WEATHER_TIME_FORMAT", "12h").to_lowercase();
    let windspeed_unit = read_str(&overrides, "WEATHER_WINDSPEED_UNIT", "km/h").to_lowercase();

    let show_icon = read_bool(&overrides, "WEATHER_SHOW_ICON", true);
    let show_location = read_bool(&overrides, "WEATHER_SHOW_LOCATION", true);
    let show_today_details = read_bool(&overrides, "WEATHER_SHOW_TODAY_DETAILS", true);

    let mut forecast_days: i32 = read_str(&overrides, "WEATHER_FORECAST_DAYS", "3")
        .parse()
        .unwrap_or(3);
    if !(0..=3).contains(&forecast_days) {
        forecast_days = 3;
    }

    let get_location = read_str(&overrides, "WEATHER_LOCATION", "").replace(' ', "_");

    // Sanitize units
    let temp_unit = if temp_unit == "c" || temp_unit == "f" { temp_unit } else { "c".into() };
    let time_format = if time_format == "12h" || time_format == "24h" { time_format } else { "12h".into() };
    let windspeed_unit = if windspeed_unit == "km/h" || windspeed_unit == "mph" { windspeed_unit } else { "km/h".into() };

    // Fetch
    let url = format!("https://wttr.in/{}?format=j1", get_location);
    let client = reqwest::Client::builder()
        .user_agent("Mozilla/5.0 (Waybar Weather Rust)")
        .build()
        .expect("client");

    let resp = match client.get(&url).timeout(std::time::Duration::from_secs(10)).send().await {
        Ok(r) => r,
        Err(_) => std::process::exit(1),
    };

    let weather: Value = match resp.json().await {
        Ok(j) => j,
        Err(_) => std::process::exit(1),
    };

    // Build output
    let codes = weather_codes();
    let mut text = String::new();
    let mut tooltip = String::new();

    let current_weather = &weather["current_condition"][0];

    // text
    text.push_str(&get_temperature(current_weather, &temp_unit));
    if show_icon {
        let icon = get_weather_icon(current_weather, &codes);
        text = format!("{}{}", icon, text);
    }
    if show_location {
        if let Some(city) = get_city_name(&weather) {
            text.push_str(" | ");
            text.push_str(&city);
        }
    }

    // tooltip
    if show_today_details {
        let desc = get_description(current_weather);
        let temp_now = get_temperature(current_weather, &temp_unit);
        tooltip.push_str(&format!("<b>{} {}</b>\n", desc, temp_now));

        let feels = get_feels_like(current_weather, &temp_unit);
        tooltip.push_str(&format!("Feels like: {}\n", feels));

        if let Some(city) = get_city_name(&weather) {
            tooltip.push_str(&format!("Location: {}\n", city));
        }

        let wind = get_wind_speed(current_weather, &windspeed_unit);
        tooltip.push_str(&format!("Wind: {}\n", wind));

        if let Some(hum) = current_weather["humidity"].as_str() {
            tooltip.push_str(&format!("Humidity: {}%\n", hum));
        }
    }

    // forecast
    let today_hour = Local::now().hour() as i32;
    for i in 0..forecast_days {
        let Some(day) = weather["weather"].get(i as usize) else { break };

        tooltip.push_str("\n<b>");
        match i {
            0 => tooltip.push_str("Today, "),
            1 => tooltip.push_str("Tomorrow, "),
            _ => {}
        }
        if let Some(date) = day["date"].as_str() {
            tooltip.push_str(date);
        }
        tooltip.push_str("</b>\n");

        let max_t = get_day_temp(day, "maxtempC", "maxtempF", &temp_unit);
        let min_t = get_day_temp(day, "mintempC", "mintempF", &temp_unit);
        let sunrise = get_timestamp(day, "sunrise", &time_format).unwrap_or_else(|| "?".into());
        let sunset = get_timestamp(day, "sunset", &time_format).unwrap_or_else(|| "?".into());

        tooltip.push_str(&format!("⬆️ {} ⬇️ {} ", max_t, min_t));
        tooltip.push_str(&format!("🌅 {} 🌇 {}\n", sunrise, sunset));

        if let Some(hours) = day["hourly"].as_array() {
            for hour in hours {
                if i == 0 {
                    if let Some(t) = hour["time"].as_str() {
                        if let Some(h) = parse_hour_index(t) {
                            if h < today_hour - 2 {
                                continue;
                            }
                        }
                    }
                }
                let hh = hour["time"].as_str().unwrap_or("0");
                let hh_fmt = format_time(hh);
                let icon = get_weather_icon(hour, &codes);
                let temp_h = get_temperature_hour(hour, &temp_unit);
                let desc = get_description(hour);
                let chances = format_chances(hour);

                tooltip.push_str(&format!(
                    "{} {} {} {}, {}\n",
                    hh_fmt,
                    icon,
                    format_temp(&temp_h),
                    desc,
                    chances
                ));
            }
        }
    }

    // Print JSON for Waybar
    let out = json!({
        "text": text,
        "tooltip": tooltip
    });

    println!("{}", out.to_string());
}

// Helpers

fn load_env_file_into(path: &str, out: &mut HashMap<String, String>) {
    if let Ok(file) = File::open(path) {
        let reader = BufReader::new(file);
        for line in reader.lines().flatten() {
            let trimmed = line.trim();
            if trimmed.is_empty() || trimmed.starts_with('#') {
                continue;
            }
            let mut s = trimmed.to_string();
            if let Some(rest) = s.strip_prefix("export ") {
                s = rest.to_string();
            }
            if let Some((k, v)) = s.split_once('=') {
                let val = v.trim_matches('"').to_string();
                out.insert(k.to_string(), val);
            }
        }
    }
}

fn read_str(map: &HashMap<String, String>, key: &str, default_: &str) -> String {
    if let Some(v) = map.get(key) {
        return v.clone();
    }
    std::env::var(key).unwrap_or_else(|_| default_.to_string())
}

fn read_bool(map: &HashMap<String, String>, key: &str, default_true: bool) -> bool {
    let raw = read_str(map, key, if default_true { "True" } else { "False" });
    matches!(raw.to_lowercase().as_str(), "true" | "1" | "t" | "y" | "yes")
}

fn weather_codes() -> HashMap<&'static str, &'static str> {
    let mut m = HashMap::new();
    for k in ["113"] { m.insert(k, "☀️ "); }
    for k in ["116"] { m.insert(k, "⛅ "); }
    for k in ["119", "122", "143", "248", "260"] { m.insert(k, "☁️ "); }
    for k in ["176","179","182","185","263","266","281","284","293","296","299","302","305","308","311","314","317","350","353","356","359","362","365","368","392"] {
        m.insert(k, "🌧️ ");
    }
    for k in ["200"] { m.insert(k, "⛈️ "); }
    for k in ["227","230","320","323","326","374","377","386","389"] { m.insert(k, "🌨️ "); }
    for k in ["329","332","335","338","371","395"] { m.insert(k, "❄️ "); }
    m
}

fn get_weather_icon(w: &Value, codes: &HashMap<&'static str, &'static str>) -> String {
    let code = w["weatherCode"].as_str().unwrap_or_default();
    codes.get(code).copied().unwrap_or("").to_string()
}

fn get_description(w: &Value) -> String {
    w["weatherDesc"][0]["value"].as_str().unwrap_or_default().to_string()
}

fn get_temperature(w: &Value, unit: &str) -> String {
    if unit == "c" {
        format!("{}°C", w["temp_C"].as_str().unwrap_or_default())
    } else {
        format!("{}°F", w["temp_F"].as_str().unwrap_or_default())
    }
}

fn get_temperature_hour(w: &Value, unit: &str) -> String {
    if unit == "c" {
        format!("{}°C", w["tempC"].as_str().unwrap_or_default())
    } else {
        format!("{}°F", w["tempF"].as_str().unwrap_or_default())
    }
}

fn get_feels_like(w: &Value, unit: &str) -> String {
    if unit == "c" {
        format!("{}°C", w["FeelsLikeC"].as_str().unwrap_or_default())
    } else {
        format!("{}°F", w["FeelsLikeF"].as_str().unwrap_or_default())
    }
}

fn get_wind_speed(w: &Value, unit: &str) -> String {
    if unit == "km/h" {
        format!("{}Km/h", w["windspeedKmph"].as_str().unwrap_or_default())
    } else {
        format!("{}Mph", w["windspeedMiles"].as_str().unwrap_or_default())
    }
}

fn get_day_temp(day: &Value, key_c: &str, key_f: &str, unit: &str) -> String {
    if unit == "c" {
        format!("{}°C", day[key_c].as_str().unwrap_or_default())
    } else {
        format!("{}°F", day[key_f].as_str().unwrap_or_default())
    }
}

fn get_city_name(weather: &Value) -> Option<String> {
    weather["nearest_area"][0]["areaName"][0]["value"].as_str().map(|s| s.to_string())
}

fn format_time(t: &str) -> String {
    // wttr hour strings like "0","300","600","900","1200"
    let s = if t.ends_with("00") { t.trim_end_matches("00").to_string() } else { t.to_string() };
    let mut s = s;
    while s.len() < 3 { s.push(' '); }
    s
}

fn format_temp(s: &str) -> String {
    let mut t = s.to_string();
    if !t.starts_with('-') { t.insert(0, ' '); }
    while t.len() < 5 { t.push(' '); }
    t
}

fn parse_hour_index(t: &str) -> Option<i32> {
    if t.is_empty() { return None; }
    if t.ends_with("00") {
        let trimmed = t.trim_end_matches("00");
        if trimmed.is_empty() { return Some(0); }
        trimmed.parse::<i32>().ok()
    } else {
        t.parse::<i32>().ok()
    }
}

fn format_chances(hour: &Value) -> String {
    let map = [
        ("chanceoffog", "Fog"),
        ("chanceoffrost", "Frost"),
        ("chanceofovercast", "Overcast"),
        ("chanceofrain", "Rain"),
        ("chanceofsnow", "Snow"),
        ("chanceofsunshine", "Sunshine"),
        ("chanceofthunder", "Thunder"),
        ("chanceofwindy", "Wind"),
    ];
    let mut parts: Vec<String> = Vec::new();
    for (key, label) in map {
        let v = hour[key].as_str().unwrap_or("0");
        if let Ok(n) = v.parse::<i32>() {
            if n > 0 {
                parts.push(format!("{} {}%", label, n));
            }
        }
    }
    parts.join(", ")
}

fn get_timestamp(day: &Value, which: &str, time_format: &str) -> Option<String> {
    let t = day["astronomy"][0][which].as_str()?;
    if time_format == "24h" {
        NaiveTime::parse_from_str(t, "%I:%M %p").ok().map(|nt| nt.format("%H:%M").to_string())
    } else {
        Some(t.to_string())
    }
}
