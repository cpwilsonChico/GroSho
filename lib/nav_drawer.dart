import 'package:flutter/material.dart';

class NavShelf extends StatelessWidget {
  final String name;
  final Icon icon;
  final String path;

  NavShelf(this.name, this.icon, this.path);

  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      leading: icon,
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, path);
      }
    );
  }
}

class NavDrawer extends StatelessWidget {
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
            padding: EdgeInsets.all(0),
            children: <Widget>[
              DrawerHeader(
                  child: Center(
                      child: Text(
                        'GroSho',
                        style: TextStyle(fontSize: 26, color: Colors.white),
                      )
                  ),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 38, 80, 38),
                  )
              ),
              NavShelf("Home", Icon(Icons.home), "/"),
              NavShelf("Scan", Icon(Icons.scanner), "/scanner"),
              NavShelf("Expenses", Icon(Icons.attach_money), "/budget"),
            ]
        )
    );
  }
}