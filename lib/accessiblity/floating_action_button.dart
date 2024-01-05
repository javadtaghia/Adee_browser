import 'package:flutter/material.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:provider/provider.dart';

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
    var browserModel = Provider.of<BrowserModel>(context, listen: true);

    return Stack(
      children: [
        // Other widgets might go here
        if (browserModel.getCurrentTab() != null)
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
                  backgroundColor: Colors.white, // Change the color as needed
                  child: Icon(
                    Icons.accessibility,
                    color: Colors
                        .deepPurpleAccent, // Change the icon color as needed
                  ),
                ),
              ),
            ),
          ),
        // Add more widgets if needed
      ],
    );
  }
}
