import 'package:firebase_auth/firebase_auth.dart';

//singleton para almacenar el usuario actual u otros datos globales
class Global {
  static final Global _instance = Global._internal();
  factory Global() => _instance;
  Global._internal();

  User? currentUser;
}