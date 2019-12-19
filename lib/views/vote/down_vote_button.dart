import 'package:flutter/material.dart';
import 'package:pr0gramm/constants/vote_constants.dart';
import 'package:pr0gramm/entities/enums/vote_button_type.dart';
import 'package:pr0gramm/services/vote_animation_service.dart';
import 'package:pr0gramm/views/vote/vote_button.dart';
import 'package:pr0gramm/views/vote/vote_button_animation_integration.dart';
import 'package:pr0gramm/views/vote/vote_button_rotate_animation.dart';

class DownVoteButton extends VoteButton {
  DownVoteButton({
    Key key,
    @required VoteAnimationService animationService,
    bool disabled,
  }) : super(
            key: key,
            type: VoteButtonType.down,
            disabled: disabled,
            animationService: animationService);

  @override
  _DownVoteButtonState createState() {
    return _DownVoteButtonState();
  }
}

class _DownVoteButtonState extends State<DownVoteButton>
    with
        TickerProviderStateMixin,
        VoteButtonAnimationIntegration<DownVoteButton>,
        VoteButtonRotateAnimation<DownVoteButton> {
  @override
  void initState() {
    super.initState();
    widget.animationService.addButtonStateListener(widget.type, onStateChange);
  }

  @override
  Color getColorByAnimation(VoteAnimation voteAnimation) {
    var color = super.getColorByAnimation(voteAnimation);
    if (color == votedColor) {
      return downVotedColor;
    }
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return buildRotatingButton(
        button: IconButton(
      icon: Icon(Icons.remove_circle_outline),
      color: color,
      onPressed: !widget.disabled
          ? () => widget.animationService.voteItem(widget.type.toVote())
          : null,
      disabledColor: disabledColor,
    ));
  }
}