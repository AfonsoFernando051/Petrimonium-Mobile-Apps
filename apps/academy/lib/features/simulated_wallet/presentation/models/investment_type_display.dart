import 'package:flutter/material.dart';
import 'package:petrimonium_academy/core/constants/app_colors.dart';
import 'package:petrimonium_shared_features/petrimonium_shared_features.dart';

/// UI presentation (label/icon/color) for each [InvestmentTypeEnum] — a copy
/// of `features/portfolio`'s own `InvestmentTypeDisplay` (same fork, same
/// values) rather than an import from it: the simulated wallet is
/// deliberately independent of Academy's dead real-portfolio feature (see
/// `SimulatedWalletScreen`'s class doc), so it never reaches across that
/// boundary even for a presentation-only extension.
extension InvestmentTypeDisplay on InvestmentTypeEnum {
  String get label => switch (this) {
    InvestmentTypeEnum.STOCKS => 'Ações',
    InvestmentTypeEnum.FIXED_INCOME => 'Renda Fixa',
    InvestmentTypeEnum.REAL_ESTATE => 'Fundos Imobiliários',
    InvestmentTypeEnum.CRYPTO => 'Cripto',
    InvestmentTypeEnum.FUNDS => 'ETFs & Fundos',
    InvestmentTypeEnum.OTHERS => 'Outros',
  };

  String get shortLabel => switch (this) {
    InvestmentTypeEnum.STOCKS => 'Ações',
    InvestmentTypeEnum.FIXED_INCOME => 'R. Fixa',
    InvestmentTypeEnum.REAL_ESTATE => 'FIIs',
    InvestmentTypeEnum.CRYPTO => 'Cripto',
    InvestmentTypeEnum.FUNDS => 'ETFs',
    InvestmentTypeEnum.OTHERS => 'Outros',
  };

  IconData get icon => switch (this) {
    InvestmentTypeEnum.STOCKS => Icons.show_chart,
    InvestmentTypeEnum.FIXED_INCOME => Icons.account_balance,
    InvestmentTypeEnum.REAL_ESTATE => Icons.apartment,
    InvestmentTypeEnum.CRYPTO => Icons.currency_bitcoin,
    InvestmentTypeEnum.FUNDS => Icons.pie_chart,
    InvestmentTypeEnum.OTHERS => Icons.category,
  };

  Color get color => switch (this) {
    InvestmentTypeEnum.STOCKS => AppColors.neonCyan,
    InvestmentTypeEnum.FIXED_INCOME => AppColors.positiveGreen,
    InvestmentTypeEnum.REAL_ESTATE => AppColors.goldenBorder,
    InvestmentTypeEnum.CRYPTO => AppColors.neonPink,
    InvestmentTypeEnum.FUNDS => AppColors.neonPurple,
    InvestmentTypeEnum.OTHERS => AppColors.subtleText,
  };
}
