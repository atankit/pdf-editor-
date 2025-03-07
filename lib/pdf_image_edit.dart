import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;

class PdfImageEditingScreen extends StatefulWidget {
  @override
  _PdfImageEditingScreenState createState() => _PdfImageEditingScreenState();
}

class _PdfImageEditingScreenState extends State<PdfImageEditingScreen> {
  File? _selectedPdf;
  List<File> _images = [];

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
        _images.clear();
      });
    }
  }

  Future<void> _convertPdfToImages() async {
    if (_selectedPdf == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a PDF first!")),
      );
      return;
    }

    List<File> imageFiles = [];
    Uint8List pdfBytes = await _selectedPdf!.readAsBytes();
    final pdfStream = Printing.raster(pdfBytes, dpi: 200);

    int index = 0;
    await for (final pdfRaster in pdfStream) {
      Uint8List imageBytes = await pdfRaster.toPng();

      Uint8List processedImage = await _applyWhiteBackground(imageBytes);

      File imageFile = await _saveImageToFile(processedImage, index);
      imageFiles.add(imageFile);
      index++;
    }

    setState(() {
      _images = imageFiles;
    });
  }

  Future<Uint8List> _applyWhiteBackground(Uint8List imageBytes) async {
    ui.Image uiImage = await decodeImageFromList(imageBytes);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()),
      paint,
    );

    canvas.drawImage(uiImage, Offset.zero, Paint());

    final newImage = await recorder.endRecording().toImage(uiImage.width, uiImage.height);
    final byteData = await newImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<File> _saveImageToFile(Uint8List imageData, int index) async {
    if (!await _requestStoragePermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Storage permission denied! Enable it in settings.")),
      );
      throw Exception("Storage permission denied.");
    }

    Directory directory = Directory('/storage/emulated/0/Download');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final imagePath = '${directory.path}/pdf_img_$index.png';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(imageData);
    return imageFile;
  }

  Future<void> _editImage(int index) async {
    final editedImage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditor(
          image: _images[index].readAsBytesSync(),
        ),
      ),
    );

    if (editedImage != null) {
      setState(() {
        _images[index] = File('${_images[index].path}')..writeAsBytesSync(editedImage);
      });
    }
  }

  Future<void> _convertToPDF() async {
    final pdf = pw.Document();
    if(!await _requestStoragePermission()){
      return;
    }
    for (var image in _images) {
      final imageBytes = await image.readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pdfImage),
            );
          },
        ),
      );
    }

    final downloadsDir = Directory('/storage/emulated/0/Download');
    final fileName = "Edited_Pdf_${DateTime.now().millisecondsSinceEpoch}.pdf";
    final file = File("${downloadsDir.path}/$fileName");
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PDF Saved: ${file.path}")),
    );
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true;
      } else {
        var status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      }
    }
    return true;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("PDF to Image & Editing")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _pickPdf,
                child: Text("Pick PDF"),
              ),
              ElevatedButton(
                onPressed: _convertPdfToImages,
                child: Text("PDF to Images"),
              ),
              ElevatedButton(
                onPressed: _images.isNotEmpty ? _convertToPDF : null,
                child: Text("Save as PDF"),
              ),
            ],
          ),
          if (_selectedPdf != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Selected PDF: ${_selectedPdf!.path.split('/').last}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: _images.isNotEmpty
                ? ListView.builder(
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(_images[index]),
                    ),
                    ElevatedButton(
                      onPressed: () => _editImage(index),
                      child: Text("Edit Image"),
                    ),
                  ],
                );
              },
            )
                : Center(child: Text("No images generated yet.")),
          ),
        ],
      ),
    );
  }
}
