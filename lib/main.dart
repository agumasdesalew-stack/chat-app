import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chat_app/utils/constraints.dart';
import 'package:chat_app/pages/splash_page.dart';


Future  <void> main () async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dirkrznapkgnrhyvnbld.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpcmtyem5hcGtnbnJoeXZuYmxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExMTI5NjcsImV4cCI6MjA3NjY4ODk2N30.e_C7W3MJTKIEFl03qVDpoPKsZaIU-IzUYVmIwMaJeXs',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat app',
      theme: appTheme,
      home: const SplashPage(),
        );
      
      
  }
}

