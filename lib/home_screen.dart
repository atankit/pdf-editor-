import 'package:flutter/material.dart';
import 'package:pdf_generator/create_pdf_screen.dart';
import 'package:pdf_generator/edit_pdf/bottom_nav_bar.dart';
import 'package:pdf_generator/fillpdfform_screen.dart';
import 'package:pdf_generator/pdf_editor_screen.dart';
import 'package:pdf_generator/widgets/custom_style.dart';
import 'package:pdf_generator/pdf_image_edit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomStyle(
                text: "Create PDF",
                icon: Icons.picture_as_pdf,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreatePDFScreen()),
                  );
                },
              ),
              SizedBox(height: 10),
              CustomStyle(
                  text: "Edit PDF",
                  icon: Icons.edit,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BottomNavScreen()),
                    );
                  }),

              SizedBox(height: 10),
              CustomStyle(
                text: "Fill Form",
                icon: Icons.assignment,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> PDFFormFiller())
                  );
                },
              ),
              SizedBox(height: 10),
              CustomStyle(
                text: "Extract Text",
                icon: Icons.text_fields,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>PdfEditorScreen())
                  );
                },
              ),
              SizedBox(height: 10),
              CustomStyle(
                text: "Convert PDF to Image",
                icon: Icons.image,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>PdfImageEditingScreen())
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
