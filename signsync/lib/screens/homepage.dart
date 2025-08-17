import 'package:flutter/material.dart';
import 'package:signsync/components/coustomcontainer.dart';
import 'package:signsync/screens/basketcounter.dart';
import 'package:signsync/screens/camera_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff5fa0fb),
      appBar: AppBar(
        title: Text(
          'Toku',
          style: TextStyle(
            fontSize: 25,
            color: Colors.white,
            fontFamily: 'Pacifico',
            //fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepOrange,
      ),
      body: Column(
        children: [
          cat(
            text: 'Member',
            color: Colors.orange,
            OnTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return basket();
                  },
                ),
              );
              print('num tapped');
            },
          ),
          cat(
            text: 'Family Members',
            color: Colors.blue,
            OnTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return CameraScreen();
                  },
                ),
              );
              print('num tapped');
            },
          ),
          cat(text: 'Color', color: Colors.green),
          cat(text: 'Phrases', color: Colors.purple),
          cat(text: 'farouk', color: Colors.redAccent),
        ],
      ),
    );
  }
}
