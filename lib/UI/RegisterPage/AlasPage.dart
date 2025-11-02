import 'package:flutter/material.dart';

class AlasPage extends StatelessWidget {
  final String message;
  final String title;
  const AlasPage({
    super.key,
    required this.message,
    this.title = 'Something Went Wrong',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCB853), // #FCB853
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 48),
                // Main Dialog Box
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Error Icon with Background
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Color(0xFFD32F2F),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        // Error Message
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFB74D),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontSize: 17,
                              color: Color(0xFF424242),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),                        
                      ],
                    ),
                  ),
                ),
                
                // Error Bot Image Below Dialog Box
                const SizedBox(height: 20),
                Image.asset(
                  'assets/error_bot.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 12),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}
