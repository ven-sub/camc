// Mobile entry point for iOS/Android builds
// This file is only used for mobile builds, desktop uses main.rs

mod commands;
mod db;
mod exports;

use std::sync::Mutex;

// Mobile entry point (for iOS/Android builds only)
#[cfg(mobile)]
#[tauri::mobile_entry_point]
fn main() {
    // Initialize database
    let conn = db::init_db().expect("Failed to initialize database");

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
            exports::get_vcard_content
            // Also expose file-related commands on mobile (import/export/list)
            ,
            exports::list_json_files,
            exports::read_json_file,
            exports::create_sample_events
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
