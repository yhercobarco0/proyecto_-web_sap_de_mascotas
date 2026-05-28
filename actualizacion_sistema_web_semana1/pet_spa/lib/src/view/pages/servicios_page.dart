import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class ServiciosPage extends StatefulWidget {
  const ServiciosPage({super.key});
  @override State<ServiciosPage> createState() => _ServiciosPageState();
}

class _ServiciosPageState extends State<ServiciosPage> {
  List _servicios = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getServicios();
    if (mounted) setState(() { _servicios = res['data'] as List? ?? []; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ApiService.role == 'Administrador';
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: PetSpaTheme.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Servicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ) : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple))
          : RefreshIndicator(
              onRefresh: _load,
              color: PetSpaTheme.purple,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  // SERVICES IMAGE
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(children: [
                      Image.asset('assets/images/grooming_scene.png', width: double.infinity, height: 140, fit: BoxFit.cover),
                      Positioned.fill(child: Container(decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [PetSpaTheme.bgDark.withOpacity(0.6), Colors.transparent]),
                      ))),
                      const Positioned(left: 20, bottom: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('✂️ Nuestros Servicios', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('Servicios premium para tu mascota', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  if (_servicios.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: Column(children: [
                      Text('✂️', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Sin servicios', style: TextStyle(color: PetSpaTheme.textSecondary, fontSize: 16)),
                    ])))
                  else
                    ..._servicios.map((s) => _buildServiceCard(s, isAdmin)),
                ],
              ),
            ),
    );
  }

  Widget _buildServiceCard(Map s, bool isAdmin) {
    final active = s['estado_servicio'] == 'activo';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: PetSpaTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? PetSpaTheme.purple.withOpacity(0.25) : Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: active ? [PetSpaTheme.purple.withOpacity(0.3), PetSpaTheme.teal.withOpacity(0.2)] : [Colors.white12, Colors.white10]),
              ),
              child: Center(child: Text(_serviceEmoji(s['nombre_del_servicio']), style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['nombre_del_servicio'] ?? '—', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
              if (s['descripcion'] != null) Text(s['descripcion'], style: const TextStyle(fontSize: 12, color: PetSpaTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Bs. ${s['precio'] ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PetSpaTheme.tealLight)),
              const SizedBox(height: 4),
              BadgeChip(label: active ? 'Activo' : 'Inactivo', color: active ? PetSpaTheme.success : PetSpaTheme.danger),
            ]),
          ]),
          if (s['duracion_estimada_minutos'] != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.timer_outlined, size: 14, color: PetSpaTheme.textSecondary),
              const SizedBox(width: 6),
              Text('Duración: ${s['duracion_estimada_minutos']} minutos', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12)),
            ]),
          ],
          if (isAdmin) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _ActionBtn2('✏️ Editar', PetSpaTheme.purple, () => _showForm(srv: s))),
              const SizedBox(width: 8),
              Expanded(child: _ActionBtn2(active ? '🔴 Desactivar' : '🟢 Activar', active ? PetSpaTheme.danger : PetSpaTheme.success, () => _toggle(s, active ? 'inactivo' : 'activo'))),
            ]),
          ],
        ]),
      ),
    );
  }

  String _serviceEmoji(String? nombre) {
    final n = (nombre ?? '').toLowerCase();
    if (n.contains('baño') || n.contains('bath')) return '🛁';
    if (n.contains('corte') || n.contains('cort') || n.contains('grooming')) return '✂️';
    if (n.contains('vacuna') || n.contains('vet')) return '💉';
    if (n.contains('masaje')) return '💆';
    if (n.contains('dental') || n.contains('diente')) return '🦷';
    return '⭐';
  }

  void _showForm({Map? srv}) {
    final nameCtrl = TextEditingController(text: srv?['nombre_del_servicio'] ?? '');
    final descCtrl = TextEditingController(text: srv?['descripcion'] ?? '');
    final precioCtrl = TextEditingController(text: srv?['precio']?.toString() ?? '');
    final durCtrl = TextEditingController(text: srv?['duracion_estimada_minutos']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(srv == null ? '✂️ Nuevo Servicio' : '✏️ Editar Servicio', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          PetSpaTextField(controller: nameCtrl, label: 'Nombre del servicio *', icon: Icons.spa_outlined),
          const SizedBox(height: 12),
          PetSpaTextField(controller: descCtrl, label: 'Descripción', icon: Icons.description_outlined),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PetSpaTextField(controller: precioCtrl, label: 'Precio (Bs.)', icon: Icons.attach_money, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: PetSpaTextField(controller: durCtrl, label: 'Duración (min)', keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 20),
          GradientButton(
            text: srv == null ? 'Crear Servicio' : 'Guardar Cambios',
            onPressed: () async {
              final data = {'nombre_del_servicio': nameCtrl.text.trim(), 'descripcion': descCtrl.text.trim(), 'precio': double.tryParse(precioCtrl.text), 'duracion_estimada_minutos': int.tryParse(durCtrl.text), if (srv != null) 'estado_servicio': srv['estado_servicio']};
              final res = srv == null ? await ApiService.crearServicio(data) : await ApiService.actualizarServicio(srv['id_servicio'], data);
              if (!mounted) return;
              Navigator.pop(ctx);
              if (res['success'] == true) { PetSpaSnack.show(context, res['message'] ?? 'Guardado'); _load(); }
              else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _toggle(Map srv, String estado) async {
    final res = await ApiService.actualizarServicio(srv['id_servicio'], {...Map<String, dynamic>.from(srv), 'estado_servicio': estado});
    if (res['success'] == true) { PetSpaSnack.show(context, 'Estado actualizado'); _load(); }
    else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
  }
}

class _ActionBtn2 extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;
  const _ActionBtn2(this.text, this.color, this.onPressed);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.35))),
      child: Center(child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600))),
    ),
  );
}
