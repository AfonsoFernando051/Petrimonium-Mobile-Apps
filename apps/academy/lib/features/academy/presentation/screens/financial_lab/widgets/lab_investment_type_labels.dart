import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';
import 'package:petrimonium_academy/core/presentation/investment_type_labels.dart';

extension LabInvestmentTypeLabel on InvestmentTypeEnum {
  String get labLabel => InvestmentTypeLabels.label(this);
}
