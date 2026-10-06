import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2563EB),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.location_on_rounded, color: Colors.white, size: 96),
          SizedBox(height: 12),
          Text('WhereWeAre',
              style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
