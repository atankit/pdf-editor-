import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';

class PDFAnnotationScreen extends StatefulWidget {
  @override
  _PDFAnnotationScreenState createState() => _PDFAnnotationScreenState();
}

class _PDFAnnotationScreenState extends State<PDFAnnotationScreen> {
  File? _pdfFile;
  PdfViewerController _pdfViewerController = PdfViewerController();
  List<Offset> _drawingPoints = [];
  bool _isDrawing = false;

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

  void _toggleDrawingMode() {
    setState(() {
      _isDrawing = !_isDrawing;
      if (!_isDrawing) _drawingPoints.clear();
    });
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
        PdfPen pen = PdfPen(PdfColor(255, 0, 0), width: 2);

        double pdfWidth = page.size.width;
        double pdfHeight = page.size.height;

        double screenWidth = MediaQuery.of(context).size.width;
        double screenHeight = MediaQuery.of(context).size.height;

        double scaleX = pdfWidth / screenWidth;
        double scaleY = pdfHeight / screenHeight;

        for (int i = 0; i < _drawingPoints.length - 1; i++) {
          if (_drawingPoints[i] != Offset.zero && _drawingPoints[i + 1] != Offset.zero) {
            double startX = _drawingPoints[i].dx * scaleX;
            double startY = _drawingPoints[i].dy * scaleY;
            double endX = _drawingPoints[i + 1].dx * scaleX;
            double endY = _drawingPoints[i + 1].dy * scaleY;

            graphics.drawLine(pen, Offset(startX, startY), Offset(endX, endY));
          }
        }

        _drawingPoints.clear();
        savedFile.writeAsBytesSync(document.saveSync());
        document.dispose();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF saved in Downloads folder!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Storage permission denied")),
        );
      }
    } catch (e) {
      print("Error saving PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PDF Annotation")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: _pickPDF, child: Text("Pick PDF")),
              SizedBox(width: 10),
              ElevatedButton(onPressed: _saveAnnotatedPDF, child: Text("Save PDF")),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                if (_pdfFile != null)
                  SfPdfViewer.file(
                    _pdfFile!,
                    controller: _pdfViewerController,
                    enableTextSelection: true,
                  ),
                GestureDetector(
                  onPanUpdate: (details) {
                    if (_isDrawing) {
                      setState(() {
                        _drawingPoints.add(details.localPosition);
                      });
                    }
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _drawingPoints.add(Offset.zero);
                    });
                  },
                  child: CustomPaint(
                    painter: DrawingPainter(_drawingPoints),
                    child: Container(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _toggleDrawingMode,
          child: _isDrawing ? Icon(Icons.brush) : Icon(Icons.draw)
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset> points;
  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = Colors.red..strokeWidth = 3.0..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}
