use std::fs;
use std::io::{BufRead, BufReader};
use std::path::Path;
use std::process::{Command, Stdio};
use std::str;

const DEVICE_NAME: &str = "Lenovo Yoga Tablet Mode Control switch";
const PID_FILE: &str = "/tmp/iio-hyprland.pid";

fn on_tablet_mode() {
    println!("[hook] Tablet mode ON — starting rotation");
    let child = Command::new("iio-hyprland")
        .env("MONITOR", "eDP-1")
        .arg("eDP-1")
        .spawn()
        .expect("Failed to start iio-hyprland");

    fs::write(PID_FILE, child.id().to_string()).unwrap();
}

fn on_laptop_mode() {
    println!("[hook] Tablet mode OFF — stopping rotation");
    if let Ok(pid_str) = fs::read_to_string(PID_FILE) {
        if let Ok(pid) = pid_str.trim().parse::<i32>() {
            let _ = Command::new("kill").arg(pid.to_string()).status();
        }
        let _ = fs::remove_file(PID_FILE);
    }
    let _ = Command::new("hyprctl").arg("reload").status();
}

fn find_event_file() -> Option<String> {
    let content = fs::read_to_string("/proc/bus/input/devices").ok()?;
    let mut match_name = false;
    let mut event: Option<String> = None;

    for block in content.split("\n\n") {
        match_name = false;
        event = None;

        for line in block.lines() {
            if line.starts_with("N: Name=") && line.contains(DEVICE_NAME) {
                match_name = true;
            }
            if line.starts_with("H: Handlers=") {
                if let Some(caps) = line.split_whitespace().find(|s| s.starts_with("event")) {
                    event = Some(format!("/dev/input/{}", caps));
                }
            }
        }

        if match_name {
            if let Some(e) = event {
                if Path::new(&e).exists() {
                    return Some(e);
                }
            }
        }
    }
    None
}

fn main() {
    let event_file = match find_event_file() {
        Some(path) => path,
        None => {
            eprintln!("[error] Could not find tablet mode switch device.");
            std::process::exit(1);
        }
    };

    println!("[info] Monitoring tablet mode on: {}", event_file);

    let evtest = Command::new("evtest")
        .arg(&event_file)
        .stdout(Stdio::piped())
        .spawn()
        .expect("Failed to run evtest");

    let stdout = evtest.stdout.expect("No stdout from evtest");
    let reader = BufReader::new(stdout);

    for line in reader.lines() {
        if let Ok(line) = line {
            if let Some(caps) = line.split("value ").nth(1) {
                match caps.trim() {
                    "1" => on_tablet_mode(),
                    "0" => on_laptop_mode(),
                    _ => {}
                }
            }
        }
    }
}
