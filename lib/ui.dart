import 'package:flutter/material.dart';
import 'theme.dart';

String formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Bom dia,';
  if (hour < 18) return 'Boa tarde,';
  return 'Boa noite,';
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
  ));
}

Future<bool> confirmDelete(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir publicação?'),
        content: Text('Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('Excluir')),
        ],
      ),
    ) ?? false;

class CenterColumn extends StatelessWidget {
  const CenterColumn({super.key, required this.child, this.maxWidth = 1000});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.color = Colors.white, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final plain = color == Colors.white || color == CampusColors.neutral;
    final cardColor = dark
        ? (plain ? const Color(0xFF161D29)
            : Color.lerp(color, const Color(0xFF161D29), .78)!)
        : color;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: color == Colors.white && !dark
            ? Border.all(color: CampusColors.line) : null,
      ),
      child: child,
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(children: [
          Expanded(child: Text(text, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface))),
          if (trailing != null) trailing!,
        ]),
      );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = CampusColors.lavenderBlue});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(25)),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CampusColors.navyDark)),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => SoftCard(
        color: CampusColors.neutral,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(children: [
            Icon(icon, size: 38, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      );
}

class ModuleLayout extends StatelessWidget {
  const ModuleLayout({super.key, required this.title, required this.subtitle, required this.body, this.action});
  final String title;
  final String subtitle;
  final Widget body;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Meu Campus')),
        body: SafeArea(
          child: CenterColumn(child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 45),
            children: [
              Text(title, style: TextStyle(fontSize: 31, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 7),
              Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15)),
              const SizedBox(height: 22),
              if (action != null) ...[action!, const SizedBox(height: 20)],
              body,
            ],
          )),
        ),
      );
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({super.key, required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 19),
          label: Text(label),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13)),
        ),
      );
}

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 9),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 17, color: CampusColors.navy),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
        ]),
      );
}

class DeleteAction extends StatelessWidget {
  const DeleteAction({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onPressed,
        tooltip: 'Excluir',
        icon: const Icon(Icons.delete_outline, color: Color(0xFFAD4A4A)),
      );
}

InputDecoration fieldDecoration(String label, {String? hint}) =>
    InputDecoration(labelText: label, hintText: hint);

String? requiredField(String? value) =>
    value == null || value.trim().isEmpty ? 'Preencha este campo.' : null;
