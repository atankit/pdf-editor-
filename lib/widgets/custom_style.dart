import 'package:flutter/material.dart';

class CustomStyle extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData icon;
  final Color backgroundColor;
  final TextStyle textStyle;


  const CustomStyle({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.icon,
     this.backgroundColor = Colors.deepPurple,
    this.textStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,  // Custom background color
        foregroundColor: Colors.white, // Text color
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Bigger padding
        textStyle: textStyle, // Stylish text
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded edges
        ),
        elevation: 5, // Add some depth
        shadowColor: Colors.black45, // Shadow effect
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white), // Button icon
          SizedBox(width: 8), // Space between icon and text
          Text(text),
        ],
      ),
    );
  }
}

class CustomInputField extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController? controller;


  const CustomInputField({
    Key? key,
    required this.title,
    required this.hint,
    this.controller,

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Container(
            height: 52,
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.only(left: 14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1.0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(

                    autofocus: false,
                    cursorColor: Colors.grey[700],
                    controller: controller,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 0),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
