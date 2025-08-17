import 'package:flutter/material.dart';

Text mass = const Text(
  'Points Counter!!',
  style: TextStyle(
    fontSize: 33,
    color: Colors.white,
    fontFamily: 'Pacifico',
    //fontWeight: FontWeight.bold,
  ),
);

enum PointState { point, twoPoints, threePoints, reset }

enum Team { teamA, teamB }

class basket extends StatefulWidget {
  @override
  State<basket> createState() => _basketState();
}

class _basketState extends State<basket> {
  int teamAPoints = 0;

  int teamBPoints = 0;

  void setpoint(Team team, PointState pointState) {
    setState(() {
      switch (team) {
        case Team.teamA:
          switch (pointState) {
            case PointState.point:
              teamAPoints++;
              break;
            case PointState.twoPoints:
              teamAPoints += 2;
              break;
            case PointState.threePoints:
              teamAPoints += 3;
              break;
            case PointState.reset:
              teamAPoints = 0;
              break;
          }
          break;
        case Team.teamB:
          switch (pointState) {
            case PointState.point:
              teamBPoints++;
              break;
            case PointState.twoPoints:
              teamBPoints += 2;
              break;
            case PointState.threePoints:
              teamBPoints += 3;
              break;
            case PointState.reset:
              teamBPoints = 0;
              break;
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Row(
          children: [
            Spacer(flex: 1),
            CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xff8aa1cd),
              child: CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage('images/background02.jpeg'),
              ),
            ),
            Spacer(flex: 1),
            mass,
            Spacer(flex: 1),
          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Spacer(flex: 1),
            Row(
              children: [
                Spacer(flex: 1),
                Column(
                  children: [
                    const Text(
                      'Team A',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$teamAPoints',
                      style: const TextStyle(
                        fontSize: 64,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () {
                          setpoint(Team.teamA, PointState.point);
                        },
                        child: const Text('Add Point'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepOrange,
                          minimumSize: const Size(120, 50),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () {
                          setpoint(Team.teamA, PointState.twoPoints);
                        },
                        child: const Text('Add 2 Point'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepOrange,
                          minimumSize: const Size(120, 50),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () {
                          setpoint(Team.teamA, PointState.threePoints);
                        },
                        child: const Text('Add 3 Point'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepOrange,
                          minimumSize: const Size(120, 50),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Spacer(flex: 1),
                VerticalDivider(
                  color: Colors.black,
                  thickness: 2,
                  indent: 20,
                  endIndent: 20,
                ),
                Spacer(flex: 1),
                Column(
                  children: [
                    const Text(
                      'Team B',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$teamBPoints',
                      style: const TextStyle(
                        fontSize: 64,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () {
                          setpoint(Team.teamB, PointState.point);
                        },
                        child: const Text('Add Point'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepOrange,
                          minimumSize: const Size(120, 50),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () {
                          setpoint(Team.teamB, PointState.twoPoints);
                        },
                        child: const Text('Add 2 Point'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepOrange,
                          minimumSize: const Size(120, 50),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      child: ElevatedButton(
                        onPressed: () {
                          setpoint(Team.teamB, PointState.threePoints);
                        },
                        child: const Text('Add 3 Point'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.deepOrange,
                          minimumSize: const Size(120, 50),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Spacer(flex: 1),
              ],
            ),
            Spacer(flex: 1),

            Divider(
              color: Colors.deepOrange,
              thickness: 2,
              indent: 20,
              endIndent: 20,
            ),
            Spacer(flex: 1),
            ElevatedButton(
              onPressed: () {
                setpoint(Team.teamA, PointState.reset);
                setpoint(Team.teamB, PointState.reset);
              },
              child: const Text('Reset Points'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepOrange,
                minimumSize: const Size(120, 50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
            ),
            Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
