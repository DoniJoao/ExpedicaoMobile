import 'package:flutter/material.dart';
import 'screens/expedicao.dart'; // Importa a tela que criamos antes

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expedição Desktop',
      debugShowCheckedModeBanner: false, // Remove aquela faixinha de "Debug" do canto da tela
      
      // Aqui você define a identidade visual global do seu app (como o seu arquivo CSS global)
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        
        // Define fontes ou estilos padrões para o app inteiro se quiser
        fontFamily: 'Roboto', 
      ),
      
      // Define qual será a primeira tela aberta assim que o app carregar
      home: ExpedicaoScreen(), 
    );
  }
}