// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  static const String einkaufsKey = 'einkaufsItems';

  static Future<ThemeMode> getThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int themeModeValue = prefs.getInt(themeModeKey) ?? 0;
    return ThemeMode.values[themeModeValue];
  }

  static Future<void> setThemeMode(ThemeMode themeMode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeModeKey, themeMode.index);
  }

  static Future<List<String>> getEinkaufsListe() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> einkaufsValue = prefs.getStringList(einkaufsKey) ?? [];
    return einkaufsValue;
  }

  static Future<void> setEinkaufsListe(List<String> einkaufsValue) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(einkaufsKey, einkaufsValue);
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
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    speechToText = SpeechToText();
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
                  items.add(newItems[i]);
                }
                Preferences.setEinkaufsListe(items);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 15),
      body: FutureBuilder(
        key: _futureBuilderKey,
        future: Preferences.getEinkaufsListe(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          items = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  SizedBox(width: 7),
                  Text('Einkaufsliste', style: TextStyle(fontSize: 35)),
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
                            child: Text(
                                'Deine Einkaufsliste ist leer\n\nEinen neuen Eintag kannst du unten rechts hinzufügen, dort findest du auch einen Knopf für Spracheingabe und Liste löschen\n\nEinen Eintrag kannst du entfernen, wenn du auf einen Eintrag gedrückt hälst und auf entfernen klickst\n\nAußerdem kannst du dann rechts über das Icon die Reihenfolge der Einträge ändern'),
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
                              child: ListTile(
                                title: Text(
                                  item,
                                  style: TextStyle(fontSize: 14),
                                ),
                                trailing: ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.menu)),
                                onLongPress: () {
                                  showModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return Card(
                                            child: ListTile(
                                          title: Text(
                                            'Entfernen',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          onTap: () {
                                            items.removeAt(index);
                                            Preferences.setEinkaufsListe(items);
                                            Navigator.pop(context);
                                            setState(() {
                                              _futureBuilderKey = UniqueKey();
                                            });
                                          },
                                        ));
                                      });
                                },
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
                              Preferences.setEinkaufsListe(items);
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
                    _showClearDialog(context);
                  },
                  heroTag: null,
                  child: Icon(Icons.clear_all),
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
                  items.add(textFieldController.text);
                  Preferences.setEinkaufsListe(items);
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
                Preferences.setEinkaufsListe([]);
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
