import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:notification_sample_app/ProjectUtils.dart';
import 'package:cloud_functions/cloud_functions.dart';



void main() => runApp(MyHome());

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {

  String fcmToken = "";
  FirebaseMessaging firebaseMessaging = new FirebaseMessaging();
  final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
    functionName: 'subscribeToTopic',
  );

  @override
  void initState() {
    super.initState();

    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        print('onMessage called: $message');
      },
      onResume: (Map<String, dynamic> message) {
        print('onResume called: $message');
      },
      onLaunch: (Map<String, dynamic> message) {
        print('onLaunch called: $message');
      },
    );

    firebaseMessaging.getToken().then((token){
      fcmToken = token;
      print('FCM Token: $token');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Notifications'),
          centerTitle: true,
        ),
        body: Center(
          child: Container(
              padding: const EdgeInsets.all(10.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: Firestore.instance.collection('topics')
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError)
                    return new Text('Error: ${snapshot.error}');
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return new Text('Loading...');
                    default:
                      return new ListView(
                        children: snapshot.data.documents
                            .map((DocumentSnapshot document) {
                          return GestureDetector(
                            onTap: () async{
                              ProjectUtils.showToast(document.documentID);

                              dynamic resp = await callable.call(<String, dynamic>{
                                'topic_id': document.documentID,
                                'device_token': fcmToken,
                              });
                              print("API Excexption"+resp);
                            },
                            child: new ListTile(
                              leading: Icon(Icons.track_changes),
                              title: Text(document['name']),
                              subtitle: Text(document.documentID),
                            ),
                          );
                        }).toList(),
                      );
                  }
                },
              )),
        ),
      ),
    );
  }
}

