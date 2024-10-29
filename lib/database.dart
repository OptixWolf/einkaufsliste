import 'package:mysql_client/mysql_client.dart';
import 'keys.dart';

class DatabaseService {
  late MySQLConnection _conn;

  Future<void> connect() async {
    _conn = await MySQLConnection.createConnection(
      host: host,
      port: port,
      userName: user,
      password: password,
      databaseName: databaseName,
      secure: false,
    );

    await _conn.connect();
    print('Datenbank verbunden');
  }

  Future<void> disconnect() async {
    await _conn.close();
    print('Datenbank getrennt');
  }

  Future<List<Map<String, dynamic>>> executeQuery(String query) async {
    await connect();
    var result = await _conn.execute(query);
    await disconnect();
    return result.rows.map((row) => row.assoc()).toList();
  }
}
