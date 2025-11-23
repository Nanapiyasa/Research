import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Down Syndrome Learning App',
      home: const GameMenuScreen(),
    );
  }
}

class GameMenuScreen extends StatelessWidget {
  const GameMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF87CEEB),
              Color(0xFFA8D8F0),
              Color(0xFFC8E6F5),
              Color(0xFFF4D8B8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Stack(
          children: [

            // ⭐ Background Decorations
            Positioned(
              top: 20,
              left: 16,
              child: Triangle(color: Color(0xFFFFB347), size: 60, angle: 15),
            ),
            Positioned(
              top: 150,
              right: 24,
              child: Triangle(color: Color(0xFFB19CD9), size: 50, angle: -20),
            ),
            Positioned(
              bottom: 120,
              left: 20,
              child: Triangle(color: Color(0xFF77DD77), size: 70, angle: 25),
            ),

            // Title
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B9EFF), Color(0xFF4A8DE8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      )
                    ],
                  ),
                  child: const Text(
                    "Game Menu",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFE135),
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(3, 3),
                          blurRadius: 6,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ⭐ BUTTON GRID
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 150),
                child: SizedBox(
                  width: 380,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 25,
                    crossAxisSpacing: 25,

                    children: [
                      MenuButton(
                        title: "Cognitive\nSkills",
                        color1: Color(0xFFFF9E3D),
                        color2: Color(0xFFFF7B25),
                        icon: Icons.extension,
                        onPressed: () => debugPrint("Cognitive Skills"),
                      ),
                      MenuButton(
                        title: "Literacy\nSkills",
                        color1: Color(0xFFB565E8),
                        color2: Color(0xFF9B4DD3),
                        icon: Icons.book,
                        onPressed: () => debugPrint("Literacy Skills"),
                      ),
                      MenuButton(
                        title: "Numeracy\nSkills",
                        color1: Color(0xFF6FCF7C),
                        color2: Color(0xFF4CAF50),
                        icon: Icons.calculate,
                        onPressed: () => debugPrint("Numeracy Skills"),
                      ),
                      MenuButton(
                        title: "Daily Life\nSkills",
                        color1: Color(0xFFFF5C8D),
                        color2: Color(0xFFF44369),
                        icon: Icons.favorite,
                        onPressed: () => debugPrint("Daily Life Skills"),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

///-----------------------------------------------------------
/// ⭐ MENU BUTTON COMPONENT
///-----------------------------------------------------------
class MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color1;
  final Color color2;
  final VoidCallback onPressed;

  const MenuButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color2.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(color: Colors.black38, offset: Offset(2, 3), blurRadius: 5)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///-----------------------------------------------------------
/// ⭐ TRIANGLE DECORATION WIDGET
///-----------------------------------------------------------
class Triangle extends StatelessWidget {
  final Color color;
  final double size;
  final double angle;

  const Triangle({
    super.key,
    required this.color,
    required this.size,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * 3.1415 / 180,
      child: CustomPaint(
        size: Size(size, size),
        painter: TrianglePainter(color),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
