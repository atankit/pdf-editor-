import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';

class PDFAddNoteScreen extends StatefulWidget {
  @override
  _PDFAddNoteScreenState createState() => _PDFAddNoteScreenState();
}

class _PDFAddNoteScreenState extends State<PDFAddNoteScreen> {
  File? _pdfFile;
  PdfViewerController _pdfViewerController = PdfViewerController();
  TextEditingController _noteController = TextEditingController();
  List<Map<String, dynamic>> _notes = [];
  bool _isAddingNote = false;
  Offset _cursorPosition = Offset(100, 100);

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _saveAnnotatedPDF() async {
    if (_pdfFile == null) return;

    try {
      if (await Permission.storage.request().isGranted) {
        Directory? downloadsDir;
        if (Platform.isAndroid) {
          downloadsDir = Directory("/storage/emulated/0/Download");
        } else {
          downloadsDir = await getDownloadsDirectory();
        }

        if (downloadsDir == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to get Downloads folder path.")),
          );
          return;
        }

        String path = "${downloadsDir.path}/annotated_document${DateTime.now().millisecondsSinceEpoch}.pdf";
        File savedFile = File(path);

        PdfDocument document = PdfDocument(inputBytes: _pdfFile!.readAsBytesSync());
        PdfPage page = document.pages[0];
        PdfGraphics graphics = page.graphics;
        PdfBrush brush = PdfSolidBrush(PdfColor(0, 0, 0));
        PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);

        for (var note in _notes) {
          graphics.drawString(
            note["text"],
            font,
            brush: brush,
            bounds: Rect.fromLTWH(note["position"].dx, note["position"].dy, 200, 50),
          );
        }

        savedFile.writeAsBytesSync(document.saveSync());
        document.dispose();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF saved in Downloads folder!")),
        );
      }
    } catch (e) {
      print("Error saving PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("PDF Annotation"),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickPDF,
                child: Text("Pick PDF"),
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: _saveAnnotatedPDF,
                child: Text("Save PDF"),
              ),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                if (_pdfFile != null)
                  Positioned.fill(
                    child: SfPdfViewer.file(
                      _pdfFile!,
                      controller: _pdfViewerController,
                    ),
                  ),
                // Display existing notes
                for (var note in _notes)
                  Positioned(
                    left: note["position"].dx,
                    top: note["position"].dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          note["position"] += details.delta;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.yellowAccent,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
                        ),
                        child: Text(
                          note["text"],
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                // Adding a new note
                if (_isAddingNote)
                  Positioned(
                    left: _cursorPosition.dx,
                    top: _cursorPosition.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _cursorPosition += details.delta;
                        });
                      },
                      child: Icon(Icons.location_on, color: Colors.red, size: 30),
                    ),
                  ),
                if (_isAddingNote)
                  Positioned(
                    left: _cursorPosition.dx + 30,
                    top: _cursorPosition.dy,
                    child: Container(
                      width: 200,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              hintText: "Enter note",
                              border: InputBorder.none,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isAddingNote = false;
                                    _noteController.clear();
                                  });
                                },
                                child: Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (_noteController.text.trim().isNotEmpty) {
                                    setState(() {
                                      _notes.add({
                                        "position": _cursorPosition,
                                        "text": _noteController.text.trim(),
                                      });
                                      _isAddingNote = false;
                                      _noteController.clear();
                                    });
                                  }
                                },
                                child: Text("Save"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isAddingNote = !_isAddingNote;
          });
        },
        child: Icon(Icons.note_add),
        tooltip: "Add Note",
      ),
    );
  }
}
