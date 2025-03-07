
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';

class PDFFormFiller extends StatefulWidget {
  @override
  _PDFFormFillerState createState() => _PDFFormFillerState();
}

class _PDFFormFillerState extends State<PDFFormFiller> {
  File? _pdfFile;
  Map<String, TextEditingController> _controllers = {};
  Map<String, bool> _checkboxValues = {};
  Map<String, int> _radioValues = {};
  Map<String, String> _dropdownValues = {};
  PdfDocument? _document;

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      setState(() => _pdfFile = file);
      _loadPDF(file);
    }
  }

  Future<void> _loadPDF(File file) async {
    final bytes = await file.readAsBytes();
    _document = PdfDocument(inputBytes: bytes);
    final fields = _document!.form.fields;

    setState(() {
      _controllers.clear();
      _checkboxValues.clear();
      _radioValues.clear();
      _dropdownValues.clear();

      for (int i = 0; i < fields.count; i++) {
        final field = fields[i];

        if (field is PdfTextBoxField && field.name != null) {
          _controllers[field.name!] = TextEditingController(text: field.text);
        } else if (field is PdfCheckBoxField && field.name != null) {
          _checkboxValues[field.name!] = field.isChecked;
        } else if (field is PdfRadioButtonListField && field.name != null) {
          _radioValues[field.name!] = field.selectedIndex;
        } else if (field is PdfComboBoxField && field.name != null) {
          _dropdownValues[field.name!] = field.selectedValue ?? "";
        }
      }
    });
  }

  Future<void> _savePDF() async {
    if (_document == null) return;

    _document!.form.setDefaultAppearance(true);

    for (int i = 0; i < _document!.form.fields.count; i++) {
      final field = _document!.form.fields[i];

      if (field is PdfTextBoxField && field.name != null) {
        field.text = _controllers[field.name!]!.text;
      } else if (field is PdfCheckBoxField && field.name != null) {
        field.isChecked = _checkboxValues[field.name!] ?? false;
      } else if (field is PdfRadioButtonListField && field.name != null) {
        field.selectedIndex = _radioValues[field.name!] ?? 0;
      } else if (field is PdfComboBoxField && field.name != null) {
        field.selectedValue = _dropdownValues[field.name!] ?? "";
      }
    }

    final bytes = _document!.saveSync();
    _document!.dispose();

    Directory? downloadsDirectory;
    if (Platform.isAndroid) {
      downloadsDirectory = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      downloadsDirectory = await getApplicationDocumentsDirectory(); // iOS fallback
    }

    if (downloadsDirectory != null) {
      final file = File('${downloadsDirectory.path}/filled_form_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to ${file.path}')),
      );

      // Open the saved file
      OpenFilex.open(file.path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save PDF: Downloads folder not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fillable PDF Form')),
      body: Column(
        children: [
          ElevatedButton(onPressed: _pickPDF, child: Text('Load PDF')),
          Expanded(
            child: ListView(
              children: [
                ..._controllers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(labelText: entry.key),
                    ),
                  );
                }),
                ..._checkboxValues.entries.map((entry) {
                  return CheckboxListTile(
                    title: Text(entry.key),
                    value: entry.value,
                    onChanged: (bool? value) {
                      setState(() => _checkboxValues[entry.key] = value ?? false);
                    },
                  );
                }),
                ..._radioValues.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: List.generate(3, (index) {
                          return Expanded(
                            child: RadioListTile<int>(
                              title: Text('Option ${index + 1}'),
                              value: index,
                              groupValue: entry.value,
                              onChanged: (int? value) {
                                setState(() => _radioValues[entry.key] = value ?? 0);
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                }),
                ..._dropdownValues.entries.map((entry) {
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: entry.key),
                    value: entry.value.isNotEmpty ? entry.value : null,
                    items: ["Option 1", "Option 2", "Option 3"].map((option) {
                      return DropdownMenuItem<String>(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() => _dropdownValues[entry.key] = value ?? "");
                    },
                  );
                }),
              ],
            ),
          ),
          ElevatedButton(onPressed: _savePDF, child: Text('Save PDF')),
        ],
      ),
    );
  }
}

