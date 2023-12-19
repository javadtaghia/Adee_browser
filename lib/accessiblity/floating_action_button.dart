import 'package:flutter/material.dart';

class MovableAccessibilityFAB extends StatefulWidget {
  final VoidCallback onPressed;

  const MovableAccessibilityFAB({super.key, required this.onPressed});

  @override
  // ignore: library_private_types_in_public_api
  _MovableAccessibilityFABState createState() =>
      _MovableAccessibilityFABState();
}

class _MovableAccessibilityFABState extends State<MovableAccessibilityFAB> {
  Offset fabPosition = const Offset(0, 0); // Initial position

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenHeight = MediaQuery.of(context).size.height;
      const fabSize = 40.0; // Default FAB size, adjust if needed
      setState(() {
        fabPosition = Offset(
            0 + fabSize, screenHeight - fabSize * 1.5); // Bottom left corner
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: fabPosition.dx,
          top: fabPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                fabPosition = Offset(
                  fabPosition.dx + details.delta.dx,
                  fabPosition.dy + details.delta.dy,
                );
              });
            },
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: Colors.transparent, // Make it transparent
              child: const CircleAvatar(
                backgroundColor: Colors.blue, // Change the color as needed
                child: Icon(
                  Icons.accessibility,
                  color: Colors.white, // Change the icon color as needed
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
