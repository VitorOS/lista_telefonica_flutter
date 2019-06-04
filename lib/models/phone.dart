import 'package:firebase_database/firebase_database.dart';

class Phone {
  String key;
  String name;
  String phone;
  bool completed;
  String userId;

  Phone(this.name, this.phone, this.userId, this.completed);

  Phone.fromSnapshot(DataSnapshot snapshot) :
    key = snapshot.key,
    userId = snapshot.value["userId"],
    name = snapshot.value["name"],
    phone = snapshot.value["phone"],
    completed = snapshot.value["completed"];

  toJson() {
    return {
      "userId": userId,
      "name": name,
      "phone": phone,
      "completed": completed,
    };
  }
}