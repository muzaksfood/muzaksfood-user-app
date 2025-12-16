class SavedPaymentMethod {
  final String id;
  final String method;
  final String? cardNumber;
  final String? cardholderName;
  final String? expiryDate;
  final bool isDefault;
  final DateTime createdAt;

  SavedPaymentMethod({
    required this.id,
    required this.method,
    this.cardNumber,
    this.cardholderName,
    this.expiryDate,
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'cardNumber': cardNumber,
      'cardholderName': cardholderName,
      'expiryDate': expiryDate,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    return SavedPaymentMethod(
      id: json['id'] as String,
      method: json['method'] as String,
      cardNumber: json['cardNumber'] as String?,
      cardholderName: json['cardholderName'] as String?,
      expiryDate: json['expiryDate'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  SavedPaymentMethod copyWith({
    String? id,
    String? method,
    String? cardNumber,
    String? cardholderName,
    String? expiryDate,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return SavedPaymentMethod(
      id: id ?? this.id,
      method: method ?? this.method,
      cardNumber: cardNumber ?? this.cardNumber,
      cardholderName: cardholderName ?? this.cardholderName,
      expiryDate: expiryDate ?? this.expiryDate,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
