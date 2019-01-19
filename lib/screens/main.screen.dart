import 'package:flutter/material.dart';
import 'package:little_light/screens/presentation_node_root.screen.dart';


import 'package:little_light/widgets/side_menu/side_menu.widget.dart';

class MainScreen extends StatefulWidget {
  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  Widget currentScreen = PresentationNodeRootScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: new Container(
        child:SideMenuWidget(
          onPageChange: (page){
            this.currentScreen = page;
            setState(() {});
          },
        ),
      ),
      body: currentScreen,
    );
  }

}