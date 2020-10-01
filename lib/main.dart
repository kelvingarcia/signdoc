import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart';
import 'package:http_interceptor/http_interceptor.dart';

void main() async {
  var imagem = await RequisicoesBackEnd.teste();
  runApp(
    MyApp(
      imagem: imagem,
    ),
  );
}

class MyApp extends StatelessWidget {
  final Imagem imagem;

  MyApp({this.imagem});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(
        title: 'Flutter Demo Home Page',
        imagem: this.imagem,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final Imagem imagem;

  MyHomePage({Key key, this.title, this.imagem}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey _globalKey = GlobalKey();
  List<Offset> _points = <Offset>[];
  double xPosition = 100;
  double yPosition = 100;

  double gdHeight = 150;
  double gdWidth = 150;

  void navegarParaAssinatura() async {
    final List<Offset> pointsFromAssinatura = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Assinatura(),
      ),
    );
    var reduceMaxDx = pointsFromAssinatura.reduce((value, element) {
      if (element != null) {
        if (value.dx > element.dx) {
          return value;
        } else {
          return element;
        }
      } else {
        return value;
      }
    });
    var reduceMinDx = pointsFromAssinatura.reduce((value, element) {
      if (element != null) {
        if (value.dx < element.dx) {
          return value;
        } else {
          return element;
        }
      } else {
        return value;
      }
    });
    var reduceMaxDy = pointsFromAssinatura.reduce((value, element) {
      if (element != null) {
        if (value.dy > element.dy) {
          return value;
        } else {
          return element;
        }
      } else {
        return value;
      }
    });
    var reduceMinDy = pointsFromAssinatura.reduce((value, element) {
      if (element != null) {
        if (value.dy < element.dy) {
          return value;
        } else {
          return element;
        }
      } else {
        return value;
      }
    });
    List<Offset> pointsNew = List();
    var valorReduzir = reduceMinDx.dx;
    pointsFromAssinatura.forEach((element) {
      if (element != null) {
        pointsNew.add(Offset(element.dx - valorReduzir, element.dy));
      } else {
        pointsNew.add(element);
      }
    });
    setState(() {
      _points = pointsNew;
      gdWidth = reduceMaxDx.dx - reduceMinDx.dx;
      gdHeight = reduceMaxDy.dy - reduceMinDy.dy;
    });
  }

  void _capturePng() async {
    try {
      print('inside');
      RenderRepaintBoundary boundary =
          _globalKey.currentContext.findRenderObject();
      await Future.delayed(const Duration(seconds: 3));
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData.buffer.asUint8List();
      var bs64 = base64Encode(pngBytes);
      print(pngBytes);
      print(bs64);
      setState(() {});
      var s = await RequisicoesBackEnd.postTeste(ImagemPost(bs64));
      print(s);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: InteractiveViewer(
          panEnabled: false,
          minScale: 0.5,
          maxScale: 4,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => navegarParaAssinatura(),
                child: Image.memory(widget.imagem.imagem),
              ),
              Positioned(
                top: yPosition,
                left: xPosition,
                height: gdHeight,
                width: gdWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(width: 2, color: Colors.grey),
                  ),
                  child: GestureDetector(
                    onPanUpdate: (tapInfo) {
                      setState(() {
                        xPosition += tapInfo.delta.dx;
                        yPosition += tapInfo.delta.dy;
                      });
                    },
                    child: CustomPaint(
                      painter: Signature(points: _points),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
              // Container(
              //   child: GestureDetector(
              //     onPanUpdate: (DragUpdateDetails details) {
              //       setState(() {
              //         RenderBox object = context.findRenderObject();
              //         Offset _localPosition =
              //             object.localToGlobal(details.localPosition);
              //         _points = List.from(_points)..add(_localPosition);
              //       });
              //     },
              //     onPanEnd: (DragEndDetails details) => _points.add(null),
              //     child: CustomPaint(
              //       painter: Signature(points: _points),
              //       size: Size.infinite,
              //     ),
              //   ),
              // ),
            ],
          ),
        ), // This trailing comma makes auto-formatting nicer for build methods.
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.send),
          onPressed: () => _capturePng(),
        ),
      ),
    );
  }
}

class Assinatura extends StatefulWidget {
  @override
  _AssinaturaState createState() => _AssinaturaState();
}

class _AssinaturaState extends State<Assinatura> {
  List<Offset> _points = <Offset>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Demo Home Page'),
      ),
      body: Container(
        child: GestureDetector(
          onPanUpdate: (DragUpdateDetails details) {
            setState(() {
              RenderBox object = context.findRenderObject();
              Offset _localPosition =
                  object.localToGlobal(details.localPosition);
              debugPrint(details.localPosition.dx.toString());
              _points = List.from(_points)..add(_localPosition);
            });
          },
          onPanEnd: (DragEndDetails details) => _points.add(null),
          child: CustomPaint(
            painter: Signature(points: _points),
            size: Size.infinite,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.edit),
        onPressed: () => Navigator.pop(context, _points),
      ),
    );
  }
}

class LoggingInterceptor implements InterceptorContract {
  @override
  Future<RequestData> interceptRequest({RequestData data}) async {
    print('Request');
    print('url: ${data.baseUrl}');
    print('headers: ${data.headers}');
    print('body: ${data.body}');
    return data;
  }

  @override
  Future<ResponseData> interceptResponse({ResponseData data}) async {
    print('Response');
    print('status code: ${data.statusCode}');
    print('headers: ${data.headers}');
    print('body: ${data.body}');
    return data;
  }
}

final Client client = HttpClientWithInterceptor.build(
  interceptors: [LoggingInterceptor()],
);

class RequisicoesBackEnd {
  static Future<Imagem> teste() async {
    // var request = await HttpRequest.request('http://localhost:8080/imagem',
    //     method: 'GET',
    //     requestHeaders: {
    //       'Content-Type': 'application/json',
    //       'Access-Control-Allow-Origin': '*'
    //     });
    var request = await client.get('http://192.168.0.5:8080/imagem');
    final Map<String, dynamic> decodedJson = jsonDecode(request.body);
    String imagemString = decodedJson['imagem'];
    var imagemBytes = base64Decode(imagemString);
    return Imagem(imagemBytes);
  }

  static Future<String> postTeste(ImagemPost imagemPost) async {
    // var request = await HttpRequest.request(
    //     'http://localhost:8080/imagemFromFront',
    //     method: 'POST',
    //     sendData: jsonEncode(imagemPost.toJson()),
    //     requestHeaders: {
    //       'Content-Type': 'application/json',
    //       'Access-Control-Allow-Origin': '*'
    //     });
    var request = await client.post(
      'http://192.168.0.7:8080/imagemFromFront',
      headers: {'Content-type': 'application/json'},
      body: jsonEncode(imagemPost.toJson()),
    );
    return request.body;
  }
}

class Imagem {
  final Uint8List imagem;

  Imagem(this.imagem);
}

class ImagemPost {
  final String imagem;

  ImagemPost(this.imagem);

  Map<String, dynamic> toJson() => {'imagem': imagem};
}

class Signature extends CustomPainter {
  List<Offset> points;

  Signature({this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(Signature oldDelegate) => oldDelegate.points != points;
}
