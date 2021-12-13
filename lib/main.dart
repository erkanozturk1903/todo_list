import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const Home());
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  List _toDoList = [];

  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data!);
      });
    });
  }

  void _ekleToDo() {
    setState(() {
      Map<String, dynamic> nevToDo = Map();
      nevToDo["title"] = _toDoController.text;
      nevToDo["Ok"] = false;
      _toDoList.add(nevToDo);
      _saveData();
    });
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });

      _saveData();
    });

    return;
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            appBar: AppBar(
              title: const Text("ToDo List"),
              backgroundColor: Colors.blueAccent,
              //centerTitle: true,
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _toDoController,
                          decoration: const InputDecoration(
                              labelText: "Yeni Görev",
                              labelStyle: TextStyle(
                                color: Colors.blueAccent,
                              )),
                        ),
                      ),
                      ElevatedButton(
                          onPressed: _ekleToDo,
                          child: const Text(
                            "EKLE",
                          ),
                          style: ElevatedButton.styleFrom(
                              primary: Colors.blueAccent,
                              textStyle: const TextStyle(color: Colors.white))),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                        padding: const EdgeInsets.only(top: 10.0),
                        itemCount: _toDoList.length,
                        itemBuilder: buildItem),
                  ),
                ),
              ],
            )),
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: const Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["Ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["Ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["Ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content:
                Text("Görev \"${_lastRemoved["title"]}\" Başarıyla Kaldırıldı"),
            action: SnackBarAction(
              label: "Geri Al",
              onPressed: () {
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: const Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
