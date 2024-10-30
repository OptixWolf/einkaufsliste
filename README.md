# Einkaufsliste

![version](https://img.shields.io/badge/version-2.1.1-blue)

## Deutsch

Eine einfache Einkaufsliste mit den folgenden Funktionen

- Dunkler und heller Modus
- Hinzufügen über Text und Sprache zu Text (stt)
- Gleichzeitiges Hinzufügen mehrerer Einträge mit Sprache zu Text (Trennzeichen "und")
- Ändern der Reihenfolge der Einträge
- Bearbeiten/Löschen einzelner Einträge
- Alles löschen

### So richtest du Arktox mit deiner eigenen Datenbank ein

> [!IMPORTANT]
> Um das Projekt auszuführen, musst du [Flutter](https://docs.flutter.dev/get-started/install) installiert haben

Schritt 1: Lade das Projekt [hier](https://github.com/OptixWolf/Arktox/archive/refs/heads/main.zip) herunter  
Schritt 2: Erstelle eine MySQL Datenbank  
Schritt 3: Erstelle eine Datenbank mit einer Tabelle "items" die folgende Spalten enthält "item_id" und "item"  
Schritt 4: Erstelle die Datei keys.dart im lib Ordner  
Schritt 5: Füge den folgenden Code in die Datei keys.dart ein und ersetze die Werte mit deinen eigenen
```dart
const host = 'youripadress';
const port = yourport;
const user = 'youruser';
const password = 'yourpassword';
const databaseName = 'einkaufsliste';
```
Schritt 6: Führe `flutter pub get` aus  
Schritt 7: Erstelle das Projekt (Wähle Android für volle Funktionalität)

## English

A simple shopping list with the following functions

- Dark and light mode
- Add via text and speech to text (stt)
- Add several entries at the same time with language to text (separator "und")
- Change the order of the entries
- Edit/delete individual entries
- Delete all

### How to set up Arktox with your own database

> [!IMPORTANT]
> To run the project, you must have [Flutter](https://docs.flutter.dev/get-started/install) installed

Step 1: Download the project [here](https://github.com/OptixWolf/Arktox/archive/refs/heads/main.zip)  
Step 2: Create a MySQL database  
Step 3: Create a database with a table "items" containing the following columns “item_id” and “item”  
Step 4: Create the file keys.dart in the lib folder  
Step 5: Paste the following code into the keys.dart file and replace the values with your own
```dart
const host = 'youripadress';
const port = yourport;
const user = 'youruser';
const password = 'yourpassword';
const databaseName = 'einkaufsliste';
```
Step 6: Execute `flutter pub get`  
Step 7: Create the project (Choose Android for full functionality)
