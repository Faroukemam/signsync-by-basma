import 'package:flutter/material.dart';

class cat extends StatelessWidget {
  cat({this.text, this.color, this.OnTap});
  String? text;
  Color? color;
  Function()? OnTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: OnTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          //borderRadius: BorderRadius.circular(10),
        ),
        width: double.infinity,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 16),
        height: 60,
        child: Text(
          text!,
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            //fontWeight: FontWeight.bold,
            fontFamily: 'Pacifico',
          ),
        ),
      ),
    );
  }
}
