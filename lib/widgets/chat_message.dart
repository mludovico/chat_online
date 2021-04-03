import 'dart:ui';

import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {

  final Map<String, dynamic> data;
  final bool mine;

  ChatMessage(this.data, this.mine);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 10.0
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          !mine ? Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                  data["senderPhotoUrl"],
              ),
            ),
          ) : Container(),
          Expanded(
              child: Column(
                crossAxisAlignment: mine ?
                  CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    data["senderName"],
                    style: Theme.of(context).textTheme.subtitle1,
                    textAlign: mine ? TextAlign.end : TextAlign.start,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 5.0),
                    child: data["imgUrl"] != null?
                    Image.network(data["imgUrl"], width: 250,):
                    Text(data["text"]),
                  )
                ],
              )
          ),
          mine ? Container(
            margin: const EdgeInsets.only(left: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                data["senderPhotoUrl"],
              ),
            ),
          ) : Container(),
        ],
      ),
    );
  }
}
