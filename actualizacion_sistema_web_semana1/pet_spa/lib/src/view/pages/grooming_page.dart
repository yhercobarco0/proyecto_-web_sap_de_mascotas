import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class GroomingPage extends StatefulWidget {
  const GroomingPage({super.key});
  @override State<GroomingPage> createState() => _GroomingPageState();
}

class _GroomingPageState extends State<GroomingPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List _citas = [];
  List _cajas = [];
  List _transacciones = [];
  List _pagos = [];
  List _logInsumos = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 5, vsync: this); _load(); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final isGroomer = ApiService.role == 'Groomers';
    final results = await Future.wait(<Future<Map<String,dynamic>>>[
      isGroomer ? ApiService.getMisFichas() : ApiService.getAllCitas(),
      ApiService.getCajas(),
      ApiService.getAllTransacciones(),
      ApiService.getAllPagos(),
      ApiService.getLogInsumos(),
    ]);
    if (mounted) setState(() {
      _citas = results[0]['data'] as List? ?? [];
      _cajas = results[1]['data'] as List? ?? [];
      _transacciones = results[2]['data'] as List? ?? [];
      _pagos = results[3]['data'] as List? ?? [];
      _logInsumos = results[4]['data'] as List? ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: BoxDecoration(color: PetSpaTheme.bgCard, borderRadius: BorderRadius.circular(14)),
          child: TabBar(
            controller: _tabs,
            indicator: BoxDecoration(gradient: PetSpaTheme.gradientPurpleTeal, borderRadius: BorderRadius.circular(12)),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: PetSpaTheme.textSecondary,
            labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: '📋 Fichas'), Tab(text: '💰 Cajas'), Tab(text: '🔄 Transacc.'), Tab(text: '💸 Pagos'), Tab(text: '📦 Log Insumos')],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple))
              : TabBarView(controller: _tabs, children: [
                  _buildFichas(),
                  _buildCajas(),
                  _buildTransacciones(),
                  _buildPagos(),
                  _buildLogInsumos(),
                ]),
        ),
      ]),
    );
  }

  Widget _buildFichas() {
    return RefreshIndicator(onRefresh: _load, color: PetSpaTheme.purple, child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        GradientButton(text: '+ Nueva Ficha', onPressed: _showNuevaFichaSheet, colors: const [PetSpaTheme.purple, PetSpaTheme.teal]),
        const SizedBox(height: 16),
        if (_citas.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Column(children: [Text('📋', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('Sin fichas', style: TextStyle(color: PetSpaTheme.textSecondary))])))
        else
          ..._citas.map((c) => _buildFichaCard(c)),
      ],
    ));
  }

  Widget _buildFichaCard(Map c) {
    final tieneFicha = c['fecha_cierre'] != null || c['id_fichas_grooming'] != null;
    final dateInfo = c['fecha_cita'] != null 
        ? c['fecha_cita'].toString().split('T')[0] 
        : (c['fecha_creacion'] != null 
            ? c['fecha_creacion'].toString().split('T')[0] 
            : '—');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PetSpaTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tieneFicha ? PetSpaTheme.teal.withOpacity(0.3) : PetSpaTheme.purple.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (tieneFicha ? PetSpaTheme.teal : PetSpaTheme.purple).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Text(tieneFicha ? '✅' : '💈', style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${c['nombre_mascota'] ?? 'Mascota'} (${c['raza'] ?? '—'})', 
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
            Text(c['nombre_del_servicio'] ?? '—', 
              style: const TextStyle(fontSize: 12, color: PetSpaTheme.tealLight, fontWeight: FontWeight.w500)),
          ])),
          BadgeChip(
            label: tieneFicha ? 'Ficha OK' : 'Sin ficha', 
            color: tieneFicha ? PetSpaTheme.success : PetSpaTheme.gold,
          ),
        ]),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: Colors.white10, height: 1),
        ),
        Row(children: [
          const Icon(Icons.person, color: PetSpaTheme.textSecondary, size: 14),
          const SizedBox(width: 6),
          const Text('Cliente: ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(c['nombre_cliente'] ?? '—', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.email, color: PetSpaTheme.textSecondary, size: 14),
          const SizedBox(width: 6),
          Text(c['email_cliente'] ?? '—', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
          if (c['telefono_cliente'] != null) ...[
            const SizedBox(width: 8),
            const Text('|', style: TextStyle(color: Colors.white12, fontSize: 11)),
            const SizedBox(width: 8),
            const Icon(Icons.phone, color: PetSpaTheme.textSecondary, size: 14),
            const SizedBox(width: 6),
            Text('${c['telefono_cliente']}', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
          ]
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.straighten, color: PetSpaTheme.textSecondary, size: 14),
          const SizedBox(width: 6),
          Text(
            'Medidas: ${c['tamano'] ?? '—'} cm  |  Peso: ${c['peso'] ?? '—'} kg', 
            style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11),
          ),
          const Spacer(),
          const Icon(Icons.calendar_today, color: PetSpaTheme.textSecondary, size: 12),
          const SizedBox(width: 4),
          Text(dateInfo, style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: () => _abrirFicha(c['id_cita'] ?? c['id_fichas_grooming']),
            icon: const Icon(Icons.assignment, size: 16),
            label: Text(tieneFicha ? 'Ver Ficha Completa' : 'Abrir & Llenar Ficha', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: tieneFicha ? PetSpaTheme.teal.withOpacity(0.2) : PetSpaTheme.purple,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )),
        ]),
      ]),
    );
  }

  void _showNuevaFichaSheet() async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple)));
    final citasRes = await ApiService.getAllCitas();
    if (!mounted) return;
    Navigator.pop(context);

    final allCitas = citasRes['data'] as List? ?? [];
    final pendingCitas = allCitas.where((c) {
      final isCanceled = c['estado_de_cita'] == 'cancelado';
      final hasFicha = c['id_fichas_grooming'] != null;
      return !isCanceled && !hasFicha;
    }).toList();

    if (pendingCitas.isEmpty) {
      PetSpaSnack.show(context, 'No hay citas activas sin ficha de grooming en este momento.', error: true);
      return;
    }

    int? selectedCitaId = pendingCitas.first['id_cita'] as int?;
    final espCtrl = TextEditingController(text: '15');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('📋 Nueva Ficha Grooming', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          const Text('Seleccionar Cita Activa *', style: TextStyle(color: PetSpaTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<int>(
              isExpanded: true, 
              value: selectedCitaId, 
              dropdownColor: PetSpaTheme.bgCard2, 
              style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13),
              items: pendingCitas.map((c) {
                final dateStr = c['fecha_cita'] != null ? c['fecha_cita'].toString().split('T')[0] : '';
                final label = '${c['nombre_mascota'] ?? 'Mascota'} - ${c['nombre_cliente'] ?? 'Cliente'} ($dateStr - ${c['nombre_del_servicio'] ?? ''})';
                return DropdownMenuItem<int>(value: c['id_cita'] as int?, child: Text(label, overflow: TextOverflow.ellipsis));
              }).toList(),
              onChanged: (v) => setS(() => selectedCitaId = v),
            )),
          ),
          const SizedBox(height: 16),
          PetSpaTextField(controller: espCtrl, label: 'Tiempo espera (min)', icon: Icons.timer, keyboardType: TextInputType.number),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Crear Ficha', 
            colors: const [PetSpaTheme.purple, PetSpaTheme.teal],
            onPressed: () async {
              if (selectedCitaId == null) {
                PetSpaSnack.show(context, 'Debe seleccionar una cita válida', error: true);
                return;
              }
              final res = await ApiService.crearFicha({
                'id_cita': selectedCitaId, 
                'tiempo_espera': int.tryParse(espCtrl.text) ?? 15
              });
              if (!mounted) return;
              Navigator.pop(ctx);
              if (res['success'] == true) { 
                PetSpaSnack.show(context, 'Ficha creada exitosamente'); 
                _load(); 
              } else {
                PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
              }
            },
          ),
        ]),
      )),
    );
  }

  Future<void> _abrirFicha(int idCita) async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple)));
    final res = await ApiService.getFichaByCita(idCita);
    if (!mounted) return;
    Navigator.pop(context);
    final ficha = res['data'];
    if (ficha == null) {
      PetSpaSnack.show(context, 'Sin ficha para esta cita. Crea una nueva.');
      return;
    }
    final insumos = ficha['insumos'] as List? ?? [];
    
    // Variables de estado para el checklist
    bool checkPiel = false;
    bool checkNudos = false;
    bool checkParasitos = false;
    bool checkAgresividad = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => DraggableScrollableSheet(expand: false, initialChildSize: 0.8, builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📋 Ficha #${ficha['id_fichas_grooming']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(ficha['fecha_cierre'] != null ? '✅ Ficha cerrada' : '🟡 Ficha abierta', style: TextStyle(color: ficha['fecha_cierre'] != null ? PetSpaTheme.success : PetSpaTheme.gold, fontSize: 13)),
          const SizedBox(height: 16),
          // Detalles de Cliente y Mascota
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.person, color: PetSpaTheme.tealLight, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Cliente: ${ficha['nombre_cliente'] ?? '—'}', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.email, color: PetSpaTheme.tealLight, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Email: ${ficha['email_cliente'] ?? '—'}', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12))),
              ]),
              if (ficha['telefono_cliente'] != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.phone, color: PetSpaTheme.tealLight, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Teléfono: ${ficha['telefono_cliente']}', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12))),
                ]),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.white12, height: 1),
              ),
              Row(children: [
                const Icon(Icons.pets, color: PetSpaTheme.purpleLight, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Mascota: ${ficha['nombre_mascota'] ?? '—'}', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.category, color: PetSpaTheme.purpleLight, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Raza: ${ficha['raza'] ?? '—'}', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.straighten, color: PetSpaTheme.purpleLight, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Tamaño: ${ficha['tamano'] ?? '—'} cm  |  Peso: ${ficha['peso'] ?? '—'} kg', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.cut, color: PetSpaTheme.purpleLight, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Servicio: ${ficha['nombre_del_servicio'] ?? '—'}', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12))),
              ]),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Insumos usados', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 8),
          if (insumos.isEmpty)
            const Text('Sin insumos registrados', style: TextStyle(color: PetSpaTheme.textSecondary))
          else
            ...insumos.map((i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: PetSpaTheme.teal.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.inventory, size: 16, color: PetSpaTheme.teal),
                const SizedBox(width: 8),
                Expanded(child: Text(i['nombre_producto'] ?? '—', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13))),
                Text('${i['unidades_usadas']} und.', style: const TextStyle(color: PetSpaTheme.tealLight, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            )),
          if (ficha['fecha_cierre'] == null) ...[
            const SizedBox(height: 16),
            const Text('Checklist Pre-Cierre (Obligatorio)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: Column(children: [
                CheckboxListTile(
                  title: const Text('Revisión de Estado de Piel', style: TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13)),
                  value: checkPiel,
                  activeColor: PetSpaTheme.teal,
                  onChanged: (v) => setS(() => checkPiel = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Desenredado / Nudos', style: TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13)),
                  value: checkNudos,
                  activeColor: PetSpaTheme.teal,
                  onChanged: (v) => setS(() => checkNudos = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Revisión de Parásitos', style: TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13)),
                  value: checkParasitos,
                  activeColor: PetSpaTheme.teal,
                  onChanged: (v) => setS(() => checkParasitos = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Control de Agresividad / Temperamento', style: TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13)),
                  value: checkAgresividad,
                  activeColor: PetSpaTheme.teal,
                  onChanged: (v) => setS(() => checkAgresividad = v ?? false),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            GradientButton(text: '➕ Agregar Insumo', colors: const [PetSpaTheme.teal, PetSpaTheme.tealLight], onPressed: () {
              Navigator.pop(context);
              _showAddInsumoSheet(ficha['id_fichas_grooming'], idCita);
            }),
            const SizedBox(height: 12),
            GradientButton(
              text: '🔒 Cerrar Ficha', 
              colors: const [PetSpaTheme.danger, Color(0xFFf97316)], 
              onPressed: (checkPiel && checkNudos && checkParasitos && checkAgresividad)
                  ? () async {
                      final payloadChecklist = [
                        {'key': 'estado_piel', 'value': checkPiel},
                        {'key': 'nudos', 'value': checkNudos},
                        {'key': 'parasitos', 'value': checkParasitos},
                        {'key': 'agresividad', 'value': checkAgresividad},
                      ];

                      final r = await ApiService.cerrarFicha(ficha['id_fichas_grooming'], payloadChecklist);
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (r['success'] == true) { PetSpaSnack.show(context, 'Ficha cerrada'); _load(); }
                      else PetSpaSnack.show(context, r['message'] ?? 'Error', error: true);
                    }
                  : null,
            ),
          ],
        ]),
      ))),
    );
  }

  void _showAddInsumoSheet(int idFicha, int idCitaOriginal) async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple)));
    final prodsRes = await ApiService.getProductos();
    if (!mounted) return;
    Navigator.pop(context);
    
    final productos = (prodsRes['data'] as List? ?? []).where((p) => (p['stok_unidad'] as int? ?? 0) > 0).toList();
    if (productos.isEmpty) {
      PetSpaSnack.show(context, 'No hay productos con stock disponible.');
      return;
    }

    int? selectedProd = productos.first['id_producto'];
    final cantCtrl = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('➕ Agregar Insumo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<int>(
              isExpanded: true, value: selectedProd, dropdownColor: PetSpaTheme.bgCard2, style: const TextStyle(color: PetSpaTheme.textPrimary),
              items: productos.map((p) => DropdownMenuItem<int>(value: p['id_producto'], child: Text('${p['nombre_producto']} (Stock: ${p['stok_unidad']})'))).toList(),
              onChanged: (v) => setS(() => selectedProd = v),
            )),
          ),
          const SizedBox(height: 12),
          PetSpaTextField(controller: cantCtrl, label: 'Unidades usadas', keyboardType: TextInputType.number, icon: Icons.numbers),
          const SizedBox(height: 20),
          GradientButton(text: 'Guardar Insumo', onPressed: () async {
            final cant = int.tryParse(cantCtrl.text) ?? 1;
            if (cant <= 0) { PetSpaSnack.show(context, 'Cantidad inválida', error: true); return; }
            final res = await ApiService.registrarInsumo({'id_fichas_grooming': idFicha, 'id_producto': selectedProd, 'unidades_usadas': cant});
            if (!mounted) return;
            Navigator.pop(ctx);
            if (res['success'] == true) { 
              PetSpaSnack.show(context, 'Insumo agregado y stock descontado'); 
              _abrirFicha(idCitaOriginal); 
            } else {
              PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
            }
          }),
        ]),
      )),
    );
  }

  Widget _buildCajas() {
    return RefreshIndicator(onRefresh: _load, color: PetSpaTheme.teal, child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        GradientButton(text: '+ Nueva Caja', colors: const [PetSpaTheme.teal, PetSpaTheme.tealLight], onPressed: _showNuevaCajaSheet),
        const SizedBox(height: 16),
        if (_cajas.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Column(children: [Text('🏦', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('Sin cajas', style: TextStyle(color: PetSpaTheme.textSecondary))])))
        else ..._cajas.map((c) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [PetSpaTheme.teal.withOpacity(0.15), PetSpaTheme.purple.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PetSpaTheme.teal.withOpacity(0.25)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🏦', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(child: Text(c['nombre_caja'] ?? '—', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary))),
              BadgeChip(label: c['estado_caja'] ?? 'activo', color: PetSpaTheme.success),
            ]),
            const SizedBox(height: 8),
            Text('Bs. ${c['saldo_caja'] ?? 0}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: PetSpaTheme.tealLight)),
            if (c['nombre_responsable'] != null) Text('👤 ${c['nombre_responsable']}', style: const TextStyle(fontSize: 11, color: PetSpaTheme.textSecondary)),
            const SizedBox(height: 10),
            GradientButton(text: '💸 Nueva Transacción', colors: const [PetSpaTheme.purple, PetSpaTheme.purpleLight], onPressed: () => _showTransaccionSheet(c['id_cajas'])),
          ]),
        )),
      ],
    ));
  }

  void _showNuevaCajaSheet() async {
    // Cargamos empleados para asignar responsable (id_trabajadores → FK a TRABAJADORES)
    final empsRes = await ApiService.getEmpleados();
    if (!mounted) return;
    final empleados = empsRes['data'] as List? ?? [];

    final nameCtrl  = TextEditingController();
    final descCtrl  = TextEditingController();
    final saldoCtrl = TextEditingController(text: '0');
    int? empId = empleados.isNotEmpty ? empleados[0]['id_trabajadores'] as int? : null;
    String estadoCaja = 'activo';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('🏦 Nueva Caja', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          // nombre_caja
          PetSpaTextField(controller: nameCtrl, label: 'Nombre de caja *', icon: Icons.account_balance),
          const SizedBox(height: 12),
          // descripcion (campo de la BD)
          PetSpaTextField(controller: descCtrl, label: 'Descripción', icon: Icons.notes),
          const SizedBox(height: 12),
          // saldo_caja
          PetSpaTextField(controller: saldoCtrl, label: 'Saldo inicial (Bs.)', icon: Icons.attach_money, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          // id_trabajadores — responsable de la caja
          if (empleados.isNotEmpty) Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<int?>(
              isExpanded: true, value: empId, dropdownColor: PetSpaTheme.bgCard2,
              style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
              hint: const Text('Responsable (opcional)', style: TextStyle(color: PetSpaTheme.textSecondary)),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Sin responsable')),
                ...empleados.map((e) => DropdownMenuItem<int?>(value: e['id_trabajadores'] as int?, child: Text(e['nombre'] ?? '—'))),
              ],
              onChanged: (v) => setS(() => empId = v),
            )),
          ),
          const SizedBox(height: 12),
          // estado_caja
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              isExpanded: true, value: estadoCaja, dropdownColor: PetSpaTheme.bgCard2,
              style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
              items: ['activo', 'inactivo'].map((s) => DropdownMenuItem(value: s, child: Text('Estado: $s'))).toList(),
              onChanged: (v) => setS(() => estadoCaja = v ?? 'activo'),
            )),
          ),
          const SizedBox(height: 20),
          GradientButton(text: 'Crear Caja', onPressed: () async {
            final res = await ApiService.crearCaja({
              'nombre_caja':    nameCtrl.text,
              'descripcion':    descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              'saldo_caja':     double.tryParse(saldoCtrl.text) ?? 0,
              'id_trabajadores': empId,
              'estado_caja':    estadoCaja,
            });
            if (!mounted) return;
            Navigator.pop(ctx);
            if (res['success'] == true) { PetSpaSnack.show(context, 'Caja creada'); _load(); }
            else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
          }),
        ]),
      )),
    );
  }

  void _showTransaccionSheet(int idCaja) {
    final montoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String tipo = 'ingreso';
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('💸 Nueva Transacción', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: GestureDetector(onTap: () => setS(() => tipo = 'ingreso'), child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(gradient: tipo == 'ingreso' ? LinearGradient(colors: [PetSpaTheme.success.withOpacity(0.3), PetSpaTheme.success.withOpacity(0.1)]) : null, color: tipo != 'ingreso' ? Colors.white10 : null, borderRadius: BorderRadius.circular(12), border: Border.all(color: tipo == 'ingreso' ? PetSpaTheme.success : Colors.white12)),
              child: const Center(child: Text('⬆️ Ingreso', style: TextStyle(color: PetSpaTheme.success, fontWeight: FontWeight.w700))),
            ))),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(onTap: () => setS(() => tipo = 'egreso'), child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(gradient: tipo == 'egreso' ? LinearGradient(colors: [PetSpaTheme.danger.withOpacity(0.3), PetSpaTheme.danger.withOpacity(0.1)]) : null, color: tipo != 'egreso' ? Colors.white10 : null, borderRadius: BorderRadius.circular(12), border: Border.all(color: tipo == 'egreso' ? PetSpaTheme.danger : Colors.white12)),
              child: const Center(child: Text('⬇️ Egreso', style: TextStyle(color: PetSpaTheme.danger, fontWeight: FontWeight.w700))),
            ))),
          ]),
          const SizedBox(height: 12),
          PetSpaTextField(controller: montoCtrl, label: 'Monto (Bs.) *', icon: Icons.attach_money, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          PetSpaTextField(controller: descCtrl, label: 'Descripción', icon: Icons.notes),
          const SizedBox(height: 20),
          GradientButton(text: 'Registrar', colors: tipo == 'ingreso' ? [PetSpaTheme.success, PetSpaTheme.teal] : [PetSpaTheme.danger, PetSpaTheme.pink], onPressed: () async {
            final res = await ApiService.crearTransaccion({'id_caja': idCaja, 'tipo': tipo, 'monto': double.tryParse(montoCtrl.text) ?? 0, 'descripcion': descCtrl.text});
            if (!mounted) return;
            Navigator.pop(ctx);
            if (res['success'] == true) { PetSpaSnack.show(context, 'Transacción registrada'); _load(); }
            else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
          }),
        ]),
      )),
    );
  }

  Widget _buildTransacciones() {
    if (_transacciones.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('🔄', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('Sin transacciones', style: TextStyle(color: PetSpaTheme.textSecondary))]));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _transacciones.length,
      itemBuilder: (_, i) {
        final t = _transacciones[i];
        final isIngreso = t['tipo'] == 'ingreso';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: PetSpaTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: (isIngreso ? PetSpaTheme.success : PetSpaTheme.danger).withOpacity(0.2))),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: (isIngreso ? PetSpaTheme.success : PetSpaTheme.danger).withOpacity(0.15)), child: Center(child: Text(isIngreso ? '⬆️' : '⬇️', style: const TextStyle(fontSize: 18)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['descripcion'] ?? t['tipo'] ?? '—', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(t['nombre_caja'] ?? '—', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
            ])),
            Text('${isIngreso ? '+' : '-'} Bs. ${t['monto'] ?? 0}', style: TextStyle(color: isIngreso ? PetSpaTheme.success : PetSpaTheme.danger, fontSize: 14, fontWeight: FontWeight.w800)),
          ]),
        );
      },
    );
  }

  Widget _buildPagos() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        GradientButton(text: '+ Registrar Pago', colors: const [PetSpaTheme.gold, Color(0xFFf97316)], onPressed: _showPagoSheet),
        const SizedBox(height: 16),
        if (_pagos.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Column(children: [Text('💸', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('Sin pagos registrados', style: TextStyle(color: PetSpaTheme.textSecondary))])))
        else ..._pagos.map((p) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: PetSpaTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: PetSpaTheme.gold.withOpacity(0.2))),
          child: Row(children: [
            const Text('💸', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['nombre_trabajador'] ?? '—', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(p['descripcion'] ?? '—', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
            ])),
            Text('Bs. ${p['monto'] ?? 0}', style: const TextStyle(color: PetSpaTheme.goldLight, fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
        )),
      ],
    );
  }

  void _showPagoSheet() async {
    final emps = await ApiService.getEmpleados();
    if (!mounted) return;
    final lista = emps['data'] as List? ?? [];
    int? empId = lista.isNotEmpty ? lista[0]['id_trabajadores'] as int? : null;
    final montoCtrl   = TextEditingController();
    final descCtrl    = TextEditingController();
    final desdeCtrl   = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final hastaCtrl   = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    String estadoPago = 'activo';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('💸 Registrar Pago', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          // Empleado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<int?>(
              isExpanded: true, value: empId, dropdownColor: PetSpaTheme.bgCard2,
              style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
              hint: const Text('Empleado', style: TextStyle(color: PetSpaTheme.textSecondary)),
              items: lista.map((e) => DropdownMenuItem<int?>(value: e['id_trabajadores'] as int?, child: Text(e['nombre'] ?? '—'))).toList(),
              onChanged: (v) => setS(() => empId = v),
            )),
          ),
          const SizedBox(height: 12),
          // Monto
          PetSpaTextField(controller: montoCtrl, label: 'Monto (Bs.) *', icon: Icons.attach_money, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          // Periodo desde - hasta (campos de BD: periodo_desde DATE, periodo_hasta DATE)
          Row(children: [
            Expanded(child: PetSpaTextField(controller: desdeCtrl, label: 'Período desde', icon: Icons.date_range)),
            const SizedBox(width: 10),
            Expanded(child: PetSpaTextField(controller: hastaCtrl, label: 'Período hasta', icon: Icons.date_range)),
          ]),
          const SizedBox(height: 12),
          // Descripcion
          PetSpaTextField(controller: descCtrl, label: 'Descripción', icon: Icons.notes),
          const SizedBox(height: 12),
          // estado_pago_empleado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              isExpanded: true, value: estadoPago, dropdownColor: PetSpaTheme.bgCard2,
              style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
              items: ['activo', 'inactivo'].map((s) => DropdownMenuItem(value: s, child: Text('Estado: $s'))).toList(),
              onChanged: (v) => setS(() => estadoPago = v ?? 'activo'),
            )),
          ),
          const SizedBox(height: 20),
          GradientButton(text: 'Registrar Pago', colors: const [PetSpaTheme.gold, Color(0xFFf97316)], onPressed: () async {
            final res = await ApiService.registrarPago({
              'id_trabajadores':      empId,
              'monto':                double.tryParse(montoCtrl.text) ?? 0,
              'descripcion':          descCtrl.text,
              'fecha_pago_empleado':  DateTime.now().toIso8601String().split('T')[0],
              'periodo_desde':        desdeCtrl.text,
              'periodo_hasta':        hastaCtrl.text,
              'estado_pago_empleado': estadoPago,
            });
            if (!mounted) return;
            Navigator.pop(ctx);
            if (res['success'] == true) { PetSpaSnack.show(context, 'Pago registrado'); _load(); }
            else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
          }),
        ]),
      )),
    );
  }

  Widget _buildLogInsumos() {
    if (_logInsumos.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('📦', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('Sin registros de insumos', style: TextStyle(color: PetSpaTheme.textSecondary))]));
    return RefreshIndicator(
      onRefresh: _load,
      color: PetSpaTheme.purple,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        itemCount: _logInsumos.length,
        itemBuilder: (_, i) {
          final log = _logInsumos[i];
          final dateStr = log['fecha_creacion'] != null 
              ? log['fecha_creacion'].toString().split('T')[0] 
              : '—';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PetSpaTheme.bgCard, 
              borderRadius: BorderRadius.circular(14), 
              border: Border.all(color: PetSpaTheme.purple.withOpacity(0.2))
            ),
            child: Row(children: [
              Container(
                width: 40, height: 40, 
                decoration: BoxDecoration(shape: BoxShape.circle, color: PetSpaTheme.purple.withOpacity(0.15)), 
                child: const Center(child: Text('📦', style: TextStyle(fontSize: 18)))
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(log['nombre_producto'] ?? '—', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('👤 Groomer: ${log['nombre_groomer'] ?? '—'}', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
                Text('📅 Cita #${log['id_cita']} | Fecha: $dateStr', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 10)),
              ])),
              Text('${log['unidades_usadas']} und.', style: const TextStyle(color: PetSpaTheme.tealLight, fontSize: 14, fontWeight: FontWeight.w800)),
            ]),
          );
        },
      ),
    );
  }
}
