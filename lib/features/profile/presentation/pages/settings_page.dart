import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// ── Notificações ───────────────────────────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _purchases  = true;
  bool _sales      = true;
  bool _escrow     = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notificações',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsCard(children: [
            _SwitchTile(
              icon: CupertinoIcons.bag,
              label: 'Compras',
              subtitle: 'Atualizações dos seus pedidos',
              value: _purchases,
              onChanged: (v) => setState(() => _purchases = v),
            ),
            const Divider(height: 1, indent: 52, color: AppColors.divider),
            _SwitchTile(
              icon: CupertinoIcons.storefront,
              label: 'Vendas',
              subtitle: 'Novos pedidos recebidos',
              value: _sales,
              onChanged: (v) => setState(() => _sales = v),
            ),
            const Divider(height: 1, indent: 52, color: AppColors.divider),
            _SwitchTile(
              icon: CupertinoIcons.lock_shield,
              label: 'Escrow',
              subtitle: 'Liberação de pagamentos',
              value: _escrow,
              onChanged: (v) => setState(() => _escrow = v),
            ),
            const Divider(height: 1, indent: 52, color: AppColors.divider),
            _SwitchTile(
              icon: CupertinoIcons.bell,
              label: 'Promoções',
              subtitle: 'Ofertas e novidades da plataforma',
              value: _promotions,
              onChanged: (v) => setState(() => _promotions = v),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Segurança ──────────────────────────────────────────────────────────────────
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Segurança',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsCard(children: [
            _NavTile(
              icon: CupertinoIcons.lock_rotation,
              label: 'Alterar senha',
              onTap: () => _showChangePasswordSheet(context),
            ),
            const Divider(height: 1, indent: 52, color: AppColors.divider),
            _NavTile(
              icon: CupertinoIcons.device_phone_portrait,
              label: 'Autenticação em dois fatores',
              subtitle: 'Recomendado',
              onTap: () {},
            ),
            const Divider(height: 1, indent: 52, color: AppColors.divider),
            _NavTile(
              icon: CupertinoIcons.list_bullet_below_rectangle,
              label: 'Sessões ativas',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 20),
          _SettingsCard(children: [
            _NavTile(
              icon: CupertinoIcons.delete,
              label: 'Excluir conta',
              color: AppColors.error,
              onTap: () => _confirmDeleteAccount(context),
            ),
          ]),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Excluir conta'),
        content: const Text('Esta ação é irreversível. Todos os seus dados serão removidos.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Excluir'),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _newPassCtrl    = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  bool _obscure1 = true, _obscure2 = true, _saving = false;

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4,
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Alterar senha',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            _PassField(controller: _newPassCtrl,     label: 'Nova senha',     obscure: _obscure1, onToggle: () => setState(() => _obscure1 = !_obscure1)),
            const SizedBox(height: 12),
            _PassField(controller: _confirmCtrl,     label: 'Confirmar senha', obscure: _obscure2, onToggle: () => setState(() => _obscure2 = !_obscure2)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : () async {
                if (_newPassCtrl.text != _confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('As senhas não coincidem'),
                    backgroundColor: AppColors.error,
                  ));
                  return;
                }
                setState(() => _saving = true);
                // TODO: chamar supabase.auth.updateUser(password: ...)
                await Future.delayed(const Duration(seconds: 1));
                if (mounted) Navigator.pop(context);
              },
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar senha'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  const _PassField({required this.controller, required this.label, required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 20, color: AppColors.textSecondary),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ── Ajuda e Suporte ────────────────────────────────────────────────────────────
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ajuda e suporte',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsCard(children: [
            _NavTile(icon: CupertinoIcons.chat_bubble_text, label: 'Chat com suporte', onTap: () {}),
            const Divider(height: 1, indent: 52, color: AppColors.divider),
            _NavTile(icon: CupertinoIcons.question_circle,  label: 'Perguntas frequentes', onTap: () {}),
            const Divider(height: 1, indent: 52, color: AppColors.divider),
            _NavTile(icon: CupertinoIcons.doc_text,         label: 'Termos de uso', onTap: () {}),
            const Divider(height: 1, indent: 52, color: AppColors.divider),
            _NavTile(icon: CupertinoIcons.shield,           label: 'Política de privacidade', onTap: () {}),
          ]),
          const SizedBox(height: 20),
          Center(
            child: Text('Fluxa v1.0.0',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withOpacity(0.6))),
          ),
        ],
      ),
    );
  }
}

// ── Componentes compartilhados ─────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon, required this.label,
    this.subtitle, required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary)),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon, required this.label,
    this.subtitle, this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 15, color: c)),
                  if (subtitle != null)
                    Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: 16,
                color: color?.withOpacity(0.5) ?? AppColors.divider),
          ],
        ),
      ),
    );
  }
}
