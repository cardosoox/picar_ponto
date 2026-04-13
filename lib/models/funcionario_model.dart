const String tableFuncionarios = 'funcionarios';

class FuncionarioFields {
  static final List<String> allValues = [id, username, password, nome, isAdmin];

  static const String id = '_id';
  static const String username = 'username';
  static const String password = 'password';
  static const String nome = 'nome';
  static const String isAdmin = 'isAdmin';
}

class Funcionario {
  final int? id;
  final String username;
  final String password;
  final String nome;
  final bool isAdmin;

  Funcionario({
    this.id,
    required this.username,
    required this.password,
    required this.nome,
    required this.isAdmin,
  });

  static Funcionario fromJson(Map<String, dynamic> json) => Funcionario(
        id: json[FuncionarioFields.id] as int?,
        username: json[FuncionarioFields.username] as String,
        password: json[FuncionarioFields.password] as String,
        nome: json[FuncionarioFields.nome] as String,
        isAdmin: json[FuncionarioFields.isAdmin] == 1,
      );

  Map<String, Object?> toJson() => {
        FuncionarioFields.id: id,
        FuncionarioFields.username: username,
        FuncionarioFields.password: password,
        FuncionarioFields.nome: nome,
        FuncionarioFields.isAdmin: isAdmin ? 1 : 0, 
      };
}