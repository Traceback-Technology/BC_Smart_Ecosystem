import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Light Mode as default
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // --- LIGHT THEME ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      ),

      // --- DARK THEME ---
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0F12),
      ),

      home: WelcomeScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
        onStudentTap: () {
          // TODO: Express.js dev - Navigate to Student Auth/Dashboard
        },
        onVisitorTap: () {
          // TODO: Express.js dev - Navigate to Visitor flow
        },
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onStudentTap;
  final VoidCallback onVisitorTap;

  const WelcomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onStudentTap,
    required this.onVisitorTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : const Color(0xFF212121);
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black87;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // --- LOGO SECTION ---
              Image.asset(
                'assets/icons/bc_logo.jpeg',
                height: 65,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    'BELGIUM CAMPUS, iTversity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: textColor,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // --- MAP PINS & TITLE SECTION (NO BORDER / BACKGROUND BOX) ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    // Top Pins Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildMapPin(Icons.location_on, 'LIBRARY', Colors.cyan, isDarkMode)),
                        Expanded(child: _buildMapPin(Icons.location_on, 'RECEPTION', Colors.redAccent, isDarkMode)),
                        Expanded(child: _buildMapPin(Icons.location_on, 'CAFETERIA', Colors.red, isDarkMode)),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Center Title & Side Pins
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMapPin(Icons.location_on, 'MAIN GATE', Colors.amber, isDarkMode),
                        
                        // --- TITLE SECTION ---
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Welcome to',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 26, 
                                      fontWeight: FontWeight.w900,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'BC ',
                                        style: TextStyle(color: Color(0xFFFFC107)),
                                      ),
                                      TextSpan(
                                        text: 'WAYS ',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : const Color(0xFF212121),
                                        ),
                                      ),
                                      const TextSpan(
                                        text: '& ',
                                        style: TextStyle(color: Color(0xFFD32F2F)),
                                      ),
                                      const TextSpan(
                                        text: 'EATS',
                                        style: TextStyle(color: Color(0xFFFFC107)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildMapPin(Icons.location_on, 'SMART CITIES', Colors.cyan, isDarkMode),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bottom Pin
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildMapPin(Icons.location_on, 'CLASSROOM IOTA', Colors.redAccent, isDarkMode),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Accent Bar Line
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 24, height: 2, color: Colors.amber),
                  Container(width: 24, height: 2, color: Colors.red),
                  Container(width: 24, height: 2, color: Colors.cyan),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Navigate Belgium Campus smarter.\nOrder easier. Live better.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: subtitleColor,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // --- ACTION CARDS ---
              _buildOptionCard(
                context: context,
                backgroundColor: const Color(0xFFFFC107),
                textColor: Colors.black,
                subtitleColor: Colors.black87,
                icon: Icons.school,
                title: 'Continue as Student',
                subtitle: 'Access your dashboard, save places, view orders and more.',
                onTap: onStudentTap,
              ),

              const SizedBox(height: 14),

              _buildOptionCard(
                context: context,
                backgroundColor: const Color(0xFF8B0000),
                textColor: Colors.white,
                subtitleColor: Colors.white70,
                icon: Icons.people,
                title: 'Continue as Guest / Parent',
                subtitle: 'Explore campus, get directions and order food.',
                onTap: onVisitorTap,
              ),

              const SizedBox(height: 32),

              // --- BOTTOM CONTROL BUTTONS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onToggleTheme,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1A1D21)
                            : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white24
                              : Colors.amber.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDarkMode
                                ? Icons.wb_sunny_outlined
                                : Icons.dark_mode_outlined,
                            size: 16,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isDarkMode ? 'Light Mode' : 'Dark Mode',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // --- MAP PIN WIDGET BUILDER ---
  Widget _buildMapPin(IconData icon, String label, Color color, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : const Color(0xFF212121),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE CARD WIDGET BUILDER ---
  Widget _buildOptionCard({
    required BuildContext context,
    required Color backgroundColor,
    required Color textColor,
    required Color subtitleColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, size: 36, color: textColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}