import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class EmpleadosPage extends StatefulWidget {
  const EmpleadosPage({super.key});
  @override State<EmpleadosPage> createState() => _EmpleadosPageState();
}

class _EmpleadosPageState extends State<EmpleadosPage> {
  List _empleados = [];
  List _habilidades = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait(<Future<Map<String,dynamic>>>[ApiService.getEmpleados(), ApiService.getHabilidades()]);
    final emps = results[0]; final habs = results[1];
    if (mounted) setState(() {
      _empleados = emps['data'] as List? ?? [];
      _habilidades = habs['data'] as List? ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: PetSpaTheme.purple,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Nuevo Empleado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple))
          : _empleados.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('👷', style: TextStyle(fontSize: 56)), SizedBox(height: 12), Text('Sin empleados', style: TextStyle(color: PetSpaTheme.textSecondary, fontSize: 16))]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: PetSpaTheme.purple,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: _empleados.length,
                    itemBuilder: (_, i) => _buildCard(_empleados[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map e) {
    final roles = {'Groomers': [PetSpaTheme.teal, PetSpaTheme.tealLight], 'Recepción': [PetSpaTheme.purple, PetSpaTheme.purpleLight], 'Personal': [PetSpaTheme.gold, PetSpaTheme.goldLight]};
    final colors = roles[e['rol'] ?? 'Personal'] ?? [PetSpaTheme.purple, PetSpaTheme.purpleLight];
    final active = (e['estado_trabajador'] ?? e['estado'] ?? 'activo') == 'activo';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: PetSpaTheme.bgCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: (colors[0] as Color).withOpacity(0.2)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors.cast<Color>())),
              child: Center(child: Text((e['nombre'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e['nombre'] ?? '—', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
              Text(e['email'] ?? '—', style: const TextStyle(fontSize: 12, color: PetSpaTheme.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              BadgeChip(label: e['rol'] ?? 'Personal', color: colors[0] as Color),
              const SizedBox(height: 4),
              BadgeChip(label: active ? 'Activo' : 'Inactivo', color: active ? PetSpaTheme.success : PetSpaTheme.danger),
            ]),
          ]),
          if (e['nombre_habilidad'] != null || e['sueldo_mensual'] != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(12)), child: Row(children: [
              if (e['nombre_habilidad'] != null) Expanded(child: Row(children: [const Icon(Icons.workspace_premium_outlined, size: 14, color: PetSpaTheme.gold), const SizedBox(width: 6), Text(e['nombre_habilidad'], style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12))])),
              if (e['sueldo_mensual'] != null) Text('Bs. ${e['sueldo_mensual']}', style: const TextStyle(color: PetSpaTheme.tealLight, fontWeight: FontWeight.w700, fontSize: 14)),
            ])),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Btn('✏️ Editar', PetSpaTheme.purple, () => _showForm(emp: e))),
            const SizedBox(width: 8),
            Expanded(child: _Btn('🗑️ Eliminar', PetSpaTheme.danger, () => _delete(e['id_usuario'] ?? e['id_trabajadores']))),
          ]),
        ]),
      ),
    );
  }

  void _showForm({Map? emp}) {
    final nameCtrl = TextEditingController(text: emp?['nombre'] ?? '');
    final emailCtrl = TextEditingController(text: emp?['email'] ?? '');
    final passCtrl = TextEditingController();
    final sueldoCtrl = TextEditingController(text: emp?['sueldo_mensual']?.toString() ?? '');
    String rol = emp?['rol'] ?? 'Groomers';
    int? habId = emp?['id_habilidad'] as int?;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(emp == null ? '👷 Nuevo Empleado' : '✏️ Editar Empleado', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          PetSpaTextField(controller: nameCtrl, label: 'Nombre completo *', icon: Icons.person_outline),
          const SizedBox(height: 12),
          if (emp == null) ...[
            PetSpaTextField(controller: emailCtrl, label: 'Email *', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            PetSpaTextField(controller: passCtrl, label: 'Contraseña *', icon: Icons.lock_outline, obscure: true),
            const SizedBox(height: 12),
          ],
          Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: rol, dropdownColor: PetSpaTheme.bgCard2, style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
                items: ['Groomers', 'Recepción', 'Personal'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setS(() => rol = v ?? rol),
              )),
            )),
            const SizedBox(width: 12),
            Expanded(child: PetSpaTextField(controller: sueldoCtrl, label: 'Sueldo (Bs.)', icon: Icons.attach_money, keyboardType: TextInputType.number)),
          ]),
          if (_habilidades.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
              child: DropdownButtonHideUnderline(child: DropdownButton<int?>(isExpanded: true, value: habId, dropdownColor: PetSpaTheme.bgCard2, style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
                hint: const Text('Habilidad (opcional)', style: TextStyle(color: PetSpaTheme.textSecondary)),
                items: [const DropdownMenuItem<int?>(value: null, child: Text('Sin habilidad')), ..._habilidades.map((h) => DropdownMenuItem<int?>(value: h['id_habilidad'] as int?, child: Text(h['nombre_habilidad'] ?? '—')))],
                onChanged: (v) => setS(() => habId = v),
              )),
            ),
          ],
          const SizedBox(height: 20),
          GradientButton(
            text: emp == null ? 'Crear Empleado' : 'Guardar Cambios',
            onPressed: () async {
              final res = emp == null
                  ? await ApiService.registroEmpleado({'nombre': nameCtrl.text, 'email': emailCtrl.text, 'password': passCtrl.text, 'rol': rol, 'sueldo_mensual': double.tryParse(sueldoCtrl.text) ?? 0, 'id_habilidad': habId})
                  : await ApiService.updateEmpleado(emp['id_usuario'] ?? emp['id_trabajadores'], {'nombre': nameCtrl.text, 'rol': rol, 'sueldo_mensual': double.tryParse(sueldoCtrl.text) ?? 0, 'id_habilidad': habId, 'estado_trabajador': 'activo'});
              if (!mounted) return;
              Navigator.pop(ctx);
              if (res['success'] == true) { PetSpaSnack.show(context, res['message'] ?? 'Guardado'); _load(); }
              else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
            },
          ),
        ]),
      )),
    );
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: PetSpaTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('¿Eliminar empleado?', style: TextStyle(color: PetSpaTheme.textPrimary)),
      content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: PetSpaTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: PetSpaTheme.danger), onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
      ],
    ));
    if (confirm != true) return;
    final res = await ApiService.deleteEmpleado(id);
    if (!mounted) return;
    if (res['success'] != false) { PetSpaSnack.show(context, 'Empleado eliminado'); _load(); }
    else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
  }
}

class _Btn extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;
  const _Btn(this.text, this.color, this.onPressed);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 9), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.35))),
    child: Center(child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)))),
  );
}
