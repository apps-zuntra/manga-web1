import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class UploadAudiobookPage extends StatefulWidget {
  const UploadAudiobookPage({Key? key}) : super(key: key);

  @override
  State<UploadAudiobookPage> createState() => _UploadAudiobookPageState();
}

class _UploadAudiobookPageState extends State<UploadAudiobookPage> {
  Uint8List? imageBytes;
  Uint8List? audioBytes;
  String? imageName;
  String? audioName;
  String? imageURL;
  String? audioURL;
  bool uploading = false;

  // Form controllers
  final titleCtrl = TextEditingController();
  final authorCtrl = TextEditingController();
  final narratorCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  String status = "Draft";
  String? selectedGenre;
  final genres = [
    "Fiction",
    "Non-Fiction",
    "Mystery",
    "Sci-Fi",
    "Self-Help",
    "Biography",
  ];

  // Select Image or Audio
  Future<void> pickFile(bool isImage) async {
    final result = await FilePicker.platform.pickFiles(
      type: isImage ? FileType.image : FileType.custom,
      allowedExtensions: isImage ? null : ["mp3", "m4b"],
      withData: true,
    );
    if (result == null) return;

    setState(() {
      if (isImage) {
        imageBytes = result.files.first.bytes!;
        imageName = result.files.first.name;
      } else {
        audioBytes = result.files.first.bytes!;
        audioName = result.files.first.name;
      }
    });
  }

  // Upload to AWS
  Future<String?> uploadToAWS(Uint8List file, String type, String name) async {
    final res = await http.post(
      Uri.parse("http://127.0.0.1:5000/generate-upload-url"),
      body: {"file_type": type, "file_name": name},
    );

    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    String uploadUrl = data["upload_url"];
    String publicUrl = data["public_url"];
    String mime = type == "image" ? "image/jpeg" : "audio/mpeg";

    final putRes = await http.put(
      Uri.parse(uploadUrl),
      headers: {"Content-Type": mime},
      body: file,
    );

    return putRes.statusCode == 200 ? publicUrl : null;
  }

  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Uploading...", style: TextStyle(fontSize: 16)),
            ],
          ),
        );
      },
    );
  }

  Future<void> uploadAndSave() async {
    if (imageBytes == null || audioBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please upload image & audio")));
      return;
    }

    if (titleCtrl.text.isEmpty || authorCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Title & Author are required")));
      return;
    }

    showLoadingDialog(); // ✅ Show loading popup

    // Upload to AWS
    imageURL = await uploadToAWS(imageBytes!, "image", imageName!);
    audioURL = await uploadToAWS(audioBytes!, "audio", audioName!);

    if (imageURL == null || audioURL == null) {
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("File upload failed ❌")));
      return;
    }

    final supabase = Supabase.instance.client;

    try {
      await supabase.from("stories").insert({
        "title": titleCtrl.text,
        "author": authorCtrl.text,
        "narrator": narratorCtrl.text,
        "genre": selectedGenre,
        "duration": durationCtrl.text,
        "price": priceCtrl.text,
        "description": descriptionCtrl.text,
        "image_url": imageURL,
        "audio_url": audioURL,
        "status": status,
        "created_at": DateTime.now().toIso8601String(),
      }).select();

      Navigator.pop(context); // ❎ close loading

      // ✅ Success popup
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 70),
              SizedBox(height: 8),
              Text(
                "Upload Complete!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.pop(context);
        resetForm();
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Supabase error: $e")));
    }
  }

  Widget textField(String label, TextEditingController c, {int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextField(
          controller: c,
          maxLines: lines,
          decoration: InputDecoration(
            hintText: "Enter $label",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  void resetForm() {
    titleCtrl.clear();
    authorCtrl.clear();
    narratorCtrl.clear();
    durationCtrl.clear();
    priceCtrl.clear();
    descriptionCtrl.clear();

    setState(() {
      imageBytes = null;
      audioBytes = null;
      imageName = null;
      audioName = null;
      imageURL = null;
      audioURL = null;
      selectedGenre = null;
      status = "Draft";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Audiobook")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Audiobook Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: textField("Title", titleCtrl)),
                SizedBox(width: 16),
                Expanded(child: textField("Author", authorCtrl)),
              ],
            ),
            SizedBox(height: 15),

            Row(
              children: [
                Expanded(child: textField("Narrator", narratorCtrl)),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Genre",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      DropdownButtonFormField(
                        value: selectedGenre,
                        items: genres
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedGenre = v),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Duration (hrs)",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      TextField(
                        controller: durationCtrl,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: (value) {
                          // prevent more than one decimal
                          if (value.split('.').length > 2) {
                            durationCtrl.text = value.substring(
                              0,
                              value.length - 1,
                            );
                            durationCtrl.selection = TextSelection.fromPosition(
                              TextPosition(offset: durationCtrl.text.length),
                            );
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "e.g. 2.5 (2 hrs 30 mins)",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      Text(
                        "Numbers only allowed",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Price",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: (value) {
                          if (value.split('.').length > 2) {
                            priceCtrl.text = value.substring(
                              0,
                              value.length - 1,
                            );
                            priceCtrl.selection = TextSelection.fromPosition(
                              TextPosition(offset: priceCtrl.text.length),
                            );
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Enter price",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      Text(
                        "Numbers only allowed",
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),

            textField("Description", descriptionCtrl, lines: 3),
            SizedBox(height: 25),

            // Upload UI
            Text("Cover Image", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            InkWell(
              onTap: () => pickFile(true),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: imageBytes == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image, size: 40, color: Colors.grey),
                            Text("Click to upload cover image"),
                          ],
                        )
                      : Image.memory(imageBytes!, height: 150),
                ),
              ),
            ),

            SizedBox(height: 20),
            Text("Audio File", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            InkWell(
              onTap: () => pickFile(false),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: audioBytes == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 40,
                              color: Colors.grey,
                            ),
                            Text("Click to upload audio file"),
                          ],
                        )
                      : Text(
                          audioName ?? "Audio Selected",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
            SizedBox(height: 30),

            uploading
                ? Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      ElevatedButton(
                        onPressed: uploadAndSave,
                        child: Text("Upload Audiobook"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                      ),
                      SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {},
                        child: Text("Save as Draft"),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
