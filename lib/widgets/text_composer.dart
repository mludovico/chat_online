import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  
  final Function({String text, String imgUrl}) sendMessage;
  
  TextComposer(this.sendMessage);
  
  @override
  _TextComposerState createState() => _TextComposerState(sendMessage);
}

class _TextComposerState extends State<TextComposer> {

  bool _isComposing = false;
  final _textController = TextEditingController();
  final auth = FirebaseAuth.instance;
  final Function({String text, String imgUrl}) sendMessage;

  _TextComposerState(this.sendMessage);
  
  void _reset(){
    setState(() {
      _textController.clear();
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(
          color: Theme.of(context).accentColor
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 8.0
        ),
        decoration: Theme.of(context).platform == TargetPlatform.iOS?
        BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: Colors.grey[200]
                )
            )
        ):null,
        child: Row(
          children: <Widget>[
            Container(
              child: IconButton(
                  icon: Icon(Icons.photo_camera),
                  onPressed: ()async{
                    await _ensureLogedIn();
                    File imgFile = File((await ImagePicker.platform.pickImage(
                        source: ImageSource.camera
                    )).path);
                    print(imgFile.path);
                    if(imgFile == null) return;
                    UploadTask task = FirebaseStorage.instance.ref().child(
                        googleSignIn.currentUser.id.toString() +
                            DateTime.now().millisecondsSinceEpoch.toString()
                    ).putFile(imgFile);
                    TaskSnapshot taskSnapshot = await task.whenComplete(() {});
                    String url = await taskSnapshot.ref.getDownloadURL();
                    sendMessage(imgUrl: url);
                  }
              ),
            ),
            Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration.collapsed(
                      hintText: "Escreva uma mensagem"
                  ),
                  onChanged: (text){
                    setState(() {
                      _isComposing = text.length > 0;
                    });
                  },
                  onSubmitted: (text){
                    _handleSubmitted(text);
                    _reset();
                  },
                )
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 4.0
              ),
              child: Theme.of(context).platform == TargetPlatform.iOS?
              CupertinoButton(
                child: Text("Enviar"),
                onPressed: _isComposing?
                    (){
                  _handleSubmitted(_textController.text);
                  _reset();
                }:
                null,
              ):
              IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _isComposing?
                      (){
                    _handleSubmitted(_textController.text);
                    _reset();
                  }:
                  null
              ),
            )
          ],
        ),
      ),
    );
  }
}