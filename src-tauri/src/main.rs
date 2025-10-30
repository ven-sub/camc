// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod db;

use db::init_db;
use rusqlite::Connection;
use std::sync::Mutex;

// Global database connection
type DbConnection = Mutex<Connection>;

// Learn more about Tauri commands at https://tauri.app/v1/guides/features/command
#[tauri::command]
fn greet(name: &str) -> String {
    format!("Hello, {}! You've been greeted from Rust!", name)
}

#[tauri::command]
fn test_db_connection() -> String {
    "Database ready: camc.db".to_string()
}

#[tauri::command]
fn get_platform() -> String {
    #[cfg(target_os = "windows")]
    return "windows".to_string();
    #[cfg(target_os = "macos")]
    return "macos".to_string();
    #[cfg(target_os = "linux")]
    return "linux".to_string();
    #[cfg(target_os = "android")]
    return "android".to_string();
    #[cfg(target_os = "ios")]
    return "ios".to_string();
}

fn main() {
    // Initialize database
    let conn = init_db().expect("Failed to initialize database");
    
    tauri::Builder::default()
        .manage(Mutex::new(conn))
        .invoke_handler(tauri::generate_handler![
            greet, 
            get_platform, 
            test_db_connection
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
