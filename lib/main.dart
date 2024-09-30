import 'package:eclipse/pages/home/forecast.dart';
import 'package:eclipse/pages/home/location.dart';
import 'package:flutter/material.dart';
import 'pages/home/home.dart';

void main() {
  runApp(const EclipseApp());
}

class EclipseApp extends StatelessWidget {
  const EclipseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
            bottom: const TabBar(
              tabs: [
                Tab(
                  text: 'Home',
                ),
                Tab(text: 'Forecast'),
                Tab(text: 'Location'),
              ],
            ),
          ),
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [const HomePage(), const ForecastPage(), LocationPage()],
          ),
        ),
      ),
    );
  }
}
