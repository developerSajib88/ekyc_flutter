import 'dart:developer';
import 'dart:io';

import 'package:ekyc/view/face_detection_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class RecognizerScreen extends StatefulWidget {
  final File frontPart;
  final File backPart;
  const RecognizerScreen({super.key,required this.frontPart, required this.backPart});

  @override
  State<RecognizerScreen> createState() => _RecognizerScreenState();
}

class _RecognizerScreenState extends State<RecognizerScreen> {

  ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);
  ValueNotifier<bool> isNotNIDCard = ValueNotifier<bool>(false);
  ValueNotifier<Map<String,String>?> data = ValueNotifier<Map<String,String>?>(null);
  ValueNotifier<String?> issueDate = ValueNotifier<String?>(null);
  ValueNotifier<String?> mrzNumber = ValueNotifier<String?>(null);
  ValueNotifier<File?> nidFace = ValueNotifier<File?>(null);

  // Future<void> recognizeText()async{
  //   await TextRecognizer(
  //       script: TextRecognitionScript.devanagiri
  //   ).processImage(
  //       InputImage.fromFile(widget.image)
  //   ).then((scannedText){
  //     scannedText.blocks.forEach((bloc){
  //       print(bloc.text);
  //       bloc.lines.forEach((line){
  //         print("hi>>>${line.elements.last.text}");
  //       });
  //     });
  //     text.value = scannedText.text;
  //   });
  // }





  Future<void> detectFrontPart() async {

    String extractedText = await extractText(widget.frontPart);

    print("#########################$extractedText#########################");

    if(1 == 1){
      data.value = parseFrontPart(extractedText);
    }else{
      isNotNIDCard.value = true;
    }
    print("Extracted NID Data: ${parseFrontPart(extractedText)}");
  }




  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    return recognizedText.text;
  }


  // Map<String, String>? parseFrontPart(String text) {
  //   Map<String, String> nidData = {};
  //
  //   // Clean and normalize text
  //   String cleanedText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  //
  //   // Extract Name: Assume it's after "Name" and is in uppercase
  //   RegExp nameRegex = RegExp(r'Name\s*([A-Z\s.]+)', caseSensitive: false);
  //   Match? nameMatch = nameRegex.firstMatch(cleanedText);
  //   if (nameMatch != null) {
  //     nidData['Name'] = nameMatch.group(1)?.trim() ?? '';
  //   } else {
  //    // return null;
  //   }
  //
  //   // Extract Date of Birth: Allow both "Birth" and OCR typo "Bith"
  //   RegExp dobRegex = RegExp(r'Date of B(?:ir|i)th\s*(\d{1,2}\s[A-Za-z]+\s\d{4})', caseSensitive: false);
  //   Match? dobMatch = dobRegex.firstMatch(cleanedText);
  //   if (dobMatch != null) {
  //     nidData['Date of Birth'] = dobMatch.group(1)?.trim() ?? '';
  //   } else {
  //    // return null;
  //   }
  //
  //   // Extract NID Number: Allow digits with or without spaces
  //   RegExp idRegex = RegExp(r'NID No\.?\s*(\d{2,3}\s?\d{3}\s?\d{4}|\d{10,17})', caseSensitive: false);
  //   Match? idMatch = idRegex.firstMatch(cleanedText);
  //   if (idMatch != null) {
  //     nidData['ID Number'] = idMatch.group(1)?.replaceAll(' ', '') ?? ''; // Remove spaces
  //   } else {
  //    // return null;
  //   }
  //
  //   return nidData;
  // }



  Map<String, String>? parseFrontPart(String ocrText) {
    try {
      // Combine all lines into one with space to handle line breaks
      String normalizedText = ocrText.replaceAll('\n', ' ');

      // Regex for Name (After "Name" until "Date of Birth" or "Date of Bith")
      final nameRegExp = RegExp(
        r'Name\s+([A-Z\s.,]+?)(?=\s*Date of (Birth|Bith))',
        caseSensitive: false,
      );

      // Regex for Date of Birth (Including OCR errors like "Bith")
      final dobRegExp = RegExp(
        r'Date of (Birth|Bith)\s+(\d{2}\s\w{3}\s\d{4})',
        caseSensitive: false,
      );

      // Regex for NID Number (Flexible positioning and multi-line support)
      final nidRegExp = RegExp(
        r'NID No\.?\s*\n?\s*(\d{3}\s\d{3}\s\d{4})|' // Case 1 & 3: NID No (with or without .) followed by number
        r'(\d{3}\s\d{3}\s\d{4})\s*\n?\s*NID No\.?', // Case 2 & 4: number followed by NID No (with or without .)
        caseSensitive: false,
      );

      // Extract Name
      final nameMatch = nameRegExp.firstMatch(normalizedText);
      String name = nameMatch?.group(1)?.trim() ?? "Not Found";

      // Extract Date of Birth
      final dobMatch = dobRegExp.firstMatch(normalizedText);
      String dateOfBirth = dobMatch?.group(2)?.trim() ?? "Not Found";

      // Extract NID Number (even if it's not on the same line)
      final nidMatch = nidRegExp.firstMatch(ocrText);
      String nidNumber = nidMatch?.group(1) ?? nidMatch?.group(2) ?? "Not Found";

      return {
        'Name': name,
        'Date of Birth': dateOfBirth,
        'ID Number': nidNumber
      };
    } catch (e) {
      print("Error parsing NID: $e");
      return null;
    }
  }




  bool isNIDCard(String extractedText) {
    List<String> nidKeywords = ["National ID Card", "Government of the People's Republic of Bangladesh", "Date of Birth", "NID No"];
    return nidKeywords.every((keyword) => extractedText.contains(keyword));
  }



  // Map<String, String>? parseFrontPart(String text) {
  //   Map<String, String> nidData = {};
  //
  //   // Extract Name (assuming name follows "Name:")
  //   RegExp nameRegex = RegExp(r'Name:\s*(.*)');
  //   Match? nameMatch = nameRegex.firstMatch(text);
  //   if (nameMatch != null) {
  //     nidData['Name'] = nameMatch.group(1) ?? '';
  //   }else{
  //     return null;
  //   }
  //
  //   // Extract Date of Birth
  //   RegExp dobRegex = RegExp(r'Date of Birth:\s*([\d]{1,2} [A-Za-z]+ \d{4})');
  //   Match? dobMatch = dobRegex.firstMatch(text);
  //   if (dobMatch != null) {
  //     nidData['Date of Birth'] = dobMatch.group(1) ?? '';
  //   }else{
  //     return null;
  //   }
  //
  //   // Extract ID Number (assuming format of a long number)
  //   RegExp idRegex = RegExp(r'ID NO:\s*(\d{10,17})');
  //   Match? idMatch = idRegex.firstMatch(text);
  //   if (idMatch != null) {
  //     nidData['ID Number'] = idMatch.group(1) ?? '';
  //   }else{
  //     return null;
  //   }
  //
  //   return nidData;
  // }
  //
  // bool isNIDCard(String extractedText) {
  //   List<String> nidKeywords = ["National ID", "Govt. of", "ID No", "Date of Birth"];
  //   for (var keyword in nidKeywords) {
  //     if (extractedText.contains(keyword)) {
  //       return true;
  //     }
  //   }
  //   return false;
  // }

  /// ======CAPTURED NID FACE==========

  Future<Face?> detectFace(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(enableContours: true, enableLandmarks: true),
    );

    final List<Face> faces = await faceDetector.processImage(inputImage);
    await faceDetector.close();

    if (faces.isEmpty) {
      print("No face detected.");
      return null;
    }

    return faces.first; // Assuming the first detected face is the NID profile image
  }


  Future<File?> cropFace(File imageFile, Face face) async {
    // Load the image
    img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());
    if (originalImage == null) return null;

    // Get the bounding box of the detected face
    final boundingBox = face.boundingBox;
    int x = boundingBox.left.toInt();
    int y = boundingBox.top.toInt();
    int width = boundingBox.width.toInt();
    int height = boundingBox.height.toInt();

    // Ensure cropping values are within the image bounds
    x = x.clamp(0, originalImage.width);
    y = y.clamp(0, originalImage.height);
    width = width.clamp(0, originalImage.width - x);
    height = height.clamp(0, originalImage.height - y);

    // Crop the face region
    img.Image croppedFace = img.copyCrop(originalImage, x: x, y: y, width: width, height: height);

    // Save the cropped image
    File faceImageFile = File(imageFile.path.replaceAll('.jpg', '_face.jpg'))
      ..writeAsBytesSync(img.encodeJpg(croppedFace));

    return faceImageFile;
  }



  Future<void> extractNIDProfileImage() async {

    Face? face = await detectFace(widget.frontPart);
    if (face == null) {
      print("No face found on the NID card.");
      return;
    }

    File? faceImage = await cropFace(widget.frontPart, face);
    if (faceImage != null) {
      nidFace.value = faceImage;
      print("Profile image extracted and saved at: ${faceImage.path}");
    }
  }





  Future<void> detectBackPart() async {

    String extractedText = await extractText(widget.backPart);
    print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>$extractedText");
    if(1 == 1){
      issueDate.value = await extractIssueDate(extractedText);
      mrzNumber.value = await extractMRZ(extractedText);
    }else{
      isNotNIDCard.value = true;
    }
    print("Back Part: ${issueDate.value}");
    print("Back Part MRZ: ${mrzNumber.value}");
  }



  Future<String?> extractIssueDate(String text) async {
    RegExp regExp = RegExp(
      r"Issue\s*Date[:\s]*(\d{2}\s\w+\s\d{4})",
      caseSensitive: false,
    );

    final match = regExp.firstMatch(text);
    return match?.group(1);
  }


  Future<String?> extractMRZ(String text) async {
    RegExp regExp = RegExp(r"[A-Z0-9<]{90}");

    final match = regExp.firstMatch(text.replaceAll('\n', ''));
    return match?.group(0);
  }

  bool isNIDBackPart(String text) {
    bool hasIssueDate = RegExp(r"Issue\s*Date[:\s]*(\d{2}\s\w+\s\d{4})", caseSensitive: false).hasMatch(text);
    bool hasMRZ = RegExp(r"[A-Z0-9<]{90}").hasMatch(text.replaceAll('\n', ''));

    return hasIssueDate && hasMRZ;
  }




  @override
  void initState(){
    // TODO: implement initState
    super.initState();
    detectFrontPart().whenComplete((){
      extractNIDProfileImage().whenComplete((){
        detectBackPart().whenComplete((){
          isLoading.value = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(10),
          child: ValueListenableBuilder(
            valueListenable: isNotNIDCard,
            builder: (context,__,_) {
              return Visibility(
                visible: isNotNIDCard.value == false,
                replacement: const Center(
                  child: Text(
                      "This isn't valid NID card. Please scan your NID card"
                  ),
                ),
                child: ValueListenableBuilder(
                  valueListenable: isLoading,
                  builder: (context,_,__) {
                    return Visibility(
                      visible: isLoading.value == false,
                      replacement: const Center(child: CircularProgressIndicator(color: Colors.blue),),
                      child: ValueListenableBuilder(
                        valueListenable: data,
                        builder: (context,__,_) {
                          return Visibility(
                            visible: data.value != null,
                            replacement: const Center(
                              child: Text(
                                "We can't detect. Please Try again!"
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                                ValueListenableBuilder(
                                    valueListenable: nidFace,
                                    builder: (_,__,___)=>
                                      nidFace.value == null ?
                                        const Icon(Icons.account_circle)
                                      : Image.file(
                                         nidFace.value!
                                      )
                                ),

                                Text("Name : ${data.value?["Name"]}"),
                                const SizedBox(height: 10),
                                Text("Date of Birth : ${data.value?["Date of Birth"]}"),
                                const SizedBox(height: 10),
                                Text("ID Number : ${data.value?["ID Number"]}"),
                                const SizedBox(height: 10),
                                Text("Issue Date : ${issueDate.value}"),


                                ElevatedButton(
                                    onPressed: ()=> Navigator.push(context, CupertinoPageRoute(builder: (context)=> const FaceDetectionScreen())),
                                    child: const Text("Face Verify")
                                ),

                              ],
                            ),
                          );
                        }
                      ),
                    );
                  }
                ),
              );
            }
          ),
        ),
      ),
    );
  }
}
