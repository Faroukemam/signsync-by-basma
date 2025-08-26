import 'package:flutter/material.dart';

class CircleWidget extends StatelessWidget {
  const CircleWidget({
    Key? key,
    required this.imagePath,
    this.frameRadius = 30,
    this.imageRadius = 28,
    this.frameColor = Colors.white,
    this.onTap,
  }) : super(key: key);

  final String imagePath;
  final double frameRadius;
  final double imageRadius;
  final Color frameColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: frameRadius,
      backgroundColor: frameColor,
      child: CircleAvatar(
        radius: imageRadius,
        backgroundImage: AssetImage(imagePath),
      ),
    );

    // If onTap is provided, wrap in GestureDetector
    return onTap != null
        ? GestureDetector(onTap: onTap, child: avatar)
        : avatar;
  }
}

/*
class CircleWidge extends StatelessWidget {
  const CircleWidge({this.image_path, this.faram_radius = 30,
   this.Image_radius = 28, this.farme_color = Colors.white});

  final String? image_path;
  final double faram_radius;
  final double image_radius;
  final Color farme_color;


  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
                radius: faram_radius,
                backgroundColor: farme_color,
                child: CircleAvatar(
                  radius: image_radius,
                  backgroundImage: AssetImage(image_path!),
                ),
              ),;
  }
}
*/
class CustomContainer extends StatelessWidget {
  CustomContainer({this.text, this.color, this.image_path, this.OnTap});
  String? text;
  Color? color;
  String? image_path;
  Function()? OnTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: OnTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        width: double.infinity,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 16),
        height: 60,
        child: /*Text(
          text!,
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pacifico',
          ),
        ),*/ Row(
          children: [
            Image.asset(image_path!, width: 30, height: 30),
            SizedBox(width: 10),
            Text(
              text!,
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                //fontWeight: FontWeight.bold,
                fontFamily: 'Pacifico',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        height: 100,
        child: Row(
          children: [
            CircleWidget(imagePath: 'assets/images/background01.jpeg'),
            SizedBox(width: 10),
            Text(
              text!,
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                //fontWeight: FontWeight.bold,
                fontFamily: 'Pacifico',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CatTile extends StatelessWidget {
  const CatTile({
    Key? key,
    required this.text,
    required this.color,
    required this.imagePath,
    this.onTap,
  }) : super(key: key);

  final String text;
  final Color color;
  final String imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget tile = Container(
      decoration: BoxDecoration(
        color: color,
        //borderRadius: BorderRadius.circular(12),
      ),
      width: double.infinity,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          CircleWidget(imagePath: imagePath),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontFamily: 'Pacifico',
            ),
          ),
        ],
      ),
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: tile) : tile;
  }
}
