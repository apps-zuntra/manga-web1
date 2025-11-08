// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class UploadAudiobookPage extends StatefulWidget {
//   @override
//   State<UploadAudiobookPage> createState() => _UploadAudiobookPageState();
// }

// class _UploadAudiobookPageState extends State<UploadAudiobookPage> {
//   Uint8List? imageBytes;
//   Uint8List? audioBytes;
//   String? imageName;
//   String? audioName;

//   String? imageURL;
//   String? audioURL;
//   bool uploading = false;

//   // 📂 Pick File (Image/Audio)
//   Future<void> pickFile(bool isImage) async {
//     final result = await FilePicker.platform.pickFiles(
//       type: isImage ? FileType.image : FileType.custom,
//       allowedExtensions: isImage ? null : ['mp3', 'm4b'],
//       withData: true,
//     );
//     if (result == null) return;

//     setState(() {
//       if (isImage) {
//         imageBytes = result.files.first.bytes!;
//         imageName = result.files.first.name;
//       } else {
//         audioBytes = result.files.first.bytes!;
//         audioName = result.files.first.name;
//       }
//     });
//   }

//   // ☁️ Upload to AWS
//   Future<String?> uploadToAWS(
//     Uint8List bytes,
//     String type,
//     String fileName,
//   ) async {
//     setState(() => uploading = true);

//     final resp = await http.post(
//       Uri.parse("http://127.0.0.1:5000/generate-upload-url"),
//       body: {"file_type": type, "file_name": fileName},
//     );

//     if (resp.statusCode != 200) {
//       print("❌ Failed to get AWS URL: ${resp.body}");
//       return null;
//     }

//     final data = jsonDecode(resp.body);
//     final uploadURL = data["upload_url"];
//     final publicURL = data["public_url"];

//     final mime = type == "image" ? "image/jpeg" : "audio/mpeg";

//     final putRes = await http.put(
//       Uri.parse(uploadURL),
//       headers: {"Content-Type": mime},
//       body: bytes,
//     );

//     if (putRes.statusCode == 200) {
//       print("✅ Uploaded to AWS: $publicURL");
//       return publicURL;
//     } else {
//       print("❌ AWS upload failed: ${putRes.statusCode}");
//       return null;
//     }
//   }

//   Future<void> uploadAndSave() async {
//     if (imageBytes == null || audioBytes == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Pick both files")));
//       return;
//     }

//     // Upload image & audio
//     imageURL = await uploadToAWS(imageBytes!, "image", imageName!);
//     audioURL = await uploadToAWS(audioBytes!, "audio", audioName!);

//     if (imageURL == null || audioURL == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Upload failed")));
//       setState(() => uploading = false);
//       return;
//     }

//     // ✅ Save Record to Supabase
//     await Supabase.instance.client.from("audiobooks").insert({
//       "title": titleCtrl.text,
//       "author": authorCtrl.text,
//       "narrator": narratorCtrl.text,
//       "genre": selectedGenre,
//       "duration": durationCtrl.text,
//       "price": priceCtrl.text,
//       "description": descriptionCtrl.text,
//       "image_url": imageURL,
//       "audio_url": audioURL,
//       "status": status,
//       "created_at": DateTime.now().toIso8601String(),
//     });

//     setState(() => uploading = false);

//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text("✅ Uploaded & Saved")));
//   }

//   // 📋 FORM FIELDS
//   final titleCtrl = TextEditingController();
//   final authorCtrl = TextEditingController();
//   final narratorCtrl = TextEditingController();
//   final durationCtrl = TextEditingController();
//   final priceCtrl = TextEditingController();
//   final descriptionCtrl = TextEditingController();

//   String status = "Draft";
//   String? selectedGenre;
//   final genres = [
//     "Fiction",
//     "Non-Fiction",
//     "Mystery",
//     "Sci-Fi",
//     "Self-Help",
//     "Biography",
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Upload Audiobook")),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(18),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Pick Cover Image"),
//             ElevatedButton(
//               onPressed: () => pickFile(true),
//               child: Text(imageName ?? "Pick Image"),
//             ),
//             if (imageBytes != null) Image.memory(imageBytes!, height: 120),

//             SizedBox(height: 20),

//             Text("Pick Audio File (MP3)"),
//             ElevatedButton(
//               onPressed: () => pickFile(false),
//               child: Text(audioName ?? "Pick Audio"),
//             ),

//             SizedBox(height: 30),

//             uploading
//                 ? Center(child: CircularProgressIndicator())
//                 : ElevatedButton.icon(
//                     icon: Icon(Icons.cloud_upload),
//                     label: Text("Upload & Save"),
//                     onPressed: uploadAndSave,
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }
