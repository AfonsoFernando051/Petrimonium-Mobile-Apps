import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

class AssetRegistrationModel {
  final String name;
  final double quantity;
  final double purchasePrice;
  final String purchaseDate;
  final InvestmentTypeEnum type;

  AssetRegistrationModel({
    required this.name,
    required this.quantity,
    required this.purchasePrice,
    required this.purchaseDate,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate,
      'type': type.name,
    };
  }
}
