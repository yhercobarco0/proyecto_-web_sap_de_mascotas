import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});
  @override State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  List _clientes = [];
  List _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getClientes();
    if (mounted) setState(() {
      _clientes = res['data'] as List? ?? [];
      _filtered = _clientes;
      _loading = false;
    });
  }

  void _filter(String q) => setState(() => _filtered = q.isEmpty ? _clientes : _clientes.where((c) =>
    (c['nombre'] ?? '').toLowerCase().contains(q.toLowerCase()) ||
    (c['email'] ?? '').toLowerCase().contains(q.toLowerCase()) ||
    (c['telefono'] ?? '').contains(q)
  ).toList());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        // HEADER
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [PetSpaTheme.purple.withOpacity(0.2), PetSpaTheme.teal.withOpacity(0.15)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PetSpaTheme.purple.withOpacity(0.2)),
          ),
          child: Row(children: [
            const Text('👥', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Gestión de Clientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
              Text('${_clientes.length} clientes registrados', style: const TextStyle(fontSize: 12, color: PetSpaTheme.textSecondary)),
            ])),
          ]),
        ),
        // SEARCH
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            controller: _search,
            onChanged: _filter,
            style: const TextStyle(color: PetSpaTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, email, teléfono...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _search.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _search.clear(); _filter(''); }) : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // LIST
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple))
              : _filtered.isEmpty
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('👥', style: TextStyle(fontSize: 56)), SizedBox(height: 12), Text('Sin clientes encontrados', style: TextStyle(color: PetSpaTheme.textSecondary, fontSize: 16))]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: PetSpaTheme.purple,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildCard(_filtered[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildCard(Map c) {
    final active = (c['estado'] ?? 'activo') == 'activo';
    final initials = (c['nombre'] ?? '?').isNotEmpty ? (c['nombre'] as String)[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PetSpaTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: PetSpaTheme.gradientPurpleTeal),
          child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(c['nombre'] ?? '—', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary))),
            BadgeChip(label: active ? 'Activo' : 'Inactivo', color: active ? PetSpaTheme.success : PetSpaTheme.danger),
          ]),
          const SizedBox(height: 4),
          Text(c['email'] ?? '—', style: const TextStyle(fontSize: 12, color: PetSpaTheme.textSecondary)),
          if (c['telefono'] != null) ...[
            const SizedBox(height: 2),
            Row(children: [const Icon(Icons.phone_outlined, size: 12, color: PetSpaTheme.textSecondary), const SizedBox(width: 4), Text(c['telefono'], style: const TextStyle(fontSize: 11, color: PetSpaTheme.textSecondary))]),
          ],
          if (c['direccion'] != null) ...[
            const SizedBox(height: 2),
            Row(children: [const Icon(Icons.location_on_outlined, size: 12, color: PetSpaTheme.textSecondary), const SizedBox(width: 4), Expanded(child: Text(c['direccion'], style: const TextStyle(fontSize: 11, color: PetSpaTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis))]),
          ],
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Btn2('✏️ Editar', PetSpaTheme.purple, () => _showEdit(c))),
            const SizedBox(width: 8),
            Expanded(child: _Btn2('🗑️ Eliminar', PetSpaTheme.danger, () => _delete(c['id_usuario'] ?? c['id_cliente']))),
          ]),
        ])),
      ]),
    );
  }

  void _showEdit(Map c) {
    final nameCtrl = TextEditingController(text: c['nombre'] ?? '');
    final telCtrl = TextEditingController(text: c['telefono'] ?? '');
    final dirCtrl = TextEditingController(text: c['direccion'] ?? '');
    String estado = c['estado'] ?? 'activo';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('✏️ Editar Cliente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          PetSpaTextField(controller: nameCtrl, label: 'Nombre', icon: Icons.person_outline),
          const SizedBox(height: 12),
          PetSpaTextField(controller: telCtrl, label: 'Teléfono', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          PetSpaTextField(controller: dirCtrl, label: 'Dirección', icon: Icons.location_on_outlined),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: estado, dropdownColor: PetSpaTheme.bgCard2, style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
              items: ['activo', 'inactivo'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setS(() => estado = v ?? estado),
            )),
          ),
          const SizedBox(height: 20),
          GradientButton(text: 'Guardar Cambios', onPressed: () async {
            final id = c['id_usuario'] ?? c['id_cliente'];
            final res = await ApiService.updateCliente(id, {'nombre': nameCtrl.text, 'telefono': telCtrl.text, 'direccion': dirCtrl.text, 'estado': estado});
            if (!mounted) return;
            Navigator.pop(ctx);
            if (res['success'] != false) { PetSpaSnack.show(context, 'Cliente actualizado'); _load(); }
            else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
          }),
        ]),
      )),
    );
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: PetSpaTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('¿Eliminar cliente?', style: TextStyle(color: PetSpaTheme.textPrimary)),
      content: const Text('Se eliminarán todos sus datos asociados.', style: TextStyle(color: PetSpaTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: PetSpaTheme.danger), onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
      ],
    ));
    if (confirm != true) return;
    final res = await ApiService.deleteCliente(id);
    if (!mounted) return;
    if (res['success'] != false) { PetSpaSnack.show(context, 'Cliente eliminado'); _load(); }
    else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
  }
}

class _Btn2 extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;
  const _Btn2(this.text, this.color, this.onPressed);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.35))),
    child: Center(child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)))),
  );
}
