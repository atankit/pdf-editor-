import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_generator/widgets/custom_style.dart';
import 'package:printing/printing.dart';

class CreatePDFScreen extends StatefulWidget {
  @override
  _CreatePDFScreenState createState() => _CreatePDFScreenState();
}

class _CreatePDFScreenState extends State<CreatePDFScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _paragraphController = TextEditingController();

  List<List<TextEditingController>> tableData = [
    [TextEditingController(text: "Header 1"), TextEditingController(text: "Header 2"), TextEditingController(text: "Header 3")]
  ];

  File? _selectedImage;
  final picker = ImagePicker();

  double _fontSize = 18.0;
  pw.FontWeight _fontWeight = pw.FontWeight.normal;
  PdfColor _fontColor = PdfColors.black;
  String _selectedFontFamily = 'Roboto';

  final Map<String, PdfColor> _fontColors = {
    "Black": PdfColors.black,
    "Red": PdfColors.red,
    "Blue": PdfColors.blue,
    "Green": PdfColors.green,
    "Purple": PdfColors.purple,
  };


  final List<String> _fontFamilies = [
    'Roboto',
    'Skranji',
    'Poppins',
    'Lato',
    'Tinos',
    'Tomorrow',
  ];

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pw.Font ttf;
    pw.Font boldTtf;

    try {
      final ByteData fontData;
      final ByteData boldFontData;

      switch (_selectedFontFamily) {
        case 'Skranji':
          fontData = await rootBundle.load("assets/fonts/Skranji-Regular.ttf");
          boldFontData = await rootBundle.load("assets/fonts/Skranji-Bold.ttf");
          break;
        case 'Poppins':
          fontData = await rootBundle.load("assets/fonts/Poppins-Regular.ttf");
          boldFontData = await rootBundle.load("assets/fonts/Poppins-Bold.ttf");
          break;
        case 'Lato':
          fontData = await rootBundle.load("assets/fonts/Lato-Regular.ttf");
          boldFontData = await rootBundle.load("assets/fonts/Lato-Light.ttf");
          break;
        case 'Tinos':
          fontData = await rootBundle.load("assets/fonts/Tinos-Regular.ttf");
          boldFontData = await rootBundle.load("assets/fonts/Tinos-Bold.ttf");
          break;
          case 'Tomorrow':
          fontData = await rootBundle.load("assets/fonts/Tomorrow-Regular.ttf");
          boldFontData = await rootBundle.load("assets/fonts/Tomorrow-Bold.ttf");
          break;
        default:
          fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
          boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
      }

      // Convert ByteData to pw.Font
      ttf = pw.Font.ttf(fontData.buffer.asByteData());
      boldTtf = pw.Font.ttf(boldFontData.buffer.asByteData());
    } catch (e) {
      print("Font loading error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Font loading failed! Using default.")),
      );

      // Fallback to default font
      ttf = await PdfGoogleFonts.robotoRegular();
      boldTtf = await PdfGoogleFonts.robotoBold();
    }


    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Header(
              level: 0,
              child: pw.Text(
                "PDF Generator :-",
                style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Text(_titleController.text,
              style: pw.TextStyle(
                fontSize: _fontSize,
                font: _fontWeight == pw.FontWeight.bold ? boldTtf : ttf,
                color: _fontColor,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Text(_subtitleController.text,
              style: pw.TextStyle(
                fontSize: _fontSize,
                font: _fontWeight == pw.FontWeight.bold ? boldTtf : ttf,
                color: _fontColor,
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Text(_paragraphController.text,
              style: pw.TextStyle(
                fontSize: _fontSize,
                font: _fontWeight == pw.FontWeight.bold ? boldTtf : ttf,
                color: _fontColor,
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Text("Table:",
              style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            ),

            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                // Header Row with Background Color
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blueGrey300), // Header background color
                  children: tableData[0].map((headerCell) {
                    return pw.Container(
                      padding: pw.EdgeInsets.all(8),
                      child: pw.Text(
                        headerCell.text,
                        style: pw.TextStyle(
                          fontSize: _fontSize,
                          font: _fontWeight == pw.FontWeight.bold ? boldTtf : ttf,
                          color: PdfColors.white, // Text color for contrast
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Data Rows
                ...tableData.skip(1).map((row) {
                  return pw.TableRow(
                    children: row.map((cell) {
                      return pw.Container(
                        padding: pw.EdgeInsets.all(8),
                        color: PdfColors.grey100, // Background color for data cells
                        child: pw.Text(
                          cell.text,
                          style: pw.TextStyle(
                            fontSize: _fontSize,
                            font: ttf,
                            color: _fontColor,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),


            if (_selectedImage != null)
                      pw.Container(
                        margin: pw.EdgeInsets.only(top: 20),
                        child: pw.Image(
                            pw.MemoryImage(_selectedImage!.readAsBytesSync()),
                            width: 250,
                          height: 250,
                          fit: pw.BoxFit.contain,
                        ),
                      ),

          ],
        ),
      ),
    );


    try {
      // Save the file to the Downloads folder
      final downloadsDir = Directory('/storage/emulated/0/Download');
      final fileName = "Pdf_Generator_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final outputFile = File("${downloadsDir.path}/$fileName");

      // Write the PDF file
      await outputFile.writeAsBytes(await pdf.save());

      // Notify user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF saved to Downloads folder: $fileName")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save PDF: $e")),
      );
    }
  }

  void _addRow() {
    setState(() {
      tableData.add(List.generate(tableData[0].length, (index) => TextEditingController()));
    });
  }

  void _addColumn() {
    setState(() {
      for (var row in tableData) {
        row.add(TextEditingController());
      }
    });
  }

  void _deleteRow(int index) {
    if (tableData.length > 1) {
      setState(() {
        tableData.removeAt(index);
      });
    }
  }

  void _deleteColumn(int index) {
    if (tableData[0].length > 1) {
      setState(() {
        for (var row in tableData) {
          row.removeAt(index);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create PDF")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CustomInputField(
              title: "Title",
              hint: "Enter your title",
              controller: _titleController,
            ),

            CustomInputField(
              title: "Subtitle",
              hint: "Enter your subtitle",
              controller: _subtitleController,
            ),
            CustomInputField(
              title: "Paragraph",
              hint: "Enter your paragraph",
              controller: _paragraphController,
            ),

            SizedBox(height: 15),

            // Add Custom fonts and styling.

            Text("Table Data:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column Delete Buttons (above the table)
                  Row(
                    children: List.generate(
                      tableData[0].length,
                          (colIndex) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.blue),
                          onPressed: () => _deleteColumn(colIndex),
                        ),
                      ),
                    ),
                  ),

                  // Table Rows
                  Column(
                    children: tableData.asMap().entries.map((rowEntry) {
                      int rowIndex = rowEntry.key;
                      List<TextEditingController> row = rowEntry.value;

                      return Row(
                        children: [
                          // Table Cells
                          ...row.asMap().entries.map((cellEntry) {
                            int colIndex = cellEntry.key;
                            TextEditingController cell = cellEntry.value;
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: cell,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: "Cell",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.deepPurple, width: 1.5),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),

                          // Row Delete Button
                          if (tableData.length > 1)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteRow(rowIndex),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 10),

                  // Add Row & Column Buttons
                  Row(
                    children: [
                      CustomStyle(
                        text: "Add Row",
                        icon: Icons.table_rows_outlined,
                        onPressed: _addRow,
                        backgroundColor: Colors.deepPurpleAccent,
                        textStyle: TextStyle(fontSize: 14),
                      ),

                      SizedBox(width: 10),

                      CustomStyle(
                        text: "Add Column",
                        icon: Icons.view_column_outlined,
                        onPressed: _addColumn,
                        backgroundColor: Colors.deepPurpleAccent,
                        textStyle: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 10),

            _selectedImage == null
                ? Text("No Image Selected !!")
                : Image.file(_selectedImage!, height: 100),

            SizedBox(height: 10,),

            CustomStyle(
                text: "Pick Image",
                onPressed: _pickImage,
                icon: Icons.image_rounded
            ),

            SizedBox(height: 20),
            _buildFontSizeSlider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFontColorSelector(),
                _buildFontWeightSelector(),
                _buildFontFamilySelector(),
              ],
            ),

            SizedBox(height: 20),


            CustomStyle(
                text: "Save PDF",
                onPressed: _generatePDF,
                icon: Icons.picture_as_pdf
            ),
          ],
        ),
      ),
    );
  }


Widget _buildFontSizeSlider() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Font Size: ${_fontSize.toStringAsFixed(1)}"),
      Slider(
        value: _fontSize,
        min: 10.0,
        max: 30.0,
        divisions: 10,
        label: _fontSize.toStringAsFixed(1),
        onChanged: (value) {
          setState(() {
            _fontSize = value;
          });
        },
      ),
    ],
  );
}


Widget _buildFontWeightSelector() {
  return DropdownButton<pw.FontWeight>(
    value: _fontWeight,
    items: [
      DropdownMenuItem(value: pw.FontWeight.normal, child: Text("Normal")),
      DropdownMenuItem(value: pw.FontWeight.bold, child: Text("Bold")),
    ],
    onChanged: (value) {
      setState(() {
        _fontWeight = value!;
      });
    },
  );
}

Widget _buildFontColorSelector() {
  return DropdownButton<PdfColor>(
    value: _fontColor,
    items: _fontColors.entries
        .map((entry) => DropdownMenuItem(value: entry.value, child: Text(entry.key)))
        .toList(),
    onChanged: (value) {
      setState(() {
        _fontColor = value!;
      });
    },
  );
}

  Widget _buildFontFamilySelector() {
    return DropdownButton<String>(
      value: _selectedFontFamily,
      items: _fontFamilies
          .map((font) => DropdownMenuItem(value: font, child: Text(font)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedFontFamily = value!;
        });
      },
    );
  }
}
