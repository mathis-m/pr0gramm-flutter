import 'package:flutter/material.dart';
import 'package:pr0gramm/api/apiClient.dart';
import 'package:pr0gramm/api/dtos/getItemInfoResponse.dart';
import 'package:pr0gramm/api/dtos/getItemsResponse.dart';
import 'package:pr0gramm/api/itemApi.dart';
import 'package:pr0gramm/api/profileApi.dart';
import 'package:pr0gramm/data/sharedPrefKeys.dart';
import 'package:pr0gramm/helper/FutureFlowControl.dart';
import 'package:pr0gramm/widgets/inherited.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'loginView.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future _initFuture;
  var _items = List<Item>();
  Future _workingTask;

  Future initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(SharedPrefKeys.Token) &&
          prefs.containsKey(SharedPrefKeys.MeToken) &&
          prefs.containsKey(SharedPrefKeys.UserName)) {
        final apiClient = ApiClient();

        final token = prefs.getString(SharedPrefKeys.Token);
        final meToken = prefs.getString(SharedPrefKeys.MeToken);
        apiClient.setToken(token, meToken);

        final username = prefs.getString(SharedPrefKeys.UserName);

        final api = ProfileApi();
        final profile = await api.getProfileInfo(name: username, flags: 15);

        MyInherited.of(context).onStatusChange(true, profile);
      }
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<Item> getItem(int index) async {
    final itemApi = ItemApi();

    while (true) {
      try {
        if (index < _items.length) return _items[index];

        if (_workingTask != null) {
          await _workingTask;
          continue;
        }

        int older;
        if (_items.isNotEmpty) older = _items.last.promoted;

        _workingTask = itemApi.getItems(
          promoted: true,
          flags: 9,
          older: older,
        );
        var getItemsResponse = await _workingTask;
        _workingTask = null;

        _items.addAll(getItemsResponse.items);
      } on Exception catch (e) {
        print(e);
      }
    }
  }

  void logOut() {
    final apiClient = ApiClient();
    apiClient.logout();

    MyInherited.of(context).onStatusChange(false, null);
  }

  @override
  Widget build(BuildContext context) {
    if (_initFuture == null) _initFuture = initialize();

    final isLoggedIn = MyInherited.of(context).isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
      ),
      drawer: Drawer(),
      body: Center(
        child: isLoggedIn ? buildProfile() : buildLoginButton(),
      ),
    );
  }

  FutureBuilder buildLoginButton() {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done)
          return RaisedButton(
            child: const Text("Login"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginView()),
              );
            },
          );

        return CircularProgressIndicator();
      },
    );
  }

  Widget buildProfile() {
    var profile = MyInherited.of(context).profile;

    return GridView.builder(
      gridDelegate:
          new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
      itemBuilder: (context, index) {
        return FutureBuilder<Map<String, dynamic>>(
          future: FutureFlowControl()
              .add('item', future: getItem(index))
              .add('info',
                  futureFunc: (map) => ItemApi().getItemInfo(map['item'].id))
              .dependsOn(['item'])
              .run(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Item item = snapshot.data['item'];
              GetItemInfoResponse info = snapshot.data['info'];
              return GestureDetector(
                child:
                    Image.network("https://thumb.pr0gramm.com/${item.thumb}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DetailView(item: item, info: info)),
                  );
                },
              );
            }

            return CircularProgressIndicator();
          },
        );
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Text("Welcome ${profile.user.name}"),
        RaisedButton(
          child: Text("Logout"),
          onPressed: logOut,
        )
      ],
    );
  }
}


class DetailView extends StatefulWidget {
  final Item item;
  final GetItemInfoResponse info;
  final controller = new ScrollController();

  DetailView({Key key, this.item, this.info}) : super(key: key);

  @override
  _DetailViewState createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  VideoPlayerController _controller;

  /// Useful to tweak how fast background image slides when scrolling.
  static const double speedCoefficient = 0.7;

  /// Scroll offset at the moment this widget appeared on the screen
  double initOffset;

  /// Size of the viewport
  double viewportSize;

  /// Offset of background image in percents, must be in range [-100.0, 100.0].
  ///
  /// Offset `0.0` means the images is vertically centered, `-100.0` means
  /// it's top-alligned and `100.0` it's bottom-aligned.
  double imageOffset = -100;

  /// Called for each scroll notification event.
  void _handleScroll() {
    /// Note that this logic is not bulletproof and needs some tweaking.
    /// But hopefully it is good enough to represent the approach.

    /// We first get the delta of current scroll offset to our [initOffset].
    /// This value would normally be less than the [viewportSize].
    /// It can be positive or negative depending on the direction of scroll.
    final double delta = widget.controller.offset - initOffset;

    /// Having [delta] we can calculate the distance travelled as a percentage
    /// of the [viewportSize].
    final int viewportFraction =
        (100 * delta / viewportSize).round().clamp(-100, 100);

    /// Adjust the value by our [speedCoefficient].
    /// We also negate the result here because the image must actually slide
    /// in the oposite direction to scroll.
    final double offset = -1 * speedCoefficient * viewportFraction;

    if (offset != imageOffset) {
      /// Not every scroll notification will result in a different offset so
      /// we can save on repainting a little.
      setState(() {
        imageOffset = offset;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initOffset = widget.controller.offset;
    viewportSize = widget.controller.position.viewportDimension;
    widget.controller.addListener(_handleScroll);
    if (widget.item.image.endsWith(".mp4"))
      _controller = VideoPlayerController.network(
          "https://vid.pr0gramm.com/${widget.item.image}")
        ..initialize().then((_) {
          _controller.play();
          _controller.setLooping(true);
          setState(() {});
        });
  }

  @override
  Widget build(BuildContext context) {
    /// Adjust standard [Alignment.center] by the value of [imageOffset].
    double y = imageOffset / 100;
    var alignment = Alignment.center.add(new Alignment(0.0, y));
    if (widget.item.image.endsWith(".mp4"))
      return Scaffold(
        backgroundColor: Colors.black45,
        appBar: AppBar(
          title: Text("Top"),
        ),
        body: Center(
          child: Stack(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  if (_controller.value.isPlaying)
                    _controller.pause();
                  else
                    _controller.play();
                },
                child: _controller?.value?.initialized ?? false
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : CircularProgressIndicator(),
              ),
            ],
          ),
        ),
      );

    return Scaffold(
      backgroundColor: Colors.black45,
      appBar: AppBar(
        title: Text("Post"),
      ),
      body: Image.network(
        "https://img.pr0gramm.com/${widget.item.image}",
        alignment: alignment,
      ),
    );
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleScroll);
    widget.controller?.dispose();
    _controller?.dispose();
    super.dispose();
  }
}

class CommentView extends StatefulWidget {
  CommentView({Key key}) : super(key: key);

  @override
  _CommentViewState createState() {
    return _CommentViewState();
  }
}

class _CommentViewState extends State<CommentView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return null;
  }
}
