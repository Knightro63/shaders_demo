import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:shaders_demo/shader_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ShaderHandler shaderHandler;
  late double dpr;
  late Size size;
  bool ready = false;

  void animate() async {
    Future.delayed(const Duration(milliseconds: 50), () async {
      if (shaderHandler.textures.isNotEmpty) {
        shaderHandler.textures.first.activate();
        shaderHandler.update();
      }
      animate();
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      ready = true;
      shaderHandler = ShaderHandler(
        size.width.toInt(),
        size.height.toInt(),
        dpr,
        (){setState(() {});}
      );
      shaderHandler.setup(context);
      animate();
    });
    super.initState();
  }

  @override
  void dispose(){
    shaderHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    dpr = MediaQuery.of(context).devicePixelRatio;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: 
          (kIsWeb) ?ready && shaderHandler.textures.isNotEmpty?HtmlElementView(viewType: shaderHandler.textures.first.textureId.toString()):Container()
          :ready && shaderHandler.textures.isNotEmpty?Texture(textureId: shaderHandler.textures.first.textureId):Container()
      )
    );
  }
}
