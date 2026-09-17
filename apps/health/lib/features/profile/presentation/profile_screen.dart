import 'package:flutter/material.dart';
import 'package:petrimonium_flutter_core/petrimonium_flutter_core.dart';

import '../../../core/app/health_scope.dart';
import '../../../core/theme/health_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../health/domain/pet_species.dart';
import '../../health/presentation/health_controller.dart';

/// `subIsProfile`. Regional settings persist in the Health profile while the
/// account identity and Pet remain shared with the other Petrimonium apps.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HealthScope.of(context);
    final l10n = AppLocalizations.of(context);
    final name = controller.account?.username;

    return Scaffold(
      backgroundColor: HealthColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: controller.navigation.closeSubScreen,
                    borderRadius: BorderRadius.circular(16),
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(Icons.arrow_back, size: 18, color: HealthColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ClipOval(child: Image.asset(PetSpecies.fox.assetPath, width: 26, height: 26, fit: BoxFit.contain)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.profileTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: HealthColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipOval(child: Image.asset(PetSpecies.fox.assetPath, width: 48, height: 48, fit: BoxFit.contain)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (name != null && name.isNotEmpty)
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: HealthColors.textPrimary,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.profileSharedAccountNote,
                                style: const TextStyle(fontSize: 12, color: HealthColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _ProfileRow(
                      label: l10n.profileRegionalSettings,
                      onTap: controller.navigation.openRegionalPreferences,
                    ),
                    const SizedBox(height: 12),
                    _ProfileRow(label: l10n.profileMentorPreferences, onTap: controller.navigation.openMentor),
                    const SizedBox(height: 12),
                    _ProfileRow(label: l10n.profileAccountsAndCards, onTap: controller.navigation.openAccounts),
                    const SizedBox(height: 12),
                    _ProfileRow(label: l10n.logout, danger: true, onTap: controller.logout),
                    const SizedBox(height: 12),
                    _ProfileRow(
                      label: l10n.deleteAccount,
                      danger: true,
                      onTap: () => _confirmDeleteAccount(context, l10n),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo obrigatório antes de apagar: ao contrário do logout, isto não tem
/// volta. O botão destrutivo fica à direita e em vermelho; o pedido é
/// cancelado se o utilizador tocar fora.
Future<void> _confirmDeleteAccount(BuildContext context, AppLocalizations l10n) async {
  final controller = HealthScope.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: HealthColors.card,
      title: Text(l10n.deleteAccountConfirmTitle),
      content: Text(
        l10n.deleteAccountConfirmMessage,
        style: const TextStyle(fontSize: 13.5, height: 1.4, color: HealthColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel, style: const TextStyle(color: HealthColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.deleteAccount, style: const TextStyle(color: HealthColors.negative)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  // Confirmar a intenção e provar a identidade são duas perguntas diferentes, e é a segunda
  // que uma sessão roubada não sabe responder. O backend recusa esta chamada sem credencial.
  final credential = await _askForCredential(context, l10n, controller);
  if (credential == null) return;

  try {
    await controller.deleteAccount(password: credential.password, googleIdToken: credential.googleIdToken);
  } on InvalidCredentialsException {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deleteAccountWrongCredential)));
  } catch (_) {
    // A conta continua a existir. Sem isto o erro só chegava ao handler da
    // zone e o ecrã ficava igual, com o utilizador a achar que foi apagada —
    // `controller.error` só é lido pela HomeScreen, nunca aqui.
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError)));
  }
}

/// O que o utilizador apresentou para se reautenticar. Exatamente um dos campos vem preenchido.
class _Credential {
  const _Credential.password(String this.password) : googleIdToken = null;
  const _Credential.google(String this.googleIdToken) : password = null;

  final String? password;
  final String? googleIdToken;
}

/// Oferece as duas vias porque uma conta tem uma ou outra: a local tem senha, a criada pelo
/// Google não tem nenhuma, e uma local mais tarde ligada ao Google tem as duas. O cliente não
/// tem registo fiável do provedor da conta, por isso não adivinha — quem decide se a credencial
/// serve é o backend.
Future<_Credential?> _askForCredential(BuildContext context, AppLocalizations l10n, HealthController controller) {
  return showDialog<_Credential>(
    context: context,
    builder: (dialogContext) => _ReauthenticateDialog(l10n: l10n, controller: controller),
  );
}

class _ReauthenticateDialog extends StatefulWidget {
  const _ReauthenticateDialog({required this.l10n, required this.controller});

  final AppLocalizations l10n;
  final HealthController controller;

  @override
  State<_ReauthenticateDialog> createState() => _ReauthenticateDialogState();
}

class _ReauthenticateDialogState extends State<_ReauthenticateDialog> {
  final TextEditingController _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submitPassword() {
    if (_password.text.isEmpty) return;
    Navigator.of(context).pop(_Credential.password(_password.text));
  }

  Future<void> _submitGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    String? idToken;
    try {
      idToken = await widget.controller.obtainGoogleIdToken();
    } catch (_) {
      // Um fluxo do Google falhado ou cancelado deixa o diálogo aberto, para o utilizador
      // ainda poder usar o campo da senha em vez de voltar ao perfil sem explicação.
      idToken = null;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (idToken == null || idToken.isEmpty) return;
    Navigator.of(context).pop(_Credential.google(idToken));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      backgroundColor: HealthColors.card,
      title: Text(l10n.deleteAccountReauthTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.deleteAccountReauthMessage,
            style: const TextStyle(fontSize: 13.5, height: 1.4, color: HealthColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            enabled: !_busy,
            decoration: InputDecoration(labelText: l10n.deleteAccountPasswordLabel),
            onSubmitted: (_) => _submitPassword(),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _busy ? null : _submitGoogle, child: Text(l10n.deleteAccountGoogleButton)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: const TextStyle(color: HealthColors.textSecondary)),
        ),
        TextButton(
          onPressed: _busy ? null : _submitPassword,
          child: Text(l10n.deleteAccount, style: const TextStyle(color: HealthColors.negative)),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, this.danger = false, this.onTap});

  final String label;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: HealthColors.inputFill,
          border: Border.all(color: HealthColors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: danger ? HealthColors.negative : HealthColors.textPrimary),
              ),
            ),
            const Text('›', style: TextStyle(color: HealthColors.textMuted, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
