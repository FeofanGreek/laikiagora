import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'dart:io';
import 'package:share/share.dart';


String Url = 'https://laiki.koldashev.ru';
bool outApp = false;
void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()));

WebViewController _myController;


Geolocator _geolocator;
Position _position;
var counter = 1;

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();

}

class _HomePageState extends State<HomePage> {
  Map _source = {ConnectivityResult.none: false};
  MyConnectivity _connectivity = MyConnectivity.instance;

  //проверяем наличе разрешения на доступ к местоположению
  void checkPermission() {

    Future<Position> _determinePosition() async {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permantly denied, we cannot request permissions.');
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return Future.error(
              'Location permissions are denied (actual value: $permission).');
        }
      }

      return await Geolocator.getCurrentPosition();
    }

  }

  // обновляем данные о местоположении
  void updateLocation() async {
    try {
      Position newPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high)
          .timeout(new Duration(seconds: 5));
      setState(() {
        _position = newPosition;
        counter++;
        _myController.evaluateJavascript('lats=${_position != null ? _position.latitude.toString() : '0'}; lngs=${_position != null ? _position.longitude.toString() : '0'}; setCoords();');
        //print('Геопозиция обновлена Latitude: ${_position != null ? _position.latitude.toString() : '0'},'
        //    ' Longitude: ${_position != null ? _position.longitude.toString() : '0'}"');
        //_myController.evaluateJavascript('lats=37.958410; lngs=23.763210; setCoords();'); //для скриншотов
        if(counter == 2 ){_myController.evaluateJavascript('javascript:initialize();');}


      });
    } catch (e) {
      //print('Error: ${e.toString()}');
    }
  }


  Timer timer;

  @override
  void initState() {
    super.initState();
    _connectivity.initialise();
    _connectivity.myStream.listen((source) {
      setState(() => _source = source);
    });
    // запускаем и насраиваем доступ к местоположению
    _geolocator = Geolocator();
    LocationOptions locationOptions = LocationOptions(
        accuracy: LocationAccuracy.high, distanceFilter: 1);

    checkPermission();
    timer = new Timer.periodic(Duration(seconds: 10), (timer) {
    updateLocation();
    });

  }


  @override
  Widget build(BuildContext context) {

    String string = "Λαϊκή Αγορά";

    switch (_source.keys.toList()[0]) {
      case ConnectivityResult.none:
        string = "NO Internet connection!";
        return Scaffold(
          backgroundColor: Color(0xFFffffff),
          appBar:AppBar(
            elevation: 0.0,
            title: Image.asset('images/icon.jpg',  height: 50, fit:BoxFit.fill),
            centerTitle: true,
            backgroundColor: Color(0xFFffffff),
            brightness: Brightness.light,


          ),
          body: Center(child: Text("$string", style: TextStyle(fontSize: 36),textAlign: TextAlign.center,)),

        );
        break;
      case ConnectivityResult.mobile:
        string = "Mobile: Online";
        return MyWebView(selectedUrl: Url);
        break;
      case ConnectivityResult.wifi:
        string = "WiFi: Online";
        return MyWebView(selectedUrl: Url);
        break;
    }
  }

  @override
  void dispose() {
    _connectivity.disposeStream();
    timer.cancel();
    super.dispose();
  }
}


//запускаем сайт
class MyConnectivity {
  MyConnectivity._internal();
  static final MyConnectivity _instance = MyConnectivity._internal();
  static MyConnectivity get instance => _instance;
  Connectivity connectivity = Connectivity();
  StreamController controller = StreamController.broadcast();
  Stream get myStream => controller.stream;

  void initialise() async {
    ConnectivityResult result = await connectivity.checkConnectivity();
    _checkStatus(result);
    connectivity.onConnectivityChanged.listen((result) {
      _checkStatus(result);
    });
  }

  void _checkStatus(ConnectivityResult result) async {
    bool isOnline = false;
    try {
      final result = await InternetAddress.lookup('https://laiki.koldashev.ru');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isOnline = true;
      } else
        isOnline = false;
    } on SocketException catch (_) {
      isOnline = false;
    }
    controller.sink.add({result: isOnline});
  }

  void disposeStream() => controller.close();
}

class MyWebView extends StatelessWidget {
  String selectedUrl;
  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();


  MyWebView({
    @required this.selectedUrl,
  });


  //создаем тело виджета
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: Color(0xFFffffff),
        appBar:AppBar(
          elevation: 0.0,
          title: Image.asset('images/icon.jpg',  height: 50, fit:BoxFit.fill),
          centerTitle: true,
          backgroundColor: Color(0xFFffffff),
          brightness: Brightness.light,
          /*leading: Container(
            child: Material(
              color: Colors.white, // button color
              child: InkWell(
                splashColor: Colors.green, // splash color
                onTap: () {
                  if(!outApp){
                    outApp = true;
                    _myController.loadUrl('https://google.com');
                    //print('идем в лайки');

                  } else
                  {outApp = false;
                  _myController.loadUrl('https://laiki.koldashev.ru/');
                  }
                }, // button pressed
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    !outApp?Icon(Icons.web, size: 18.0, color: Colors.black):Icon(Icons.home, size: 18.0, color: Colors.black), // icon
                    !outApp?Text("Site", style: TextStyle(color: Colors.black87)):Text("Home", style: TextStyle(color: Colors.black87)), // text
                  ],
                )
              ),
            ),
          ),*/
          actions: <Widget>[
            Container(
              margin: EdgeInsets.fromLTRB(0,0,10,0),
              child: Material(
                color: Colors.white, // button color
                child: InkWell(
                  splashColor: Colors.green, // splash color
                  onTap: () {
                    final RenderBox box = context.findRenderObject();
                    Share.share('https://play.google.com/store/apps/details?id=ru.koldashev.laikiagora',
                        subject: 'MobileApp Λαϊκή Αγορά',
                        sharePositionOrigin:
                        box.localToGlobal(Offset.zero) &
                        box.size);
                  }, // button pressed
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.ios_share, size: 18.0, color: Colors.black), // icon
                      Text("Share", style: TextStyle(color: Colors.black87)), // text
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: WebView(
            initialUrl: selectedUrl,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller.complete(webViewController);
              _myController = webViewController;

            },
            onPageFinished: (url){
              _position != null ?_myController.evaluateJavascript('lats=${_position != null ? _position.latitude.toString() : '0'}; lngs=${_position != null ? _position.longitude.toString() : '0'}; setCoords();'):_myController.evaluateJavascript('lats=37.971880064647095; lngs=23.725922301448474; setCoords();');
              //_myController.evaluateJavascript('lats=37.958410; lngs=23.763210; setCoords();'); //для скриншотов
            }
        ));

  }

}