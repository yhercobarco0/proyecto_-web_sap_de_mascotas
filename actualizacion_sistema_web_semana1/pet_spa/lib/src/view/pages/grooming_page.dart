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
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 4, vsync: this); _load(); }
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
    ]);
    if (mounted) setState(() {
      _citas = results[0]['data'] as List? ?? [];
      _cajas = results[1]['data'] as List? ?? [];
      _transacciones = results[2]['data'] as List? ?? [];
      _pagos = results[3]['data'] as List? ?? [];
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
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: '📋 Fichas'), Tab(text: '💰 Cajas'), Tab(text: '🔄 Transacc.'), Tab(text: '💸 Pagos')],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PetSpaTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tieneFicha ? PetSpaTheme.teal.withOpacity(0.3) : PetSpaTheme.purple.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🐶', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['nombre_mascota'] ?? 'Cita #${c['id_cita']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
            Text(c['nombre_del_servicio'] ?? '—', style: const TextStyle(fontSize: 11, color: PetSpaTheme.textSecondary)),
          ])),
          BadgeChip(label: tieneFicha ? 'Ficha OK' : 'Sin ficha', color: tieneFicha ? PetSpaTheme.success : PetSpaTheme.gold),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: () => _abrirFicha(c['id_cita'] ?? c['id_fichas_grooming']),
            style: ElevatedButton.styleFrom(backgroundColor: PetSpaTheme.teal, padding: const EdgeInsets.symmetric(vertical: 8)),
            child: const Text('📋 Ver/Abrir Ficha', style: TextStyle(fontSize: 12)),
          )),
        ]),
      ]),
    );
  }

  void _showNuevaFichaSheet() {
    final citaCtrl = TextEditingController();
    final espCtrl = TextEditingController(text: '15');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('📋 Nueva Ficha Grooming', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          PetSpaTextField(controller: citaCtrl, label: 'ID de Cita *', icon: Icons.numbers, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          PetSpaTextField(controller: espCtrl, label: 'Tiempo espera (min)', icon: Icons.timer, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          GradientButton(text: 'Crear Ficha', onPressed: () async {
            final res = await ApiService.crearFicha({'id_cita': int.tryParse(citaCtrl.text), 'tiempo_espera': int.tryParse(espCtrl.text) ?? 15});
            if (!mounted) return;
            Navigator.pop(ctx);
            if (res['success'] == true) { PetSpaSnack.show(context, 'Ficha creada'); _load(); }
            else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
          }),
        ]),
      ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(expand: false, initialChildSize: 0.7, builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('📋 Ficha #${ficha['id_fichas_grooming']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(ficha['fecha_cierre'] != null ? '✅ Ficha cerrada' : '🟡 Ficha abierta', style: TextStyle(color: ficha['fecha_cierre'] != null ? PetSpaTheme.success : PetSpaTheme.gold, fontSize: 13)),
          const SizedBox(height: 16),
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
            GradientButton(text: '➕ Agregar Insumo', colors: const [PetSpaTheme.teal, PetSpaTheme.tealLight], onPressed: () {
              Navigator.pop(context);
              _showAddInsumoSheet(ficha['id_fichas_grooming'], idCita);
            }),
            const SizedBox(height: 12),
            GradientButton(text: '🔒 Cerrar Ficha', colors: const [PetSpaTheme.danger, Color(0xFFf97316)], onPressed: () async {
              final r = await ApiService.cerrarFicha(ficha['id_fichas_grooming']);
              if (!mounted) return;
              Navigator.pop(context);
              if (r['success'] == true) { PetSpaSnack.show(context, 'Ficha cerrada'); _load(); }
            }),
          ],
        ]),
      )),
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
}
