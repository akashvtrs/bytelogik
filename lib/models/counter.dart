class CounterModel {
  final String userId;
  final int value;

  CounterModel({required this.userId, required this.value});

  Map<String, dynamic> toMap() => {'userId': userId, 'value': value};

  factory CounterModel.fromMap(Map<String, dynamic> map) =>
      CounterModel(userId: map['userId'], value: map['value']);
}
