import 'package:camera/camera.dart';
import 'package:face_mask_detection/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:tflite/tflite.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraImage cameraImage;
  late CameraController cameraController;
  bool isWoking = false;
  String result = '';

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
      cameraController.startImageStream((imageFromStream) => {
            if (!isWoking)
              {
                isWoking = true,
                cameraImage = imageFromStream,
                runModelOnStreamFrames(),
              }
          });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/model/model.tflite",
        labels: "assets/model/labels.txt");
  }

  runModelOnStreamFrames() async {
    if (cameraImage != null) {
      var recognitions = await Tflite.runModelOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        imageMean: 127.5,
        rotation: 90,
        numResults: 1,
        threshold: 0.1,
        asynch: true,
      );
      result = "";

      for (var response in recognitions!) {
        result += response["label"] + "\n";
      }

      setState(() {
        result;
      });

      isWoking = false;
    }
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Text(result, style: TextStyle(color: Colors.white, backgroundColor: Colors.black54, ),textAlign: TextAlign.center,),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(children: [
        Positioned(
            top: 0,
            left: 0,
            width: size.width,
            height: size.height - 100,
            child: (!cameraController.value.isInitialized)
                ? Container()
                : AspectRatio(
                    aspectRatio: cameraController.value.aspectRatio,
                    child: CameraPreview(cameraController),
                  )),
      ]),
    );
  }
}
