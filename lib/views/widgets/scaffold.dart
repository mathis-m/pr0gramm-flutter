import 'package:flutter/material.dart';
import 'package:pr0gramm/views/widgets/app_bar.dart';
import 'package:pr0gramm/views/widgets/drawer.dart';

class MyScaffold extends StatefulWidget {
  final Widget body;
  final String name;

  const MyScaffold({Key key, this.body, this.name}) : super(key: key);

  @override
  _MyScaffoldState createState() => new _MyScaffoldState();
}

class _MyScaffoldState extends State<MyScaffold> {
  bool isSearching = false;

  @override
  Widget build(BuildContext context) {
    var name = ModalRoute.of(context).settings?.name;
    bool isSearchRoute = name == "/search";
    bool isProfileRoute = name == "/profile";

    return NotificationListener<EndSearchNotification>(
      onNotification: onEndSearchNotification,
      child: NotificationListener<StartSearchNotification>(
        onNotification: onStartSearchNotification,
        child: Scaffold(
          backgroundColor: Colors.black45,
          appBar: isSearching ? MySearchBar() : MyAppBar(title: widget.name),
          drawer: isSearchRoute || isProfileRoute ? null : CustomDrawer(),
          body: widget.body,
        ),
      ),
    );
  }

  bool onStartSearchNotification(StartSearchNotification notification) {
    setState(() {
      isSearching = true;
    });
    return true;
  }

  bool onEndSearchNotification(EndSearchNotification notification) {
    setState(() {
      isSearching = false;
    });
    return true;
  }
}

class StartSearchNotification extends Notification {}

class EndSearchNotification extends Notification {}
