import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {

  bool _isComposing = false;
  final _textController = TextEditingController();
  final googleSignIn = GoogleSignIn();
  final auth = FirebaseAuth.instance;

  void _reset(){
    setState(() {
      _textController.clear();
      _isComposing = false;
    });
  }

  _sendMessage({String text, String imgUrl}){
    FirebaseFirestore.instance.collection("messages").add(
        {
          "text": text,
          "imgUrl": imgUrl,
          "senderName": googleSignIn.currentUser.displayName,
          "senderPhotoUrl": googleSignIn.currentUser.photoUrl
        }
    );
  }

  _handleSubmitted(String text)async{
    await _ensureLogedIn();
    _sendMessage(text: text);
  }

  Future<Null> _ensureLogedIn()async{
    GoogleSignInAccount user = googleSignIn.currentUser;
    if(user == null)
      user = await googleSignIn.signInSilently();
    if(user == null)
      user = await googleSignIn.signIn();
    if(auth.currentUser == null){
      GoogleSignInAuthentication credentials =
      await googleSignIn.currentUser.authentication;
      await auth.signInWithCredential(
          GoogleAuthProvider.credential(
            idToken: credentials.idToken,
            accessToken: credentials.accessToken,
          )
      );
    }
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
                    _sendMessage(imgUrl: url);
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