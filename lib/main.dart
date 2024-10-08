// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'package:Einkaufsliste/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

bool showReorganizer = false;

Future<void> main() async {
  //WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeMode>(
      future: Preferences.getThemeMode(),
      builder: (context, themeModeSnapshot) {
        final currentThemeMode = themeModeSnapshot.data ?? ThemeMode.system;

        return MaterialApp(
          title: 'Einkaufsliste',
          home: HomePage(),
          themeMode: currentThemeMode,
          theme: ThemeData.light(
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(
            useMaterial3: true,
          ),
        );
      },
    );
  }
}

class Preferences {
  static const String themeModeKey = 'themeMode';

  static Future<bool> getPref(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool value = prefs.getBool(key) ?? true;
    return value;
  }

  static Future<void> setPref(String key, bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<ThemeMode> getThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int themeModeValue = prefs.getInt(themeModeKey) ?? 0;
    return ThemeMode.values[themeModeValue];
  }

  static Future<void> setThemeMode(ThemeMode themeMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeModeKey, themeMode.index);
  }

  static Future<List<String>> getPrefStringList(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> value = prefs.getStringList(key) ?? [];
    return value;
  }

  static Future<void> setPrefStringList(String key, List<String> value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }
}

bool dialogOpen = false;
late SpeechToText speechToText;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Key _futureBuilderKey = UniqueKey();
  List<String> items = [];
  List<Map<String, dynamic>> items_online = [];
  bool isExpanded = false;
  bool onlineMode = false;

  @override
  void initState() {
    super.initState();
    speechToText = SpeechToText();

    Preferences.getPref('online_mode').then((value) {
      onlineMode = value;
    });
  }

  Future<void> _startListening() async {
    if (!speechToText.isListening) {
      bool available = await speechToText.initialize(
        onStatus: (status) {
          if (status == 'listening') {
            _showListeningDialog(context);
          }
        },
        onError: (errorNotification) {
          if (dialogOpen) {
            dialogOpen = false;
            Navigator.pop(context);
          }
        },
      );

      if (available) {
        speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              if (result.recognizedWords != "") {
                List<String> newItems = result.recognizedWords.split(' und ');

                for (int i = 0; i < newItems.length; i++) {
                  if(onlineMode)
                  {
                    DatabaseService().executeQuery('INSERT INTO items(item) VALUES("${newItems[i]}")');
                  }
                  else
                  {
                    items.add(newItems[i]);
                  }
                }
                if(!onlineMode)
                {
                Preferences.setPrefStringList('einkaufsliste', items);
                }
                setState(() {
                  _futureBuilderKey = UniqueKey();
                });
              }
              if (dialogOpen) {
                dialogOpen = false;
                Navigator.pop(context);
              }
            }
          },
        );
      }
    } else {
      speechToText.stop();
      if (dialogOpen) {
        dialogOpen = false;
        Navigator.pop(context);
      }
    }
  }

  void setClipboardText(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _showSnackbar(BuildContext context, String content) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(content),
        action: SnackBarAction(
            label: 'OK', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 15),
      body: FutureBuilder(
        key: _futureBuilderKey,
        future: Preferences.getPrefStringList('einkaufsliste'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          items = snapshot.data!;

          if(onlineMode)
          {
            return FutureBuilder(
              key: _futureBuilderKey,
              future: DatabaseService().executeQuery('SELECT * FROM items'),
              builder:(context, snapshot) {

              if (!snapshot.hasData) {
                return Center(
                    child: CircularProgressIndicator(),
                  );
              }

              items_online = snapshot.data!;
                
              return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  SizedBox(width: 7),
                  Text('Einkaufsliste (online)', style: TextStyle(fontSize: 35)),
                  Spacer(),
                  ThemedIconButton(),
                  SizedBox(
                    width: 10,
                  )
                ]),
                SizedBox(height: 30),
                Builder(
                  builder: (context) {
                    if (items_online.isEmpty) {
                      return Card(
                        child: ListTile(
                          title: Center(
                            child: Text('Deine Einkaufsliste ist leer'),
                          ), 
                          onLongPress: () {
                            showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return Card(
                                      child: ListTile(
                                    title: Text(
                                        'Du kannst den Standardeintrag nicht löschen'),
                                  ));
                                });
                          },
                        ),
                      );
                    } else {
                      return Expanded(
                        child: ListView.builder(
                          itemCount: items_online.length,
                          itemBuilder: ((context, index) {
                            final item = items_online[index];
                            return Card(
                              key: Key('$index'),
                              child: Slidable(
                                key: Key('$index'),
                                startActionPane: ActionPane(
                                  extentRatio: 0.4,
                                  motion: const BehindMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) {
                                        int id = int.parse(items_online.elementAt(index)['item_id']);
                                        _showEditDialog(context, id);
                                      },
                                      backgroundColor: Colors.blue,
                                      icon: Icons.edit,
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          bottomLeft: Radius.circular(10)),
                                    ),
                                    SlidableAction(
                                      onPressed: (context) {
                                        var id = items_online.elementAt(index)['item_id'];
                                        DatabaseService().executeQuery('DELETE FROM items WHERE item_id = $id');
                                        setState(() {
                                          _futureBuilderKey = UniqueKey();
                                        });
                                      },
                                      backgroundColor: Colors.red,
                                      icon: Icons.delete,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Visibility(
                                      visible: showReorganizer,
                                      child: ListTile(
                                        contentPadding:
                                            EdgeInsets.only(left: 21),
                                        title: Text(
                                          item['item'],
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        leading: ReorderableDragStartListener(
                                            index: index,
                                            child: const Icon(Icons.menu)),
                                      ),
                                    ),
                                    Visibility(
                                      visible: !showReorganizer,
                                      child: ListTile(
                                        contentPadding:
                                            EdgeInsets.only(left: 24),
                                        title: Text(
                                          item['item'],
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
            });
          }
          else
          {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  SizedBox(width: 7),
                  Text('Einkaufsliste (offline)', style: TextStyle(fontSize: 35)),
                  Spacer(),
                  ThemedIconButton(),
                  SizedBox(
                    width: 10,
                  )
                ]),
                SizedBox(height: 30),
                Builder(
                  builder: (context) {
                    if (items.isEmpty) {
                      return Card(
                        child: ListTile(
                          title: Center(
                            child: Text('Deine Einkaufsliste ist leer'),
                          ), 
                          onLongPress: () {
                            showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return Card(
                                      child: ListTile(
                                    title: Text(
                                        'Du kannst den Standardeintrag nicht löschen'),
                                  ));
                                });
                          },
                        ),
                      );
                    } else {
                      return Expanded(
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: items.length,
                          itemBuilder: ((context, index) {
                            final item = items[index];
                            return Card(
                              key: Key('$index'),
                              child: Slidable(
                                key: Key('$index'),
                                startActionPane: ActionPane(
                                  extentRatio: 0.4,
                                  motion: const BehindMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) {
                                        _showEditDialog(context, index);
                                      },
                                      backgroundColor: Colors.blue,
                                      icon: Icons.edit,
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          bottomLeft: Radius.circular(10)),
                                    ),
                                    SlidableAction(
                                      onPressed: (context) {
                                        items.removeAt(index);
                                        Preferences.setPrefStringList('einkaufsliste', items);
                                        setState(() {
                                          _futureBuilderKey = UniqueKey();
                                        });
                                      },
                                      backgroundColor: Colors.red,
                                      icon: Icons.delete,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Visibility(
                                      visible: showReorganizer,
                                      child: ListTile(
                                        contentPadding:
                                            EdgeInsets.only(left: 21),
                                        title: Text(
                                          item,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        leading: ReorderableDragStartListener(
                                            index: index,
                                            child: const Icon(Icons.menu)),
                                      ),
                                    ),
                                    Visibility(
                                      visible: !showReorganizer,
                                      child: ListTile(
                                        contentPadding:
                                            EdgeInsets.only(left: 24),
                                        title: Text(
                                          item,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final String item = items.removeAt(oldIndex);
                              items.insert(newIndex, item);
                              Preferences.setPrefStringList('einkaufsliste', items);
                              _futureBuilderKey = UniqueKey();
                            });
                          },
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
          }
        },
      ),
      floatingActionButton:
          Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        Visibility(
          visible: !isExpanded,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Icon(Icons.arrow_drop_up),
          ),
        ),
        Visibility(
            visible: isExpanded,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    _showInputDialog(context);
                  },
                  heroTag: null,
                  child: Icon(Icons.add),
                ),
                SizedBox(
                  height: 10,
                ),
                FloatingActionButton(
                  onPressed: () {
                    _startListening();
                  },
                  heroTag: null,
                  child: Icon(Icons.mic),
                ),
                SizedBox(
                  height: 10,
                ),
                FloatingActionButton(
                  onPressed: () {

                    if(onlineMode)
                    {
                      _showSnackbar(context, 'Das funktioniert nur im Offline Modus');
                    }
                    else
                    {
                      showReorganizer = !showReorganizer;
                      setState(() {
                        _futureBuilderKey = UniqueKey();
                      });
                    }

                    
                  },
                  heroTag: null,
                  child: Icon(Icons.menu),
                ),
                SizedBox(
                  height: 10,
                ),
                FloatingActionButton(
                  onPressed: () {
                    _showClearDialog(context);
                  },
                  heroTag: null,
                  child: Icon(Icons.delete_sweep),
                ),
                SizedBox(
                  height: 10,
                ),
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      onlineMode = !onlineMode;
                      Preferences.setPref('online_mode', onlineMode);
                    });
                  },
                  heroTag: null,
                  child: Icon(onlineMode ? Icons.signal_wifi_4_bar : Icons.signal_wifi_0_bar),
                ),
                SizedBox(
                  height: 10,
                ),
                FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                  heroTag: null,
                  child: Icon(Icons.arrow_drop_down),
                ),
              ],
            ))
      ]),
    );
  }

  Future<void> _showInputDialog(BuildContext context) async {
    TextEditingController textFieldController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Was möchtest du hinzufügen?',
              style: TextStyle(fontSize: 20)),
          content: TextField(
            controller: textFieldController,
            decoration: InputDecoration(hintText: 'Gib hier etwas ein'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                if (textFieldController.text != "") {
                  if(onlineMode)
                  {
                    DatabaseService().executeQuery('INSERT INTO items(item) VALUES("${textFieldController.text}")');
                  }
                  else
                  {
                    items.add(textFieldController.text);
                    Preferences.setPrefStringList('einkaufsliste', items);
                  }
                  Navigator.pop(context);
                  setState(() {
                    _futureBuilderKey = UniqueKey();
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(BuildContext context, int index) async {
    TextEditingController textFieldController;
    if(onlineMode)
    {
      var item = items_online.firstWhere((element) => element['item_id'] == index.toString());
      textFieldController =
        TextEditingController(text: item['item']);
    }
    else
    {
      textFieldController =
        TextEditingController(text: items[index]);
    }

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Wie möchtest du es ändern?',
              style: TextStyle(fontSize: 20)),
          content: TextField(
            controller: textFieldController,
            decoration: InputDecoration(hintText: 'Gib hier etwas ein'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                if (textFieldController.text != "") {
                  if(onlineMode)
                  {
                    DatabaseService().executeQuery('UPDATE items SET item = "${textFieldController.text}" WHERE item_id = $index');
                  }
                  else
                  {
                    items[index] = textFieldController.text;
                    Preferences.setPrefStringList('einkaufsliste', items);
                  }
                  Navigator.pop(context);
                  setState(() {
                    _futureBuilderKey = UniqueKey();
                  });
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showClearDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Möchtest du die Liste löschen?',
              style: TextStyle(fontSize: 18)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('NEIN'),
            ),
            TextButton(
              onPressed: () {
                if(onlineMode)
                {
                  DatabaseService().executeQuery('DELETE FROM items');
                }
                else
                {
                  Preferences.setPrefStringList('einkaufsliste', []);
                }
                Navigator.pop(context);
                setState(() {
                  _futureBuilderKey = UniqueKey();
                });
              },
              child: Text('JA'),
            ),
          ],
        );
      },
    );
  }
}

void _showListeningDialog(BuildContext context) {
  dialogOpen = true;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Du kannst jetzt sprechen', style: TextStyle(fontSize: 20)),
        content: Text('Mit dem Wort "und" kannst du deine Einträge trennen'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              speechToText.cancel();
              dialogOpen = false;
              Navigator.pop(context);
            },
            child: Text('Abbrechen'),
          ),
        ],
      );
    },
  );
}

class ThemedIconButton extends StatefulWidget {
  const ThemedIconButton({super.key});

  @override
  ThemedIconButtonState createState() => ThemedIconButtonState();
}

class ThemedIconButtonState extends State<ThemedIconButton> {
  ThemeMode selectedThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    Preferences.getThemeMode().then((themeMode) {
      setState(() {
        selectedThemeMode = themeMode;
      });
    });
  }

  void _changeState() {
    setState(() {
      if (selectedThemeMode == ThemeMode.system) {
        selectedThemeMode = ThemeMode.dark;
        Preferences.setThemeMode(selectedThemeMode);
        runApp(MyApp());
      } else if (selectedThemeMode == ThemeMode.dark) {
        selectedThemeMode = ThemeMode.light;
        Preferences.setThemeMode(selectedThemeMode);
        runApp(MyApp());
      } else {
        selectedThemeMode = ThemeMode.system;
        Preferences.setThemeMode(selectedThemeMode);
        runApp(MyApp());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final IconData iconData = selectedThemeMode == ThemeMode.light
        ? Icons.wb_sunny
        : selectedThemeMode == ThemeMode.system
            ? Icons.dark_mode
            : Icons.brightness_auto;

    return IconButton(
      icon: Icon(iconData),
      iconSize: 35,
      onPressed: () {
        _changeState();
      },
    );
  }
}
