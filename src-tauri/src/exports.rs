use std::fs;
use std::path::PathBuf;
use serde::Serialize;
use tauri::{AppHandle, Manager};

/// Creates sample ICS calendar content
fn create_sample_ics_content() -> String {
    "BEGIN:VCALENDAR\r\n\
VERSION:2.0\r\n\
PRODID:-//Circuit Assistant//EN\r\n\
BEGIN:VEVENT\r\n\
UID:sample-event-001@circuitassistant.org\r\n\
DTSTAMP:20251109T120000Z\r\n\
DTSTART:20251115T100000Z\r\n\
DTEND:20251115T110000Z\r\n\
SUMMARY:Circuit Overseer Visit\r\n\
DESCRIPTION:Weekly meeting with Circuit Overseer talk\r\n\
LOCATION:Kingdom Hall\r\n\
STATUS:CONFIRMED\r\n\
END:VEVENT\r\n\
END:VCALENDAR\r\n".to_string()
}

/// Creates sample vCard contact content
fn create_sample_vcard_content() -> String {
    "BEGIN:VCARD\r\n\
VERSION:3.0\r\n\
FN:John Smith\r\n\
N:Smith;John;;;\r\n\
ORG:Kingdom Hall of Jehovah's Witnesses\r\n\
TITLE:Elder\r\n\
TEL;TYPE=CELL:+1-555-123-4567\r\n\
EMAIL:john.smith@example.com\r\n\
ADR;TYPE=HOME:;;123 Main Street;Anytown;CA;12345;USA\r\n\
NOTE:Circuit Overseer Contact\r\n\
END:VCARD\r\n".to_string()
}

/// Get the appropriate export directory based on platform
/// On iOS/Android: Returns app's Documents directory (accessible via Files app)
/// On Desktop: Returns app's data directory
fn get_export_directory(app: &AppHandle) -> Result<PathBuf, String> {
    // On iOS/Android, use app's document directory
    // This is accessible via Files app -> "On My iPhone/iPad" -> App Name
    #[cfg(any(target_os = "ios", target_os = "android"))]
    {
        let doc_dir = app
            .path()
            .document_dir()
            .map_err(|e| format!("Failed to get document directory: {}", e))?;

        // Ensure directory exists
        fs::create_dir_all(&doc_dir).map_err(|e| e.to_string())?;

        Ok(doc_dir)
    }
    
    // On desktop, use app data directory
    #[cfg(not(any(target_os = "ios", target_os = "android")))]
    {
        let app_dir = app
            .path()
            .app_data_dir()
            .map_err(|e| format!("Failed to get app data directory: {}", e))?;
        
        // Create directory if it doesn't exist
        fs::create_dir_all(&app_dir).map_err(|e| e.to_string())?;
        
        Ok(app_dir)
    }
}

#[tauri::command]
pub fn export_ics(app: AppHandle) -> Result<String, String> {
    // Get ICS content
    let ics_content = create_sample_ics_content();
    
    // Get the appropriate export directory
    let export_dir = get_export_directory(&app)?;
    
    // Create ICS file path
    let file_path = export_dir.join("CircuitOverseerVisit.ics");
    
    // Write to file
    fs::write(&file_path, ics_content).map_err(|e| e.to_string())?;
    
    // Return the file path as a string
    Ok(file_path.to_string_lossy().to_string())
}

#[tauri::command]
pub fn export_vcard(app: AppHandle) -> Result<String, String> {
    // Get vCard content
    let vcard_content = create_sample_vcard_content();
    
    // Get the appropriate export directory
    let export_dir = get_export_directory(&app)?;
    
    // Create vCard file path
    let file_path = export_dir.join("JohnSmith.vcf");
    
    // Write to file
    fs::write(&file_path, vcard_content).map_err(|e| e.to_string())?;
    
    // Return the file path as a string
    Ok(file_path.to_string_lossy().to_string())
}

/// Get ICS content - exposed for frontend to handle save on mobile
#[tauri::command]
pub fn get_ics_content() -> String {
    create_sample_ics_content()
}

/// Get vCard content - exposed for frontend to handle save on mobile
#[tauri::command]
pub fn get_vcard_content() -> String {
    create_sample_vcard_content()
}

/// File information for listing available files
#[derive(Serialize)]
pub struct FileInfo {
    pub name: String,
    pub path: String,
    pub size: u64,
}

/// List all JSON files in the app's Documents directory
#[tauri::command]
pub fn list_json_files(app: AppHandle) -> Result<Vec<FileInfo>, String> {
    let export_dir = get_export_directory(&app)?;
    
    let mut json_files = Vec::new();
    
    // Read directory entries
    let entries = fs::read_dir(&export_dir).map_err(|e| e.to_string())?;
    
    for entry in entries {
        let entry = entry.map_err(|e| e.to_string())?;
        let path = entry.path();
        
        // Check if it's a file and has .json extension
        if path.is_file() {
            if let Some(extension) = path.extension() {
                if extension == "json" {
                    let metadata = fs::metadata(&path).map_err(|e| e.to_string())?;
                    let name = path.file_name()
                        .and_then(|n| n.to_str())
                        .ok_or("Invalid filename")?
                        .to_string();
                    
                    json_files.push(FileInfo {
                        name,
                        path: path.to_string_lossy().to_string(),
                        size: metadata.len(),
                    });
                }
            }
        }
    }
    
    // Sort by name
    json_files.sort_by(|a, b| a.name.cmp(&b.name));
    
    Ok(json_files)
}

/// Read a JSON file from the app's Documents directory
#[tauri::command]
pub fn read_json_file(file_path: String) -> Result<String, String> {
    // Read the file
    let contents = fs::read_to_string(&file_path).map_err(|e| e.to_string())?;
    Ok(contents)
}

/// Create a sample events JSON file in the Documents directory for testing
#[tauri::command]
pub fn create_sample_events(app: AppHandle) -> Result<String, String> {
    let sample_events = r#"[
  {
    "title": "Circuit Overseer Visit",
    "date": "2025-11-11",
    "time": "7:00 PM",
    "location": "Kingdom Hall",
    "description": "Weekly meeting with Circuit Overseer talk",
    "color": "primary"
  },
  {
    "title": "Field Service",
    "date": "2025-11-12",
    "time": "9:30 AM",
    "location": "Kingdom Hall",
    "description": "Morning service arrangement",
    "color": "green"
  },
  {
    "title": "Servants Meeting",
    "date": "2025-11-12",
    "time": "6:00 PM",
    "location": "Kingdom Hall",
    "description": "Meeting with elders and ministerial servants",
    "color": "blue"
  },
  {
    "title": "Pioneers Meeting",
    "date": "2025-11-13",
    "time": "6:00 PM",
    "location": "Kingdom Hall",
    "description": "Meeting with regular and auxiliary pioneers",
    "color": "purple"
  },
  {
    "title": "Weekend Meeting",
    "date": "2025-11-16",
    "time": "10:00 AM",
    "location": "Kingdom Hall",
    "description": "Public talk and Watchtower study",
    "color": "orange"
  }
]"#;

    // Get the export directory
    let export_dir = get_export_directory(&app)?;
    
    // Create sample events file path
    let file_path = export_dir.join("events-sample.json");
    
    // Write to file
    fs::write(&file_path, sample_events).map_err(|e| e.to_string())?;
    
    // Return the file path as a string
    Ok(file_path.to_string_lossy().to_string())
}

/// Ensure that a small placeholder file exists in the Documents directory so that
/// the Files app will display the app folder on device installs (TestFlight/App Store).
#[tauri::command]
pub fn ensure_documents_placeholder(app: AppHandle) -> Result<String, String> {
    let export_dir = get_export_directory(&app)?;
    let placeholder = export_dir.join("CircuitAssistant-README.txt");

    if !placeholder.exists() {
        let content = "Circuit Assistant app files go in this folder.\n";
        fs::write(&placeholder, content).map_err(|e| e.to_string())?;
    }

    Ok(placeholder.to_string_lossy().to_string())
}

