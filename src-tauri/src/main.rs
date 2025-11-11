// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;
mod db;
mod exports;

use db::init_db;
use rusqlite::Connection;
use std::sync::Mutex;

/// Creates the Tauri application builder with all plugins and commands registered
fn create_tauri_app(conn: Connection) -> tauri::Builder<tauri::Wry> {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .manage(Mutex::new(conn))
        .invoke_handler(tauri::generate_handler![
            commands::greet,
            commands::get_platform,
            commands::test_db_connection,
            exports::export_ics,
            exports::export_vcard,
            exports::get_ics_content,
            exports::get_vcard_content,
            exports::list_json_files,
            exports::read_json_file,
            exports::create_sample_events,
            exports::ensure_documents_placeholder
        ])
}

fn main() {
    // Initialize database
    let conn = init_db().expect("Failed to initialize database");

    create_tauri_app(conn)
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
