import 'package:flutter/material.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:rrhfit_sys32/pages/dashboard/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fittlay Planillas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const DashboardPage(),
    );
  }
}