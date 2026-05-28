import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
class CitasPage extends StatefulWidget {
  final bool soloMias;
  final bool isGroomer;
  const CitasPage({super.key, this.soloMias = false, this.isGroomer = false});
  @override
  State<CitasPage> createState() => _CitasPageState();
}

class _CitasPageState extends State<CitasPage> with SingleTickerProviderStateMixin {
  List _citas = [];
  bool _loading = true;
  late TabController _tabs;
  DateTime _fecha = DateTime.now();

  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = widget.isGroomer
        ? await ApiService.getMisServicios()
        : widget.soloMias
            ? await ApiService.getMisCitas()
            : await ApiService.getAllCitas();
    if (mounted) setState(() { _citas = res['data'] as List? ?? []; _loading = false; });
  }

  Color _estadoColor(String? e) {
    switch (e) {
      case 'activo': return PetSpaTheme.success;
      case 'terminado': return PetSpaTheme.teal;
      case 'cancelado': return PetSpaTheme.danger;
      default: return PetSpaTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activas = _citas.where((c) => c['estado_de_cita'] == 'activo' && (c['motivo_cancelacion'] == null || c['motivo_cancelacion'] == 'No cancelado')).toList();
    final terminadas = _citas.where((c) => c['estado_de_cita'] == 'terminado').toList();
    final canceladas = _citas.where((c) => c['estado_de_cita'] == 'activo' && c['motivo_cancelacion'] != null && c['motivo_cancelacion'] != 'No cancelado').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNuevaCitaSheet,
        backgroundColor: PetSpaTheme.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Cita', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        // HEADER STATS
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [PetSpaTheme.teal.withOpacity(0.2), PetSpaTheme.purple.withOpacity(0.15)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PetSpaTheme.teal.withOpacity(0.2)),
          ),
          child: Row(children: [
            _MiniStat('${activas.length}', 'Activas', PetSpaTheme.success),
            _MiniStat('${terminadas.length}', 'Terminadas', PetSpaTheme.teal),
            _MiniStat('${canceladas.length}', 'Canceladas', PetSpaTheme.danger),
            _MiniStat('${_citas.length}', 'Total', PetSpaTheme.purple),
          ]),
        ),
        // TABS
        Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          decoration: BoxDecoration(color: PetSpaTheme.bgCard, borderRadius: BorderRadius.circular(14)),
          child: TabBar(
            controller: _tabs,
            indicator: BoxDecoration(gradient: PetSpaTheme.gradientPurpleTeal, borderRadius: BorderRadius.circular(12)),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: PetSpaTheme.textSecondary,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Activas (${activas.length})'),
              Tab(text: 'Terminadas'),
              Tab(text: 'Canceladas'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: PetSpaTheme.teal))
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _buildList(activas),
                    _buildList(terminadas),
                    _buildList(canceladas),
                  ],
                ),
        ),
      ]),
    );
  }

  Widget _buildList(List citas) {
    if (citas.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
      Text('📅', style: TextStyle(fontSize: 48)), SizedBox(height: 12),
      Text('Sin citas aquí', style: TextStyle(color: PetSpaTheme.textSecondary, fontSize: 15)),
    ]));

    return RefreshIndicator(
      onRefresh: _load,
      color: PetSpaTheme.teal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: citas.length,
        itemBuilder: (_, i) => _buildCitaCard(citas[i]),
      ),
    );
  }

  Widget _buildCitaCard(Map c) {
    final estado = c['estado_de_cita'] ?? 'activo';
    final color = _estadoColor(estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PetSpaTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12), border: Border.all(color: color.withOpacity(0.3))),
              child: Center(child: Text(_petEmoji(c['raza']), style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c['nombre_mascota'] ?? '—', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
              Text(c['nombre_del_servicio'] ?? '—', style: TextStyle(fontSize: 12, color: color)),
            ])),
            BadgeChip(label: estado, color: color),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _InfoPill(Icons.calendar_today, _fmtDate(c['fecha_cita']))),
            const SizedBox(width: 8),
            Expanded(child: _InfoPill(Icons.person_outline, c['nombre_groomer'] ?? 'Sin asignar')),
            const SizedBox(width: 8),
            Expanded(child: _InfoPill(Icons.attach_money, 'Bs. ${c['monto_pagado'] ?? 0} (${c['metodo_pago'] ?? 'efectivo'})')),
          ]),
          if (estado == 'activo') ...[
            const SizedBox(height: 12),
            if (ApiService.role != 'Clientes') ...[
              Row(children: [
                Expanded(child: _ActionBtn('✅ Terminar', PetSpaTheme.success, () => _terminar(c['id_cita']))),
              ]),
              const SizedBox(height: 8),
            ],
            Row(children: [
              Expanded(child: _ActionBtn('✏️ Editar', PetSpaTheme.purple, () => _showEditarSheet(c))),
              const SizedBox(width: 8),
              Expanded(child: _ActionBtn('✕ Cancelar', PetSpaTheme.danger, () => _cancelar(c['id_cita']))),
            ]),
          ],
          if (estado == 'listo_para_recoger' && !widget.soloMias) ...[
            const SizedBox(height: 12),
            _ActionBtn('✅ Entregar y Terminar', PetSpaTheme.success, () => _terminar(c['id_cita'])),
          ],
          if (estado == 'terminado' && (widget.soloMias || ApiService.role == 'Clientes') && c['calificacion'] == null) ...[
            const SizedBox(height: 10),
            _ActionBtn('⭐ Dejar opinión', PetSpaTheme.gold, () => _showOpinionSheet(c['id_cita'])),
          ],
        ]),
      ),
    );
  }

  void _showNuevaCitaSheet() async {
    final futures = await Future.wait(<Future<Map<String,dynamic>>>[
      widget.soloMias ? ApiService.getMisMascotas() : ApiService.getAllMascotas(),
      ApiService.getServicios(),
      ApiService.getGroomers(),
    ]);
    if (!mounted) return;
    final masRes = futures[0];
    final srvRes = futures[1];
    final grRes = futures[2];

    final mascotas = masRes['data'] as List? ?? [];
    final servicios = srvRes['data'] as List? ?? [];
    final groomers = grRes['data'] as List? ?? [];

    int? mascotaId = mascotas.isNotEmpty ? mascotas[0]['id_mascota'] : null;
    int? servicioId = servicios.isNotEmpty ? servicios[0]['id_servicio'] : null;
    int duracion = servicios.isNotEmpty ? (servicios[0]['duracion_estimada_minutos'] ?? 30) : 30;
    int? groomerId;
    final fechaCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final now = DateTime.now();
    final hourStr = now.hour.toString().padLeft(2, '0');
    final minStr = now.minute.toString().padLeft(2, '0');
    final horaCtrl = TextEditingController(text: '$hourStr:$minStr');
    final montoCtrl = TextEditingController(text: servicios.isNotEmpty ? '${servicios[0]['precio'] ?? 0}' : '0');
    String metodoPago = 'efectivo';

    List<String> horasOcupadas = [];
    
    void fetchHorarios(StateSetter st) async {
      if (groomerId != null && groomerId != 0) {
         final res = await ApiService.getHorariosOcupados(groomerId!, fechaCtrl.text);
         if (res['success'] == true) {
            st(() {
               horasOcupadas = (res['data'] as List).map((e) => '${e['hora_cita'].toString().substring(0, 5)} a ${e['hora_fin'].toString().substring(0, 5)}').toList();
            });
         }
      } else {
         st(() => horasOcupadas = []);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('📅 Nueva Cita', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          _buildDropdown('🐾 Mascota', mascotas, (v) { setS(() { mascotaId = v; }); }, mascotaId, 'id_mascota', 'nombre_mascota'),
          const SizedBox(height: 12),
          _buildDropdown('✂️ Servicio', servicios, (v) { setS(() { servicioId = v; final srv = servicios.firstWhere((s) => s['id_servicio'] == v, orElse: () => {}); montoCtrl.text = '${srv['precio'] ?? 0}'; duracion = srv['duracion_estimada_minutos'] ?? 30; }); }, servicioId, 'id_servicio', 'nombre_del_servicio'),
          Padding(padding: const EdgeInsets.only(top: 4, left: 14), child: Text('⏱️ Duración aprox: $duracion min + 15m (limpieza)', style: const TextStyle(color: PetSpaTheme.gold, fontSize: 11, fontWeight: FontWeight.w600))),
          const SizedBox(height: 12),
          _buildDropdown('👷 Groomer', [{'id_trabajadores': null, 'nombre': 'Sin asignar'}, ...groomers], (v) { setS(() => groomerId = v); fetchHorarios(setS); }, groomerId, 'id_trabajadores', 'nombre'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Focus(onFocusChange: (f) { if(!f) fetchHorarios(setS); }, child: PetSpaTextField(controller: fechaCtrl, label: 'Fecha', icon: Icons.calendar_today, keyboardType: TextInputType.datetime))),
            const SizedBox(width: 12),
            Expanded(child: PetSpaTextField(controller: horaCtrl, label: 'Hora (HH:MM)', icon: Icons.access_time)),
          ]),
          if (groomerId != null && horasOcupadas.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: PetSpaTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: PetSpaTheme.danger.withOpacity(0.3))),
              child: Text('Horarios ocupados este día:\n${horasOcupadas.join(', ')}', style: const TextStyle(color: PetSpaTheme.danger, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ] else if (groomerId != null) ...[
            const SizedBox(height: 8),
            const Padding(padding: EdgeInsets.only(left: 10), child: Text('✅ Groomer disponible todo el día', style: TextStyle(color: PetSpaTheme.success, fontSize: 11, fontWeight: FontWeight.w600))),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PetSpaTextField(controller: montoCtrl, label: 'Monto (Bs.)', icon: Icons.attach_money, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: metodoPago,
                  dropdownColor: PetSpaTheme.bgCard2,
                  style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
                  items: ['efectivo', 'qr', 'transferencia', 'tarjeta'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                  onChanged: (v) => setS(() => metodoPago = v ?? 'efectivo'),
                ),
              ),
            )),
          ]),
          const SizedBox(height: 20),
          GradientButton(
            text: 'Confirmar Cita',
            colors: const [PetSpaTheme.teal, PetSpaTheme.tealLight],
            onPressed: () async {
              final res = await ApiService.crearCita({'id_mascota': mascotaId, 'id_servicio': servicioId, 'empleado_acargo': groomerId, 'fecha_cita': fechaCtrl.text, 'hora_cita': horaCtrl.text, 'metodo_pago': metodoPago, 'monto_pagado': double.tryParse(montoCtrl.text) ?? 0});
              if (!mounted) return;
              Navigator.pop(ctx);
              if (res['success'] == true) { PetSpaSnack.show(context, res['message'] ?? 'Cita creada ✅'); _load(); }
              else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
            },
          ),
        ]),
      )),
    );
  }

  Widget _buildDropdown(String label, List items, Function(int?) onChanged, int? value, String keyField, String labelField) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: value,
          dropdownColor: PetSpaTheme.bgCard2,
          style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
          hint: Text(label, style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 14)),
          items: items.map((it) => DropdownMenuItem<int?>(
            value: it[keyField] as int?,
            child: Text(it[labelField]?.toString() ?? '—', overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (v) => onChanged(v),
        ),
      ),
    );
  }

  void _showEditarSheet(Map c) async {
    // Cargamos groomers para el dropdown
    final grRes = await ApiService.getGroomers();
    if (!mounted) return;
    final groomers = grRes['data'] as List? ?? [];

    final fechaCtrl  = TextEditingController(text: c['fecha_cita']?.toString().split('T')[0] ?? '');
    final montoCtrl  = TextEditingController(text: '${c['monto_pagado'] ?? 0}');
    final motivoCtrl = TextEditingController(text: c['motivo_cancelacion'] == 'No cancelado' ? '' : (c['motivo_cancelacion'] ?? ''));
    int? groomerId   = c['empleado_acargo'] as int?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('✏️ Editar Cita', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          // Fecha
          PetSpaTextField(controller: fechaCtrl, label: 'Nueva fecha (YYYY-MM-DD)', icon: Icons.calendar_today),
          const SizedBox(height: 12),
          // Monto
          PetSpaTextField(controller: montoCtrl, label: 'Monto (Bs.)', icon: Icons.attach_money, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          // Empleado a cargo (empleado_acargo → FK a TRABAJADORES)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                isExpanded: true,
                value: groomerId,
                dropdownColor: PetSpaTheme.bgCard2,
                style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
                hint: const Text('👷 Empleado a cargo', style: TextStyle(color: PetSpaTheme.textSecondary)),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Sin asignar')),
                  ...groomers.map((g) => DropdownMenuItem<int?>(value: g['id_trabajadores'] as int?, child: Text(g['nombre'] ?? '—'))),
                ],
                onChanged: (v) => setS(() => groomerId = v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Motivo de cancelación (opcional, pero existe en la BD)
          PetSpaTextField(controller: motivoCtrl, label: 'Motivo de reprogramación (opcional)', icon: Icons.notes),
          const SizedBox(height: 20),
          GradientButton(text: 'Guardar cambios', onPressed: () async {
            final res = await ApiService.actualizarCita(c['id_cita'], {
              'fecha_cita':      fechaCtrl.text,
              'monto_pagado':    double.tryParse(montoCtrl.text),
              'empleado_acargo': groomerId,
              if (motivoCtrl.text.isNotEmpty) 'motivo_reprogramacion': motivoCtrl.text,
            });
            if (!mounted) return;
            Navigator.pop(ctx);
            if (res['success'] == true) { PetSpaSnack.show(context, 'Cita actualizada'); _load(); }
            else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
          }),
        ]),
      )),
    );
  }


  void _terminar(int idCita) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple)));
    
    final cajasRes = await ApiService.getCajas();
    final fichaRes = await ApiService.getFichaByCita(idCita);
    
    if (!mounted) return;
    Navigator.pop(context); // Close loading spinner

    final cajas = cajasRes['data'] as List? ?? [];
    final ficha = fichaRes['data'];

    double totalServicio = 0.0;
    double totalInsumos = 0.0;
    
    // Find the appointment in _citas to get the service base price
    final c = _citas.firstWhere((element) => element['id_cita'] == idCita, orElse: () => null);
    if (c != null) {
      totalServicio = double.tryParse(c['precio']?.toString() ?? '0.0') ?? 0.0;
    }

    if (ficha != null) {
      final insumos = ficha['insumos'] as List? ?? [];
      for (var ins in insumos) {
        final double price = double.tryParse(ins['precio_insumo']?.toString() ?? '0.0') ?? 0.0;
        final int qty = int.tryParse(ins['unidades_usadas']?.toString() ?? '0') ?? 0;
        totalInsumos += price * qty;
      }
    }

    final totalAcumulado = totalServicio + totalInsumos;

    final estadoMascCtrl  = TextEditingController(text: 'Bien');
    final fotoEstCtrl     = TextEditingController();
    final montoCtrl       = TextEditingController(text: totalAcumulado.toStringAsFixed(2));
    int? cajaId           = cajas.isNotEmpty ? cajas[0]['id_cajas'] as int? : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('✅ Terminar Cita', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 6),
          const Text('Completa el informe del servicio realizado', style: TextStyle(fontSize: 12, color: PetSpaTheme.textSecondary)),
          const SizedBox(height: 20),
          // estado_de_mascota (TEXT) — cómo quedó la mascota
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: estadoMascCtrl.text.isEmpty ? 'Bien' : estadoMascCtrl.text,
                dropdownColor: PetSpaTheme.bgCard2,
                style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
                items: ['Excelente', 'Bien', 'Regular', 'Con observaciones'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setS(() => estadoMascCtrl.text = v ?? 'Bien'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // foto_estado_mascota (TEXT — URL de foto)
          PetSpaTextField(
            controller: fotoEstCtrl,
            label: 'Foto estado mascota (URL, opcional)',
            icon: Icons.photo_camera_outlined,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          // caja a depositar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                isExpanded: true,
                value: cajaId,
                dropdownColor: PetSpaTheme.bgCard2,
                style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
                hint: const Text('🏦 Seleccione caja', style: TextStyle(color: PetSpaTheme.textSecondary)),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('No registrar en caja')),
                  ...cajas.map((c) => DropdownMenuItem<int?>(value: c['id_cajas'] as int?, child: Text(c['nombre_caja'] ?? '—'))),
                ],
                onChanged: (v) => setS(() => cajaId = v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // monto_pagado final
          PetSpaTextField(
            controller: montoCtrl,
            label: 'Monto final cobrado (Bs.)',
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          GradientButton(
            text: '✅ Confirmar Término',
            colors: const [PetSpaTheme.success, PetSpaTheme.teal],
            onPressed: () async {
              final res = await ApiService.terminarCita(idCita, {
                'estado_de_mascota':    estadoMascCtrl.text,
                'foto_estado_mascota':  fotoEstCtrl.text.trim().isEmpty ? null : fotoEstCtrl.text.trim(),
                if (montoCtrl.text.isNotEmpty) 'monto_pagado': double.tryParse(montoCtrl.text),
                if (cajaId != null) 'monto_llevado_a_caja': cajaId,
              });
              if (!mounted) return;
              Navigator.pop(ctx);
              if (res['success'] == true) { 
                PetSpaSnack.show(context, 'Cita terminada ✅'); 
                _load(); 
              }
              else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
            },
          ),
        ]),
      )),
    );
  }

  Future<void> _cancelar(int id) async {
    final res = await ApiService.cancelarCita(id);
    if (!mounted) return;
    if (res['success'] == true) { PetSpaSnack.show(context, 'Cita cancelada'); _load(); }
    else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
  }

  void _showOpinionSheet(int idCita) {
    int calificacion = 0;
    final commentCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('⭐ Dejar Opinión', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(
            onTap: () => setS(() => calificacion = i + 1),
            child: Icon(Icons.star, size: 44, color: i < calificacion ? PetSpaTheme.gold : Colors.white12),
          ))),
          const SizedBox(height: 16),
          PetSpaTextField(controller: commentCtrl, label: 'Comentario (opcional)', icon: Icons.comment_outlined),
          const SizedBox(height: 20),
          GradientButton(
            text: 'Enviar Opinión',
            colors: const [PetSpaTheme.gold, Color(0xFFf97316)],
            onPressed: () async {
              if (calificacion == 0) { PetSpaSnack.show(ctx, 'Selecciona una calificación', error: true); return; }
              final res = await ApiService.registrarOpinion({'id_cita': idCita, 'calificacion': calificacion, 'comentario': commentCtrl.text});
              if (!mounted) return;
              Navigator.pop(ctx);
              if (res['success'] == true) { PetSpaSnack.show(context, '¡Gracias por tu opinión! ⭐'); _load(); }
              else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
            },
          ),
        ]),
      )),
    );
  }

  String _petEmoji(String? raza) {
    final r = (raza ?? '').toLowerCase();
    if (r.contains('gato') || r.contains('cat')) return '🐱';
    if (r.contains('conejo')) return '🐰';
    return '🐶';
  }

  String _fmtDate(dynamic d) {
    if (d == null) return '—';
    try { final dt = DateTime.parse(d.toString()); return '${dt.day}/${dt.month}/${dt.year}'; } catch (_) { return d.toString(); }
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MiniStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
    Text(label, style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 10)),
  ]));
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(icon, size: 11, color: PetSpaTheme.textSecondary),
      const SizedBox(width: 4),
      Expanded(child: Text(text, style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
  );
}

class _ActionBtn extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;
  const _ActionBtn(this.text, this.color, this.onPressed);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))),
      child: Center(child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600))),
    ),
  );
}
