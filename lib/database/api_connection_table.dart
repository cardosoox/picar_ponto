import 'dart:async';
import 'package:path/path.dart';
import 'package:picar_ponto/models/api_connection_model.dart';
import 'package:picar_ponto/models/funcionario_model.dart';
import 'package:picar_ponto/models/registo_model.dart';
import 'package:sqflite/sqflite.dart';

const String tableDiasEncerrados = 'dias_encerrados';

class ApiConnectionDatabase {
  ApiConnectionDatabase._init();

  static final ApiConnectionDatabase instance = ApiConnectionDatabase._init();
  static Database? _database;

  //define a bd em sqlite
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('picarPonto.db');
    return _database!;
  }

  //inicializa a bd
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return openDatabase(path, version: 1, onCreate: _createDB);
  }
  //cria a bd
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const datetimeType = 'TEXT NOT NULL';
    const datetimeNullType = 'TEXT';
    const boolType = 'INTEGER NOT NULL';

    //cria a tabela funcionarios
    await db.execute('''
    CREATE TABLE $tableFuncionarios (
      ${FuncionarioFields.id} $idType,
      ${FuncionarioFields.username} $textType,
      ${FuncionarioFields.password} $textType,
      ${FuncionarioFields.nome} $textType,
      ${FuncionarioFields.isAdmin} $boolType
    )
    ''');

    //insere dados na tabela funcionarios
    await db.insert(tableFuncionarios, {
      FuncionarioFields.username: 'admin',
      FuncionarioFields.password: '123',
      FuncionarioFields.nome: 'Chefe Supremo',
      FuncionarioFields.isAdmin: 1,
    });

    await db.insert(tableFuncionarios, {
      FuncionarioFields.username: 'joao',
      FuncionarioFields.password: '456',
      FuncionarioFields.nome: 'João Silva',
      FuncionarioFields.isAdmin: 0,
    });


    //cria a tabela de conexao da bd sqlite

    await db.execute('''
    CREATE TABLE $tableApiConnection (
      ${ApiConnectionFields.id} $idType,
      ${ApiConnectionFields.url} $textType,
      ${ApiConnectionFields.port} $textType,
      ${ApiConnectionFields.connectionString} $textType,
      ${ApiConnectionFields.lastConnection} $datetimeNullType
    )
    ''');


    //cria a tabela de dias encerrados
    await db.execute('''
    CREATE TABLE $tableDiasEncerrados (
      _id $idType,
      data $textType
    )
    ''');
    
    //cria a tabela de registos
    await db.execute('''
    CREATE TABLE $tableRegistos (
      ${RegistoFields.id} $idType,
      ${RegistoFields.nomeFuncionario} $textType,
      ${RegistoFields.entrada} $datetimeType,
      ${RegistoFields.saida} $datetimeNullType,
      dia_id INTEGER 
    )
    ''');
  }

  // funcao para criação da coneccao da api

  Future<ApiConnection> create(ApiConnection apiConnection) async {
    final db = await instance.database;
    final ApiConnection? tmp = await readFirst();
    if (tmp != null) {
      apiConnection.id = tmp.id;
      await update(apiConnection);
      return apiConnection;
    }
    //insere o id da conexao na tabela da apiconection
    final id = await db.insert(tableApiConnection, apiConnection.toJson());
    return apiConnection.copy(id: id);
  }

  // atualiza a conexao da api no sqlite
  Future<ApiConnection?> update(ApiConnection apiConnection) async {
    final db = await instance.database;
    final count = await db.update(
      tableApiConnection,
      apiConnection.toJson(),
      where: '${ApiConnectionFields.id} = ?',
      whereArgs: [apiConnection.id],
    );
    if (count == 0) return null;
    return readFirst();
  }
  // le a conexao da api no sqlite
  Future<ApiConnection?> read(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      tableApiConnection,
      columns: ApiConnectionFields.allValues,
      where: '${ApiConnectionFields.id} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return ApiConnection.fromJson(maps.first);
    return null;
  }

  Future<ApiConnection?> readFirst() async {
    final db = await instance.database;
    final maps = await db.query(
      tableApiConnection,
      columns: ApiConnectionFields.allValues,
    );
    if (maps.isNotEmpty) return ApiConnection.fromJson(maps.first);
    return null;
  }

  Future<int> deleteAll() async {
    final db = await instance.database;
    return db.delete(tableApiConnection);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<Funcionario?> verificarLogin(String username, String password) async {
    final db = await instance.database;
    final result = await db.query(
      tableFuncionarios,
      where:
          '${FuncionarioFields.username} = ? AND ${FuncionarioFields.password} = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) return Funcionario.fromJson(result.first);
    return null;
  }

  Future<RegistoPonto> inserirRegisto(RegistoPonto registo) async {
    final db = await instance.database;
    final id = await db.insert(tableRegistos, registo.toJson());
    return registo.copy(id: id);
  }

  Future<int> atualizarSaida(RegistoPonto registo) async {
    final db = await instance.database;
    return db.update(
      tableRegistos,
      registo.toJson(),
      where: '${RegistoFields.id} = ?',
      whereArgs: [registo.id],
    );
  }

  Future<List<RegistoPonto>> lerRegistosDeHoje() async {
    final db = await instance.database;
    const orderBy = '${RegistoFields.entrada} DESC';
    final result = await db.query(
      tableRegistos,
      where: 'dia_id IS NULL',
      orderBy: orderBy,
    );
    return result.map((json) => RegistoPonto.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> lerHistoricoCompleto() async {
    final db = await instance.database;
    final dias = await db.query(tableDiasEncerrados, orderBy: 'data DESC');

    List<Map<String, dynamic>> resultadoFinal = [];

    for (var dia in dias) {
      final registos = await db.query(
        tableRegistos,
        where: 'dia_id = ?',
        whereArgs: [dia['_id']],
      );

      resultadoFinal.add({
        'data': DateTime.parse(dia['data'] as String),
        'registos': registos
            .map((json) => RegistoPonto.fromJson(json))
            .toList(),
      });
    }
    return resultadoFinal;
  }

  Future<void> encerrarDiaNoSQLite() async {
    final db = await instance.database;

    final diaId = await db.insert(tableDiasEncerrados, {
      'data': DateTime.now().toIso8601String(),
    });

    await db.update(tableRegistos, {'dia_id': diaId}, where: 'dia_id IS NULL');
  }

  Future<RegistoPonto?> buscarRegistoAberto(String nomeFuncionario) async {
    final db = await instance.database;

    final result = await db.query(
      tableRegistos,
      where:
          '${RegistoFields.nomeFuncionario} = ? AND ${RegistoFields.saida} IS NULL AND dia_id IS NULL',
      whereArgs: [nomeFuncionario],
    );

    if (result.isNotEmpty) {
      return RegistoPonto.fromJson(result.first);
    }
    return null;
  }

  Future<int> apagarRegistoUnico(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableRegistos,
      where: '${RegistoFields.id} = ?',
      whereArgs: [id],
    );
  }
}
