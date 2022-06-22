import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isolates_or_thread/internet_connectivity.dart';
import 'dart:async';


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Timer? timer;
  int counter = 1;

  ValueNotifier<bool> finalSubscriptionStatus = ValueNotifier(true);
  ValueNotifier<String> imageUrl = ValueNotifier("");
  ValueNotifier<String> developerName = ValueNotifier("");

  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('users').snapshots();


  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 10), (Timer t) async {
      // bool? subscriptionStatus = await _checkDataFromFireBase();

      _usersStream.listen((QuerySnapshot snapshot) async {
        for (var data in snapshot.docs) {
          if(data['full_name'] != null){
            developerName.value = data['full_name'];
          }
          if(data['image_url'] != null){
            imageUrl.value = data['image_url'];
          }
          if(data['subscription'] != null){
            if (kDebugMode) {
              print("Subscription fetch test value will be ${data['subscription']}");
            }
            finalSubscriptionStatus.value = data['subscription'];
          }
        }
      });

      if (kDebugMode) {
        print('Subscription Status checking no : ${counter++} & value is : ${finalSubscriptionStatus.value}');
      }

    });
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: ValueListenableBuilder(
        valueListenable: finalSubscriptionStatus,
        builder: (context, value, child) {
          switch(value){
            case true:
              return WithSubscription(name: developerName,);
            case false:
              return WithoutSubscription(imageUrl: imageUrl,);
            default:
              return WithSubscription(name: developerName,);
          }
        },
      ),
    );
  }
}

class WithoutSubscription extends StatelessWidget {
  const WithoutSubscription({Key? key, required this.imageUrl}) : super(key: key);

  final ValueNotifier<String> imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: ValueListenableBuilder(
        valueListenable: imageUrl,
        builder: (context, imageUrlValue, child) {
          return CachedNetworkImage(
            imageUrl: imageUrlValue.toString(),
            imageBuilder: (context, imageProvider) => Container(
              // height: _height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          );
        },
      ),),
    );
  }

}

class WithSubscription extends StatelessWidget {
  WithSubscription({Key? key, required this.name}) : super(key: key);

  final ValueNotifier<String> name;

  final Stream<QuerySnapshot> _usersStream = FirebaseFirestore.instance
      .collection('users').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: name,
        builder: (context, textValue, child) {
          return Center(
            child: Text(textValue.toString()),
          );
        },
      ),
    );
  }
}


class TestWidget extends StatefulWidget {
  const TestWidget({Key? key}) : super(key: key);

  @override
  TestWidgetState createState() => TestWidgetState();
}

class TestWidgetState extends State<TestWidget> {

  Map _source = {ConnectivityResult.none: false};
  final MyConnectivity _connectivity = MyConnectivity.instance;

  @override
  void initState() {
    super.initState();
    _connectivity.initialise();
    _connectivity.myStream.listen((source) {
      setState(() => _source = source);
    });
  }

  @override
  Widget build(BuildContext context) {
    String status = "Offline";
    switch (_source.keys.toList()[0]) {
      case ConnectivityResult.none:
        status = "Offline";
        break;
      case ConnectivityResult.mobile:
        status = "Mobile: Online";
        break;
      case ConnectivityResult.wifi:
        status = "WiFi: Online";
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Internet")),
      body: Center(child: Text(status)),
      persistentFooterButtons: [
        ElevatedButton(onPressed: (){},child:const Text("Next")),
      ],
    );
  }

  @override
  void dispose() {
    _connectivity.disposeStream();
    super.dispose();
  }
}