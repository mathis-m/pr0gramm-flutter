import 'package:flutter/material.dart';
import 'package:pr0gramm/entities/postInfo.dart';
import 'package:pr0gramm/services/timeFormatter.dart';
import 'package:pr0gramm/services/voteService.dart';
import 'package:pr0gramm/views/widgets/userMark.dart';

import '../../../entities/enums/vote.dart';
import '../../../widgets/inherited.dart';

const authorTextStyle = const TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.bold,
  color: Colors.white,
  letterSpacing: 1,
);

const postTimeTextStyle = const TextStyle(
  fontSize: 8,
  color: Colors.white70,
);

class PostButtons extends StatefulWidget {
  final PostInfo info;

  PostButtons({Key key, this.info}) : super(key: key);

  @override
  _PostButtonsState createState() => _PostButtonsState();
}

class _PostButtonsState extends State<PostButtons> {
  final VoteService _voteService = VoteService();

  void voteItem(Vote vote) {
    if (vote == myVote) {
      if (Vote.favorite != vote) {
        vote = Vote.none;
      } else {
        vote = Vote.up;
      }
    }
    _voteService.voteItem(widget.info.item, vote);
    setState(() {
      myVote = vote;
    });
  }

  Vote myVote;

  @override
  void initState() {
    _voteService.getVoteOfItem(widget.info.item).then((vote) => setState(() {
          myVote = vote;
        }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var loggedIn = GlobalInherited.of(context).isLoggedIn;
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.add_circle_outline),
          color: Colors.white,
          onPressed: loggedIn ? () => voteItem(Vote.up) : null,
          disabledColor: Colors.white30,
        ),
        IconButton(
          color: Colors.white,
          icon: Icon(Icons.remove_circle_outline),
          onPressed: loggedIn ? () => voteItem(Vote.down) : null,
          disabledColor: Colors.white30,
        ),
        IconButton(
          color: Colors.white,
          icon: Icon(Icons.favorite_border),
          onPressed: loggedIn ? () => voteItem(Vote.favorite) : null,
          disabledColor: Colors.white30,
        ),
        Container(
          height: 30.0,
          width: 1.0,
          color: Colors.white30,
          margin: const EdgeInsets.only(left: 10.0, right: 20.0),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  Text(
                    widget.info.item.user,
                    style: authorTextStyle,
                  ),
                  UserMarkWidget(
                    userMark: widget.info.item.mark,
                    radius: 2.5,
                  )
                ],
              ),
              Text(
                formatTime(widget.info.item.created * 1000),
                style: postTimeTextStyle,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        )
      ],
    );
  }
}