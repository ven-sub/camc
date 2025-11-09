// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;
mod db;
mod exports;

use db::init_db;
use std::sync::Mutex;

fn main() {
    // Initialize database
    let conn = init_db().expect("Failed to initialize database");

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
            exports::create_sample_events
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
