import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

void main(){
  Firestore.instance.collection("teste").document("teste").setData({"teste":"teste"});
  runApp(myApp());
}

ThemeData kIOSTheme = ThemeData(
    primarySwatch: Colors.orange,
    primaryColor: Colors.grey[400],
    primaryColorBrightness: Brightness.light
);

ThemeData kDeafultTheme = ThemeData(
    primarySwatch: Colors.purple,
    accentColor: Colors.orangeAccent[400]
);

final googleSignIn = GoogleSignIn();
final auth = FirebaseAuth.instance;

Future<Null> _ensureLogedIn()async{
  GoogleSignInAccount user = googleSignIn.currentUser;
  if(user == null)
    user = await googleSignIn.signInSilently();
  if(user == null)
    user = await googleSignIn.signIn();
  if(await auth.currentUser() == null){
    GoogleSignInAuthentication credentials = await googleSignIn.currentUser.authentication;
    await auth.signInWithCredential(
      GoogleAuthProvider.getCredential(
        idToken: credentials.idToken, accessToken: credentials.accessToken
      )
    );
  }
}

_handleSubmitted(String text)async{
  await _ensureLogedIn();
  _sendMessage(text: text);
}

_sendMessage({String text, String imgUrl}){
  Firestore.instance.collection("messages").add(
    {
      "text": text,
      "imgUrl": imgUrl,
      "senderName": googleSignIn.currentUser.displayName,
      "senderPhotoUrl": googleSignIn.currentUser.photoUrl
    }
  );
}

class myApp extends StatefulWidget {
  @override
  _myAppState createState() => _myAppState();
}

class _myAppState extends State<myApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Chat Online",
      debugShowCheckedModeBanner: false,
      theme: Theme.of(context).platform == TargetPlatform.iOS?
        kIOSTheme:kDeafultTheme,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Chat Online"),
          centerTitle: true,
          elevation: Theme.of(context).platform == TargetPlatform.iOS?
            0.0:4.0,
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder(
                stream: Firestore.instance.collection("messages").snapshots(),
                builder: (context, snapshot){
                  switch(snapshot.connectionState){
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                      break;
                    default:
                      return ListView.builder(
                        reverse: false,
                        itemCount: snapshot.data.documents.length,
                        itemBuilder: (context, index){
                          return ChatMessage(snapshot.data.documents[index].data);
                        }
                      );
                  }
                }
              )
            ),
            Divider(height: 1.0,),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: TextComposer(),
            ),
          ],
        ),
      )
    );
  }
}

class TextComposer extends StatefulWidget {
  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  bool _isComposing = false;
  final _textController = TextEditingController();

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
                      File imgfile = await ImagePicker.pickImage(
                        source: ImageSource.camera
                      );
                      print(imgfile.path);
                      if(imgfile == null) return;
                      StorageUploadTask task = FirebaseStorage.instance.ref().child(
                        googleSignIn.currentUser.id.toString() +
                          DateTime.now().millisecondsSinceEpoch.toString()
                      ).putFile(imgfile);
                      StorageTaskSnapshot taskSnapshot = await task.onComplete;
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

class ChatMessage extends StatelessWidget {
  final Map<String, dynamic> data;
  ChatMessage(this.data);
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
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                data["senderPhotoUrl"]
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data["senderName"],
                  style: Theme.of(context).textTheme.subhead,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: data["imgUrl"] != null?
                    Image.network(data["imgUrl"]):
                    Text(data["text"]),
                )
              ],
            )
          )
        ],
      ),
    );
  }
}
