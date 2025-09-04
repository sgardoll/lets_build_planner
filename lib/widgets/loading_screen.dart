import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrDesktop = screenWidth >= 768;
    
    return Scaffold(
      backgroundColor: const Color(0xFFE9DFD8), // Background color #E9DFD8
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              constraints: BoxConstraints(
                maxWidth: isTabletOrDesktop ? 400 : 280,
                maxHeight: isTabletOrDesktop ? 200 : 140,
              ),
              child: isTabletOrDesktop 
                ? Image.asset(
                    'images/logo_horizontal.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to text if image fails to load
                      return _buildFallbackLogo(context, true);
                    },
                  )
                : Image.asset(
                    'images/logo_vertical.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to text if image fails to load
                      return _buildFallbackLogo(context, false);
                    },
                  ),
            ),
            
            const SizedBox(height: 40),
            
            // Loading indicator
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF6A47)), // Orange color from logo
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Loading text
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(BuildContext context, bool isHorizontal) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: isHorizontal 
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "LET'S",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEF6A47), // Orange from logo
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "BUILD",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "LET'S",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEF6A47), // Orange from logo
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "BUILD",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
    );
  }
}