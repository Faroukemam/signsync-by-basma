import 'package:flutter/material.dart';
import 'package:signsync/screens/homepage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff045c9a),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    'SignSync',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xfffcf101),
                    ),
                  ),
                ),
              ),
              Text('Developed By Basma'),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}



/*

Image.asset(
              
              'assets/images/splash_image.png', // Ensure this path is correct
              width: 200,
              height: 200,
            ),
*/