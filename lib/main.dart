import 'package:chat_online/widgets/chat_message.dart';
import 'package:chat_online/widgets/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
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

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

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

  User _currentUser = FirebaseAuth.instance.currentUser;
  final googleSignIn = GoogleSignIn();

  _sendMessage({String text, String imgUrl}){
    FirebaseFirestore.instance.collection("messages").add(
        {
          "text": text,
          "imgUrl": imgUrl,
          "senderName": googleSignIn.currentUser.displayName,
          "senderPhotoUrl": googleSignIn.currentUser.photoUrl,
          "timestamp": Timestamp.now(),
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
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((event) {
      setState(() {
        _currentUser = event;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _currentUser != null ? 'Ola, ${_currentUser.displayName}' : 'Chat App'
          ),
          centerTitle: true,
          elevation: Theme.of(context).platform == TargetPlatform.iOS?
            0.0:4.0,
          actions: _currentUser != null ? [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                await GoogleSignIn().signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('usuário deslogado com sucesso!')
                  )
                );
              }
            ),
          ] : null,
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection("messages")
                    .orderBy('timestamp').snapshots(),
                builder: (context, snapshot){
                  if (!snapshot.hasData) return CircularProgressIndicator();
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
                        itemCount: snapshot.data.docs.length,
                        itemBuilder: (context, index){
                          return ChatMessage(
                            snapshot.data.docs[index].data(),
                            _currentUser.displayName ==
                                snapshot.data.docs[index].data()['senderName']
                          );
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
              child: TextComposer(_sendMessage),
            ),
          ],
        ),
      )
    );
  }
}