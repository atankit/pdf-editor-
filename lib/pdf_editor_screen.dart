import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfEditorScreen extends StatefulWidget {
  @override
  _PdfEditorScreenState createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen> {
  TextEditingController _textController = TextEditingController();
  File? selectedFile;
  String? pdfPath;

  Future<void> pickAndExtractText() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        selectedFile = file;
        pdfPath = file.path;
      });
      extractFormattedTextFromPdf(file);
    }
  }

  Future<void> extractFormattedTextFromPdf(File file) async {
    try {
      PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());
      PdfTextExtractor extractor = PdfTextExtractor(document);
      String formattedText = "";
      for (int i = 0; i < document.pages.count; i++) {
        formattedText += extractor.extractText(layoutText: true, startPageIndex: i, endPageIndex: i);
        formattedText += "\n\n";
      }
      setState(() {
        _textController.text = formattedText;
      });
      document.dispose();
    } catch (e) {
      setState(() {
        _textController.text = "Failed to extract text.";
      });
    }
  }

  Future<void> saveEditedPdf() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Storage permission denied!")),
        );
        return;
      }
    }

    PdfDocument document = PdfDocument();
    document.pages.add().graphics.drawString(
      _textController.text,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
    );

    List<int> bytes = document.saveSync();
    document.dispose();

    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    String path = '${directory.path}/edited_pdf${DateTime.now().millisecondsSinceEpoch}.pdf';
    File file = File(path);
    await file.writeAsBytes(bytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved in Downloads: $path')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PDF Editor")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickAndExtractText,
              child: Text("Pick and Extract Text from PDF"),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Column(
                children: [
                  if (pdfPath != null)
                    Expanded(
                      child: PDFView(
                        filePath: pdfPath,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: true,
                        pageFling: true,
                      ),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Extracted text appears here...",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: saveEditedPdf,
              child: Text("Save as PDF"),
            ),
          ],
        ),
      ),
    );
  }
}
