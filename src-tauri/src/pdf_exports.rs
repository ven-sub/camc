use std::fs;
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

/// Get the appropriate export directory based on platform
/// Reuses the logic from exports.rs for cross-platform compatibility
fn get_export_directory(app: &AppHandle) -> Result<PathBuf, String> {
    #[cfg(any(target_os = "ios", target_os = "android"))]
    {
        let doc_dir = app
            .path()
            .document_dir()
            .map_err(|e| format!("Failed to get document directory: {}", e))?;

        fs::create_dir_all(&doc_dir).map_err(|e| e.to_string())?;
        Ok(doc_dir)
    }
    
    #[cfg(not(any(target_os = "ios", target_os = "android")))]
    {
        let app_dir = app
            .path()
            .app_data_dir()
            .map_err(|e| format!("Failed to get app data directory: {}", e))?;
        
        fs::create_dir_all(&app_dir).map_err(|e| e.to_string())?;
        Ok(app_dir)
    }
}

/// Generate Meeting Schedule PDF using printpdf
#[tauri::command]
pub fn generate_pdf_printpdf(app: AppHandle) -> Result<String, String> {
    use printpdf::*;
    
    // Get export directory
    let export_dir = get_export_directory(&app)?;
    let file_path = export_dir.join("MeetingSchedule.pdf");
    
    // Create PDF document
    let (doc, page1, layer1) = PdfDocument::new("Meeting Schedule", Mm(210.0), Mm(297.0), "Layer 1");
    let current_layer = doc.get_page(page1).get_layer(layer1);
    
    // Load fonts
    let font = doc.add_builtin_font(BuiltinFont::Helvetica).map_err(|e| e.to_string())?;
    let font_bold = doc.add_builtin_font(BuiltinFont::HelveticaBold).map_err(|e| e.to_string())?;
    
    // Title
    current_layer.use_text("MEETING SCHEDULE", 20.0, Mm(105.0), Mm(270.0), &font_bold);
    
    // Subtitle
    current_layer.use_text("Congregation Meeting Information", 12.0, Mm(70.0), Mm(260.0), &font);
    
    // Form fields with labels
    let mut y_pos = 240.0;
    let label_x = 20.0;
    let field_x = 80.0;
    let field_width = 100.0;
    
    // Helper to draw a labeled field
    let draw_field = |layer: &PdfLayerReference, y: f32, label: &str| {
        layer.use_text(label, 11.0, Mm(label_x), Mm(y), &font);
        // Draw underline for fillable field
        layer.set_outline_thickness(0.5);
        layer.add_line(
            Line {
                points: vec![
                    (Point::new(Mm(field_x), Mm(y - 2.0)), false),
                    (Point::new(Mm(field_x + field_width), Mm(y - 2.0)), false),
                ],
                is_closed: false,
            }
        );
    };
    
    draw_field(&current_layer, y_pos, "Congregation:");
    y_pos -= 15.0;
    
    draw_field(&current_layer, y_pos, "Week of:");
    y_pos -= 15.0;
    
    // Meeting section
    y_pos -= 10.0;
    current_layer.use_text("MIDWEEK MEETING", 13.0, Mm(20.0), Mm(y_pos), &font_bold);
    y_pos -= 15.0;
    
    draw_field(&current_layer, y_pos, "Date:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Time:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Location:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Chairman:");
    
    // Weekend meeting section
    y_pos -= 20.0;
    current_layer.use_text("WEEKEND MEETING", 13.0, Mm(20.0), Mm(y_pos), &font_bold);
    y_pos -= 15.0;
    
    draw_field(&current_layer, y_pos, "Date:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Time:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Speaker:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Talk Title:");
    
    // Footer
    current_layer.use_text("Circuit Assistant Mobile Companion", 8.0, Mm(60.0), Mm(20.0), &font);
    
    // Save PDF
    doc.save(&mut std::io::BufWriter::new(
        std::fs::File::create(&file_path).map_err(|e| e.to_string())?
    )).map_err(|e| e.to_string())?;
    
    Ok(file_path.to_string_lossy().to_string())
}

/// Generate Territory Assignment PDF using lopdf
#[tauri::command]
pub fn generate_pdf_lopdf(app: AppHandle) -> Result<String, String> {
    use lopdf::{Document, Object, Dictionary, Stream};
    use lopdf::content::{Content, Operation};
    
    // Get export directory
    let export_dir = get_export_directory(&app)?;
    let file_path = export_dir.join("TerritoryAssignment.pdf");
    
    // Create new PDF document
    let mut doc = Document::with_version("1.7");
    
    // Create page
    let pages_id = doc.new_object_id();
    let font_id = doc.add_object(
        Dictionary::from_iter(vec![
            ("Type", "Font".into()),
            ("Subtype", "Type1".into()),
            ("BaseFont", "Helvetica".into()),
        ])
    );
    let font_bold_id = doc.add_object(
        Dictionary::from_iter(vec![
            ("Type", "Font".into()),
            ("Subtype", "Type1".into()),
            ("BaseFont", "Helvetica-Bold".into()),
        ])
    );
    
    let resources_id = doc.add_object(
        Dictionary::from_iter(vec![
            ("Font", Dictionary::from_iter(vec![
                ("F1", font_id.into()),
                ("F2", font_bold_id.into()),
            ]).into()),
        ])
    );
    
    // Create content stream
    let mut content = Content { operations: vec![] };
    
    // Title
    content.operations.push(Operation::new("BT", vec![]));
    content.operations.push(Operation::new("Tf", vec!["F2".into(), 20.into()]));
    content.operations.push(Operation::new("Td", vec![100.into(), 750.into()]));
    content.operations.push(Operation::new("Tj", vec![Object::string_literal("TERRITORY ASSIGNMENT")]));
    content.operations.push(Operation::new("ET", vec![]));
    
    // Subtitle
    content.operations.push(Operation::new("BT", vec![]));
    content.operations.push(Operation::new("Tf", vec!["F1".into(), 12.into()]));
    content.operations.push(Operation::new("Td", vec![150.into(), 730.into()]));
    content.operations.push(Operation::new("Tj", vec![Object::string_literal("Territory Record")]));
    content.operations.push(Operation::new("ET", vec![]));
    
    // Form fields
    let mut y_pos = 680.0;
    let fields = vec![
        "Territory Number: ________________",
        "Publisher Name: __________________",
        "Date Assigned: ___________________",
        "Date Completed: __________________",
        "",
        "ASSIGNMENT DETAILS",
        "",
        "Description: _____________________",
        "_____________________________________",
        "",
        "Boundaries: ______________________",
        "_____________________________________",
        "",
        "Special Notes: ___________________",
        "_____________________________________",
        "_____________________________________",
    ];
    
    for field in fields {
        if field.is_empty() {
            y_pos -= 10.0;
        } else if field.starts_with("ASSIGNMENT") {
            content.operations.push(Operation::new("BT", vec![]));
            content.operations.push(Operation::new("Tf", vec!["F2".into(), 13.into()]));
            content.operations.push(Operation::new("Td", vec![50.into(), y_pos.into()]));
            content.operations.push(Operation::new("Tj", vec![Object::string_literal(field)]));
            content.operations.push(Operation::new("ET", vec![]));
            y_pos -= 20.0;
        } else {
            content.operations.push(Operation::new("BT", vec![]));
            content.operations.push(Operation::new("Tf", vec!["F1".into(), 11.into()]));
            content.operations.push(Operation::new("Td", vec![50.into(), y_pos.into()]));
            content.operations.push(Operation::new("Tj", vec![Object::string_literal(field)]));
            content.operations.push(Operation::new("ET", vec![]));
            y_pos -= 15.0;
        }
    }
    
    // Footer
    content.operations.push(Operation::new("BT", vec![]));
    content.operations.push(Operation::new("Tf", vec!["F1".into(), 8.into()]));
    content.operations.push(Operation::new("Td", vec![200.into(), 50.into()]));
    content.operations.push(Operation::new("Tj", vec![Object::string_literal("Circuit Assistant Mobile Companion")]));
    content.operations.push(Operation::new("ET", vec![]));
    
    let content_id = doc.add_object(Stream::new(
        Dictionary::new(),
        content.encode().map_err(|e| e.to_string())?
    ));
    
    // Create page object
    let page_id = doc.add_object(
        Dictionary::from_iter(vec![
            ("Type", "Page".into()),
            ("Parent", pages_id.into()),
            ("Contents", content_id.into()),
            ("Resources", resources_id.into()),
            ("MediaBox", vec![0.into(), 0.into(), 595.into(), 842.into()].into()),
        ])
    );
    
    // Create pages object
    let pages = Dictionary::from_iter(vec![
        ("Type", "Pages".into()),
        ("Kids", vec![page_id.into()].into()),
        ("Count", 1.into()),
    ]);
    doc.objects.insert(pages_id, Object::Dictionary(pages));
    
    // Create catalog
    let catalog_id = doc.add_object(
        Dictionary::from_iter(vec![
            ("Type", "Catalog".into()),
            ("Pages", pages_id.into()),
        ])
    );
    
    doc.trailer.set("Root", catalog_id);
    doc.compress();
    
    // Save PDF
    doc.save(&file_path).map_err(|e| e.to_string())?;
    
    Ok(file_path.to_string_lossy().to_string())
}

/// Generate Service Report PDF using genpdf
/// Note: This implementation uses printpdf instead due to genpdf font complexity
#[tauri::command]
pub fn generate_pdf_genpdf(app: AppHandle) -> Result<String, String> {
    use printpdf::*;
    
    // Get export directory
    let export_dir = get_export_directory(&app)?;
    let file_path = export_dir.join("ServiceReport.pdf");
    
    // Create PDF document
    let (doc, page1, layer1) = PdfDocument::new("Field Service Report", Mm(210.0), Mm(297.0), "Layer 1");
    let current_layer = doc.get_page(page1).get_layer(layer1);
    
    // Load fonts
    let font = doc.add_builtin_font(BuiltinFont::Helvetica).map_err(|e| e.to_string())?;
    let font_bold = doc.add_builtin_font(BuiltinFont::HelveticaBold).map_err(|e| e.to_string())?;
    
    // Title
    current_layer.use_text("FIELD SERVICE REPORT", 20.0, Mm(60.0), Mm(270.0), &font_bold);
    
    // Subtitle
    current_layer.use_text("Monthly Activity Summary", 12.0, Mm(70.0), Mm(260.0), &font);
    
    // Form fields
    let mut y_pos = 240.0;
    let label_x = 20.0;
    let field_x = 80.0;
    let field_width = 110.0;
    
    // Helper to draw a labeled field
    let draw_field = |layer: &PdfLayerReference, y: f32, label: &str| {
        layer.use_text(label, 11.0, Mm(label_x), Mm(y), &font);
        // Draw underline for fillable field
        layer.set_outline_thickness(0.5);
        layer.add_line(
            Line {
                points: vec![
                    (Point::new(Mm(field_x), Mm(y - 2.0)), false),
                    (Point::new(Mm(field_x + field_width), Mm(y - 2.0)), false),
                ],
                is_closed: false,
            }
        );
    };
    
    draw_field(&current_layer, y_pos, "Name:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Month:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Congregation:");
    
    // Activity section
    y_pos -= 20.0;
    current_layer.use_text("MINISTRY ACTIVITY", 13.0, Mm(20.0), Mm(y_pos), &font_bold);
    y_pos -= 15.0;
    
    draw_field(&current_layer, y_pos, "Hours:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Publications:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Videos Shown:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Return Visits:");
    y_pos -= 12.0;
    draw_field(&current_layer, y_pos, "Bible Studies:");
    
    // Participation section
    y_pos -= 20.0;
    current_layer.use_text("MEETING ATTENDANCE", 13.0, Mm(20.0), Mm(y_pos), &font_bold);
    y_pos -= 15.0;
    
    // Draw checkboxes
    let draw_checkbox = |layer: &PdfLayerReference, y: f32, label: &str| {
        // Draw checkbox as four lines
        layer.set_outline_thickness(0.5);
        // Bottom line
        layer.add_line(Line {
            points: vec![
                (Point::new(Mm(20.0), Mm(y)), false),
                (Point::new(Mm(25.0), Mm(y)), false),
            ],
            is_closed: false,
        });
        // Right line
        layer.add_line(Line {
            points: vec![
                (Point::new(Mm(25.0), Mm(y)), false),
                (Point::new(Mm(25.0), Mm(y + 5.0)), false),
            ],
            is_closed: false,
        });
        // Top line
        layer.add_line(Line {
            points: vec![
                (Point::new(Mm(25.0), Mm(y + 5.0)), false),
                (Point::new(Mm(20.0), Mm(y + 5.0)), false),
            ],
            is_closed: false,
        });
        // Left line
        layer.add_line(Line {
            points: vec![
                (Point::new(Mm(20.0), Mm(y + 5.0)), false),
                (Point::new(Mm(20.0), Mm(y)), false),
            ],
            is_closed: false,
        });
        layer.use_text(label, 11.0, Mm(28.0), Mm(y + 1.0), &font);
    };
    
    draw_checkbox(&current_layer, y_pos, "Attended Midweek Meeting");
    y_pos -= 10.0;
    draw_checkbox(&current_layer, y_pos, "Attended Weekend Meeting");
    
    // Footer
    current_layer.use_text("Circuit Assistant Mobile Companion", 8.0, Mm(60.0), Mm(20.0), &font);
    
    // Save PDF
    doc.save(&mut std::io::BufWriter::new(
        std::fs::File::create(&file_path).map_err(|e| e.to_string())?
    )).map_err(|e| e.to_string())?;
    
    Ok(file_path.to_string_lossy().to_string())
}

