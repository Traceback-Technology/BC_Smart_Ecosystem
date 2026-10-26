import 'package:flutter/material.dart';
import '../services/bc_eats_store.dart';
import 'eats_order_widgets.dart';

Future<void> editEatsNotes(BuildContext context) async {
  final store = BcEatsStore.instance;
  final value = await showDialog<String>(context: context, builder: (_) => _NotesDialog(initial: store.notes));
  if (value != null) store.updateNotes(value);
}
class _NotesDialog extends StatefulWidget {
  final String initial;
  const _NotesDialog({required this.initial});
  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}
class _NotesDialogState extends State<_NotesDialog> {
  late final controller = TextEditingController(text: widget.initial);
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Special Instructions'),
    content: TextField(controller: controller, maxLength: 300, minLines: 2, maxLines: 4,
      decoration: const InputDecoration(hintText: 'Add any notes (optional)')),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save'))]);
}
Future<void> editEatsContact(BuildContext context) => showDialog<void>(context: context, builder: (_) => const _ContactDialog());
class _ContactDialog extends StatefulWidget {
  const _ContactDialog();
  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}
class _ContactDialogState extends State<_ContactDialog> {
  final form = GlobalKey<FormState>();
  final store = BcEatsStore.instance;
  late final name = TextEditingController(text: store.customerName);
  late final phone = TextEditingController(text: store.phone);
  late final email = TextEditingController(text: store.email);
  @override
  void dispose() { name.dispose(); phone.dispose(); email.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Contact Details'),
    content: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Name and surname'),
        validator: (value) => (value ?? '').trim().length < 2 ? 'Enter your name.' : null),
      TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone number'),
        validator: (value) => (value ?? '').replaceAll(RegExp(r'\D'), '').length < 7 ? 'Enter a valid phone number.' : null),
      TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (optional)'),
        validator: (value) => (value ?? '').trim().isEmpty || RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim()) ? null : 'Enter a valid email.'),
    ]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      TextButton(onPressed: () { if (form.currentState!.validate()) { store.updateContact(name.text.trim(), phone.text.trim(), email.text.trim()); Navigator.pop(context); } }, child: const Text('Save'))]);
}
Future<void> scheduleEatsOrder(BuildContext context) async {
  final now = DateTime.now();
  final day = await showDatePicker(context: context, firstDate: DateTime(now.year, now.month, now.day),
    lastDate: now.add(const Duration(days: 7)), initialDate: now);
  if (day == null || !context.mounted) return;
  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))));
  if (time == null || !context.mounted) return;
  final scheduled = DateTime(day.year, day.month, day.day, time.hour, time.minute);
  if (!scheduled.isAfter(DateTime.now().add(const Duration(minutes: 15)))) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose a time at least 15 minutes from now.'))); return;
  }
  BcEatsStore.instance.schedule(scheduled);
}
String eatsDate(BuildContext context, DateTime value) => '${value.day} ${const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][value.month - 1]} ${value.year}, ${TimeOfDay.fromDateTime(value).format(context)}';
Future<void> eatsPromo(BuildContext context) => showDialog<void>(context: context, builder: (_) => const _PromoDialog());
class _PromoDialog extends StatefulWidget {
  const _PromoDialog();
  @override
  State<_PromoDialog> createState() => _PromoDialogState();
}
class _PromoDialogState extends State<_PromoDialog> {
  String? error;
  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Have a promo code?'),
    content: TextField(textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(labelText: 'Promo code', errorText: error)),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      TextButton(onPressed: () => setState(() => error = 'Promo codes are not available in this demo.'), child: const Text('Apply'))]);
}

Widget eatsDemoNotice(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(
  'Demo checkout · no payment is taken', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: context.eatsMuted)));
