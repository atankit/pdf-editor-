import 'package:flutter/material.dart';
import 'package:pdf_generator/edit_pdf/pdf_viewer_screen.dart';
import 'package:pdf_generator/edit_pdf/pdf_annotation_screen.dart';

class BottomNavScreen extends StatefulWidget {
  @override
  _BottomNavScreenState createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    PDFAddNoteScreen(),
    PDFAnnotationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_rounded),
            label: "Add Note",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.draw),
            label: "Draw",
          ),
        ],
      ),
    );
  }
}

class ScreenOne extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Home Screen", style: TextStyle(fontSize: 24)),
    );
  }
}


