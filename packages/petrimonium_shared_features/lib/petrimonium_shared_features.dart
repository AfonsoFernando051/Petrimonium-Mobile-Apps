/// Features that genuinely belong to the whole Petrimonium ecosystem rather
/// than to one product.
///
/// The bar for entry is the question from the architecture doc: if we fix or
/// improve this, should Academy, Wallet and Health all receive the change?
/// Gamification clears it - global XP and global level are one number per
/// account, produced by one backend ledger, and a bug in the level maths is a
/// bug in every product at once.
///
/// What stays out: anything whose authoritative rules live in the backend
/// domain (financial calculations, Academy progression, Health scoring), and
/// anything that only looks shared because Academy and Wallet were forked
/// from the same codebase.
library;

export 'src/gamification/data/gamification_remote_datasource.dart';
export 'src/gamification/data/gamification_repository.dart';
export 'src/gamification/domain/gamification_summary.dart';
export 'src/gamification/domain/level_calculator.dart';
export 'src/gamification/domain/level_tier.dart';
export 'src/gamification/domain/player_level.dart';
