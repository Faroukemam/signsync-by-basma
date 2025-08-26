import 'package:flutter/material.dart';
import 'package:signsync/components/coustomcontainer.dart';
import 'package:signsync/screens/basketcounter.dart';
import 'package:signsync/screens/camera_screen.dart';
import 'package:signsync/screens/camera_screen_f&r.dart';
import 'package:signsync/screens/cambot.dart';
import 'package:signsync/screens/cambot1.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff772F1A),
      appBar: AppBar(
        title: Row(
          children: [
            CircleWidget(
              imagePath: 'assets/images/deaflogo.png',
              frameRadius: 27,
              imageRadius: 25,
              frameColor: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              'SignSync',
              style: TextStyle(
                fontSize: 25,
                color: Colors.white,
                fontFamily: 'Pacifico',
                //fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xff585123),
      ),
      body: Column(
        children: [
          cat(
            text: 'Text to Sign',
            color: Color(0xffEEC170),
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
            text: 'Sign To Text',
            color: Color(0xffF2A65A),
            OnTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return FCameraScreen();
                  },
                ),
              );
            },
          ),
          cat(text: 'Speech To Sign', color: Color(0xffF58549)),
          //cat(text: 'Phrases', color: Colors.purple),
          //cat(text: 'farouk', color: Colors.redAccent),
        ],
      ),
    );
  }
}
