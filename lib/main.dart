import 'package:flutter/material.dart';
import 'package:mango_web/config/supabase_config.dart';
import 'package:mango_web/geturl.dart';
import 'package:mango_web/upload_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://glofplyipqsoirrawnxf.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdsb2ZwbHlpcHFzb2lycmF3bnhmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMDM0MzAsImV4cCI6MjA3Nzg3OTQzMH0.E9KcDsTptE-W2cwwcACI_qctxcHupRytklx8QWwIzw8'; // <-- paste the anon key directly here

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Audiobook Upload',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: UploadAudiobookPage(), 
    );
  }
}
