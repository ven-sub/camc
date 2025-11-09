use std::fs;
use std::path::PathBuf;

#[cfg(any(target_os = "ios", target_os = "android"))]
use tauri::Manager;

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
fn get_export_directory() -> Result<PathBuf, String> {
    // On iOS/Android, use app's document directory
    // This is accessible via Files app -> "On My iPhone/iPad" -> App Name
    #[cfg(any(target_os = "ios", target_os = "android"))]
    {
        // Get the app's documents directory (not the system Documents)
        let doc_dir = dirs::document_dir()
            .ok_or("Failed to get document directory")?;
        
        // Ensure directory exists
        fs::create_dir_all(&doc_dir).map_err(|e| e.to_string())?;
        
        Ok(doc_dir)
    }
    
    // On desktop, use app data directory
    #[cfg(not(any(target_os = "ios", target_os = "android")))]
    {
        let app_dir = dirs::data_local_dir()
            .ok_or("Failed to get app data directory")?
            .join("org.circuitassistant.camc");
        
        // Create directory if it doesn't exist
        fs::create_dir_all(&app_dir).map_err(|e| e.to_string())?;
        
        Ok(app_dir)
    }
}

#[tauri::command]
pub fn export_ics() -> Result<String, String> {
    // Get ICS content
    let ics_content = create_sample_ics_content();
    
    // Get the appropriate export directory
    let export_dir = get_export_directory()?;
    
    // Create ICS file path
    let file_path = export_dir.join("CircuitOverseerVisit.ics");
    
    // Write to file
    fs::write(&file_path, ics_content).map_err(|e| e.to_string())?;
    
    // Return the file path as a string
    Ok(file_path.to_string_lossy().to_string())
}

#[tauri::command]
pub fn export_vcard() -> Result<String, String> {
    // Get vCard content
    let vcard_content = create_sample_vcard_content();
    
    // Get the appropriate export directory
    let export_dir = get_export_directory()?;
    
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

