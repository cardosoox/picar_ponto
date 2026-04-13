const String tableRegistos = 'registos_ponto';

class RegistoFields {
  static final List<String> allValues = [id, nomeFuncionario, entrada, saida];

  static const String id = '_id';
  static const String nomeFuncionario = 'nomeFuncionario';
  static const String entrada = 'entrada';
  static const String saida = 'saida';
}

class RegistoPonto {
  final int? id;
  final String nomeFuncionario;
  final DateTime entrada;
  final DateTime? saida; 

  RegistoPonto({
    this.id,
    required this.nomeFuncionario,
    required this.entrada,
    this.saida,
  });

  static RegistoPonto fromJson(Map<String, dynamic> json) => RegistoPonto(
        id: json[RegistoFields.id] as int?,
        nomeFuncionario: json[RegistoFields.nomeFuncionario] as String,
        entrada: DateTime.parse(json[RegistoFields.entrada] as String),
        saida: json[RegistoFields.saida] != null 
               ? DateTime.parse(json[RegistoFields.saida] as String) 
               : null,
      );

  Map<String, Object?> toJson() => {
        RegistoFields.id: id,
        RegistoFields.nomeFuncionario: nomeFuncionario,
        RegistoFields.entrada: entrada.toIso8601String(),
        RegistoFields.saida: saida?.toIso8601String(),
      };

  RegistoPonto copy({
    int? id,
    String? nomeFuncionario,
    DateTime? entrada,
    DateTime? saida,
  }) => RegistoPonto(
        id: id ?? this.id,
        nomeFuncionario: nomeFuncionario ?? this.nomeFuncionario,
        entrada: entrada ?? this.entrada,
        saida: saida ?? this.saida,
      );
}