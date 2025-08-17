//import 'package:flutter/cupertino.dart'
import 'package:flutter/material.dart';
import 'package:signsync/screens/homepage.dart';
import 'package:signsync/screens/basketcounter.dart';

void main() {
  runApp(tokuApp());
}

class tokuApp extends StatelessWidget {
  const tokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SignSync',
      home: HomePage(),
    );
  }
}

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
      ),
    );
  }
}

class becard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'SignSync',
            style: TextStyle(
              fontSize: 25,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xff133b80),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                print('Notifications Pressed!');
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                print('Settings Pressed!');
              },
            ),
          ],
        ),
        backgroundColor: Color(0xff133b80),
        body: Center(
          child: Column(
            children: [
              Spacer(flex: 2),
              CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xff8aa1cd),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('images/background02.jpeg'),
                ),
              ),
              Spacer(flex: 2),
              Text(
                'Hello, Farouk!',
                style: TextStyle(
                  fontSize: 33,
                  fontFamily: 'Pacifico',
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              Text(
                'Mechatronics Engineer',
                style: TextStyle(
                  fontSize: 20,
                  color: const Color.fromARGB(255, 105, 100, 100),
                ),
              ),
              Divider(
                color: Color.fromARGB(255, 255, 255, 255),
                thickness: 1,
                indent: 50,
                endIndent: 50,
                height: 4,
              ),
              //Spacer(flex: 2),
              Padding(
                padding: EdgeInsets.all(16),
                child: Container(
                  // width: 300,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Spacer(flex: 1),
                      Icon(
                        Icons.phone,
                        size: 30,
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                      Spacer(flex: 1),
                      Text(
                        '+20 100 000 0000',
                        style: TextStyle(
                          fontSize: 30,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.all(16),

                child: Container(
                  // width: 300,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Spacer(flex: 1),
                      Icon(
                        Icons.email,
                        size: 30,
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                      Spacer(flex: 1),
                      Text(
                        'farouk.waked@must.edu.eg',
                        style: TextStyle(
                          fontSize: 20,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.all(16),
                color: Color.fromARGB(255, 255, 255, 255),
                child: ListTile(
                  leading: Icon(Icons.web, color: Colors.blue),
                  title: Text(
                    'www.farouk-waked.com',
                    style: TextStyle(color: Colors.blue),
                  ),
                  onTap: () {
                    print('Website Pressed!');
                  },
                ),
              ),
              ListTile(
                leading: Icon(Icons.location_on, color: Colors.white),
                title: Text(
                  'Cairo, Egypt',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class sign extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xfffffefe),
        body: Center(
          child: Image(image: AssetImage('images/background01.jpeg')),
        ),
      ),
    );
  }
}
/*
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'SignSync',
            style: TextStyle(
              fontSize: 25,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.green,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                print('Notifications Pressed!');
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                print('Settings Pressed!');
              },
            ),
          ],
        ),
        body: Center(child: mass),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            print('Floating Action Button Pressed!');
          },
          child: const Icon(Icons.add),
          backgroundColor: Colors.green,
        ),
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              IconButton(icon: Icon(Icons.home), onPressed: null),
              IconButton(icon: Icon(Icons.search), onPressed: null),
              IconButton(icon: Icon(Icons.settings), onPressed: null),
            ],
          ),
        ),
      ),
    ),
  );
}
*/


/* ClipRRect(
              borderRadius: BorderRadius.circular(200),
              child: Image.asset('images/background01.jpeg',
              width: 305,
              ),
            ),*/