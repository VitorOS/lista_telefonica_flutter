import 'package:flutter/material.dart';
import 'package:lista_telefonica/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lista_telefonica/models/phone.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Phone> _phoneList;

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final _nameEditingController = TextEditingController();
  final _phoneEditingController = TextEditingController();

  StreamSubscription<Event> _onPhoneAddedSubscription;
  StreamSubscription<Event> _onPhoneChangedSubscription;

  Query _phoneQuery;

  bool _isEmailVerified = false;

  @override
  void initState() {
    super.initState();

    _checkEmailVerification();

    _phoneList = new List();
    _phoneQuery = _database
        .reference()
        .child("phone")
        .orderByChild("userId")
        .equalTo(widget.userId);
    _onPhoneAddedSubscription = _phoneQuery.onChildAdded.listen(_onEntryAdded);
    _onPhoneChangedSubscription = _phoneQuery.onChildChanged.listen(_onEntryChanged);
  }

  void _checkEmailVerification() async {
    _isEmailVerified = await widget.auth.isEmailVerified();
    if (!_isEmailVerified) {
      _showVerifyEmailDialog();
    }
  }

  void _resentVerifyEmail(){
    widget.auth.sendEmailVerification();
    _showVerifyEmailSentDialog();
  }

  void _showVerifyEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content: new Text("Please verify account in the link sent to email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Resent link"),
              onPressed: () {
                Navigator.of(context).pop();
                _resentVerifyEmail();
              },
            ),
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Verify your account"),
          content: new Text("Link to verify account has been sent to your email"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Dismiss"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _onPhoneAddedSubscription.cancel();
    _onPhoneChangedSubscription.cancel();
    super.dispose();
  }

  _onEntryChanged(Event event) {
    var oldEntry = _phoneList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    setState(() {
      _phoneList[_phoneList.indexOf(oldEntry)] = Phone.fromSnapshot(event.snapshot);
    });
  }

  _onEntryAdded(Event event) {
    setState(() {
      _phoneList.add(Phone.fromSnapshot(event.snapshot));
    });
  }

  _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  _addNewPhone(String name, String number) {
    if (name.length > 0 && number.length > 0) {

      Phone phone = new Phone(name.toString(), number.toString(), widget.userId, false);
      _database.reference().child("phone").push().set(phone.toJson());
    }
  }

  _updatePhone(Phone phone){
    //Toggle completed
    phone.completed = !phone.completed;
    if (phone != null) {
      _database.reference().child("phone").child(phone.key).set(phone.toJson());
    }
  }

  _deletePhone(String phoneId, int index) {
    _database.reference().child("phone").child(phoneId).remove().then((_) {
      print("Delete $phoneId successful");
      setState(() {
        _phoneList.removeAt(index);
      });
    });
  }

  _showDialog(BuildContext context, index) async {
    print(index);
    if(index >= 0){
      _nameEditingController.value = new TextEditingValue(text: _phoneList[index].name);
      _phoneEditingController.value = new TextEditingValue(text: _phoneList[index].phone);
    }else{
      _nameEditingController.clear();
      _phoneEditingController.clear();
    }
    await showDialog<String>(
        context: context,
      builder: (BuildContext context) {
          return AlertDialog(
            content: new Column(
              children: <Widget>[
                new Expanded(child: new TextField(
                  controller: _nameEditingController,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Name',
                  ),
                )),
                new Expanded(child: new TextField(
                  controller: _phoneEditingController,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Phone',
                  ),
                )),

              ],
            ),

            actions: <Widget>[
              new FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              new FlatButton(
                  child: const Text('Save'),
                  onPressed: () {
                    if(index >= 0){
                      Phone phone = _phoneList[index];
                      phone.name = _nameEditingController.text.toString();
                      phone.phone = _phoneEditingController.text.toString();
                      _updatePhone(phone);
                    }else{
                      _addNewPhone(_nameEditingController.text.toString(), _phoneEditingController.text.toString());
                    }
                    Navigator.pop(context);
                  })
            ],
          );
      }
    );
  }

  Widget _showPhoneList() {
    if (_phoneList.length > 0) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: _phoneList.length,
          itemBuilder: (BuildContext context, int index) {
            String phoneId = _phoneList[index].key;
            String name = _phoneList[index].name;
            String phone = _phoneList[index].phone;
            bool completed = _phoneList[index].completed;
//            String userId = _phoneList[index].userId;
            return Dismissible(
              key: Key(phoneId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                _deletePhone(phoneId, index);
              },
              child: ListTile(
                title: Text(
                  name,
                  style: TextStyle(fontSize: 20.0),
                ),
                subtitle: Text(
                  phone,
                  style: TextStyle(fontSize: 20.0),
                ),
                trailing: IconButton(
                    icon: Icon(Icons.border_color, color: Colors.grey, size: 20.0),
                    onPressed: () {
                      _showDialog(context, index);
//                      _updatePhone(_phoneList[index]);
                    }),
              ),
            );
          });
    } else {
      return Center(child: Text("Bem vindo, sua agenda está vazia",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),));
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Lista Telefônica'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: _signOut)
          ],
        ),
        body: _showPhoneList(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showDialog(context, -5);
          },
          tooltip: 'Increment',
          child: Icon(Icons.add),
        )
    );
  }
}
