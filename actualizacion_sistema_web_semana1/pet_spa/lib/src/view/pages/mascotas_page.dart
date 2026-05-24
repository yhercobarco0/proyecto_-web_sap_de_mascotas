import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class MascotasPage extends StatefulWidget {
  final bool soloMias;
  const MascotasPage({super.key, this.soloMias = false});
  @override
  State<MascotasPage> createState() => _MascotasPageState();
}

class _MascotasPageState extends State<MascotasPage> {
  List _mascotas = [];
  List _filtered = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = widget.soloMias || ApiService.role == 'Clientes'
        ? await ApiService.getMisMascotas()
        : await ApiService.getAllMascotas();
    if (mounted) setState(() {
      _mascotas = res['data'] as List? ?? [];
      _filtered = _mascotas;
      _loading = false;
    });
  }

  void _filter(String q) {
    setState(() => _filtered = q.isEmpty ? _mascotas : _mascotas.where((m) =>
      (m['nombre_mascota'] ?? '').toLowerCase().contains(q.toLowerCase()) ||
      (m['raza'] ?? '').toLowerCase().contains(q.toLowerCase()) ||
      (m['nombre_dueño'] ?? '').toLowerCase().contains(q.toLowerCase())
    ).toList());
  }

  String _getEmoji(String? raza) {
    final r = (raza ?? '').toLowerCase();
    if (r.contains('gato') || r.contains('cat') || r.contains('felino')) return '🐱';
    if (r.contains('conejo') || r.contains('rabbit')) return '🐰';
    if (r.contains('ave') || r.contains('loro') || r.contains('bird')) return '🦜';
    return '🐶';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: PetSpaTheme.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Mascota', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(children: [
        // PETS COLLAGE BANNER
        Container(
          height: 140,
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(children: [
              Positioned.fill(child: Image.asset('assets/images/pets_collage.png', fit: BoxFit.cover)),
              Positioned.fill(child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [PetSpaTheme.bgDark.withOpacity(0.5), Colors.transparent]),
                ),
              )),
              const Positioned(left: 20, bottom: 16, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🐾 Mis Mascotas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  Text('Todos tus peludos favoritos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              )),
            ]),
          ),
        ),
        // SEARCH
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: TextField(
            controller: _search,
            onChanged: _filter,
            style: const TextStyle(color: PetSpaTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, raza...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _search.text.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _search.clear(); _filter(''); })
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // LIST
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple))
              : _filtered.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: PetSpaTheme.purple,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildPetCard(_filtered[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildPetCard(Map m) {
    final colors = [
      [PetSpaTheme.purple, PetSpaTheme.purpleLight],
      [PetSpaTheme.teal, PetSpaTheme.tealLight],
      [PetSpaTheme.gold, PetSpaTheme.goldLight],
      [PetSpaTheme.pink, const Color(0xFFf472b6)],
    ];
    final colorSet = colors[(m['id_mascota'] ?? 0) % colors.length];

    return GestureDetector(
      onTap: () => _showPetDetail(m),
      child: Container(
        decoration: BoxDecoration(
          color: PetSpaTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colorSet.map((c) => c.withOpacity(0.3)).toList()),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(child: Text(_getEmoji(m['raza']), style: const TextStyle(fontSize: 52))),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['nombre_mascota'] ?? '—', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(m['raza'] ?? 'Sin raza', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    if (m['edad'] != null)
                      Row(children: [
                        const Icon(Icons.cake_outlined, size: 12, color: PetSpaTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('${m['edad']} años', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
                      ]),
                    if (m['peso'] != null) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.monitor_weight_outlined, size: 12, color: PetSpaTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('${m['peso']} kg', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
                      ]),
                    ],
                    if (m['nombre_dueño'] != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.person_outline, size: 12, color: PetSpaTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(child: Text(m['nombre_dueño'], style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                    ],
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: GestureDetector(
                        onTap: () => _showFormDialog(mascota: m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(color: PetSpaTheme.purple.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: PetSpaTheme.purple.withOpacity(0.3))),
                          child: const Center(child: Text('✏️', style: TextStyle(fontSize: 14))),
                        ),
                      )),
                      const SizedBox(width: 6),
                      Expanded(child: GestureDetector(
                        onTap: () => _showVacunas(m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(color: PetSpaTheme.teal.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: PetSpaTheme.teal.withOpacity(0.3))),
                          child: const Center(child: Text('💉', style: TextStyle(fontSize: 14))),
                        ),
                      )),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPetDetail(Map m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 20),
          Text(_getEmoji(m['raza']), style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(m['nombre_mascota'] ?? '—', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          _DetailRow('Raza', m['raza'] ?? '—'),
          _DetailRow('Edad', m['edad'] != null ? '${m['edad']} años' : '—'),
          _DetailRow('Peso', m['peso'] != null ? '${m['peso']} kg' : '—'),
          _DetailRow('Tamaño', m['tamano'] != null ? '${m['tamano']} cm' : '—'),
          if (m['nombre_dueño'] != null) _DetailRow('Dueño', m['nombre_dueño']),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: GradientButton(text: '✏️ Editar', onPressed: () { Navigator.pop(context); _showFormDialog(mascota: m); }, colors: const [PetSpaTheme.purple, PetSpaTheme.purpleLight])),
            const SizedBox(width: 12),
            Expanded(child: GradientButton(text: '💉 Vacunas', onPressed: () { Navigator.pop(context); _showVacunas(m); }, colors: const [PetSpaTheme.teal, PetSpaTheme.tealLight])),
          ]),
        ]),
      ),
    );
  }

  void _showFormDialog({Map? mascota}) {
    final nameCtrl  = TextEditingController(text: mascota?['nombre_mascota'] ?? '');
    final razaCtrl  = TextEditingController(text: mascota?['raza'] ?? '');
    final edadCtrl  = TextEditingController(text: mascota?['edad']?.toString() ?? '');
    final pesoCtrl  = TextEditingController(text: mascota?['peso']?.toString() ?? '');
    final tamanoCtrl = TextEditingController(text: mascota?['tamano']?.toString() ?? '');
    final fotoCtrl  = TextEditingController(text: mascota?['foto_mascota'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(mascota == null ? '🐾 Nueva Mascota' : '✏️ Editar Mascota',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          // Nombre y raza
          PetSpaTextField(controller: nameCtrl, label: 'Nombre *', icon: Icons.pets),
          const SizedBox(height: 12),
          PetSpaTextField(controller: razaCtrl, label: 'Raza / Especie', icon: Icons.category_outlined),
          const SizedBox(height: 12),
          // Edad y peso
          Row(children: [
            Expanded(child: PetSpaTextField(controller: edadCtrl, label: 'Edad (años)', icon: Icons.cake_outlined, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: PetSpaTextField(controller: pesoCtrl, label: 'Peso (kg)', icon: Icons.monitor_weight_outlined, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          ]),
          const SizedBox(height: 12),
          // Tamaño (campo de la BD: tamano NUMERIC(5,2))
          PetSpaTextField(
            controller: tamanoCtrl,
            label: 'Tamaño (cm / referencia)',
            icon: Icons.straighten,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          // Foto de la mascota (URL o path)
          PetSpaTextField(
            controller: fotoCtrl,
            label: 'URL de foto (opcional)',
            icon: Icons.photo_camera_outlined,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          // Preview si hay URL
          if (fotoCtrl.text.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(fotoCtrl.text, height: 120, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          const SizedBox(height: 20),
          GradientButton(
            text: mascota == null ? 'Registrar Mascota' : 'Guardar Cambios',
            onPressed: () async {
              final data = {
                'nombre_mascota': nameCtrl.text.trim(),
                'raza':           razaCtrl.text.trim(),
                'edad':           int.tryParse(edadCtrl.text),
                'peso':           double.tryParse(pesoCtrl.text),
                'tamano':         double.tryParse(tamanoCtrl.text),
                'foto_mascota':   fotoCtrl.text.trim().isEmpty ? null : fotoCtrl.text.trim(),
              };
              final res = mascota == null
                  ? await ApiService.crearMascota(data)
                  : await ApiService.actualizarMascota(mascota['id_mascota'], data);
              if (!mounted) return;
              Navigator.pop(context);
              if (res['success'] == true) { PetSpaSnack.show(context, res['message'] ?? 'Guardado'); _load(); }
              else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
            },
          ),
        ]),
      )),
    );
  }

  Future<void> _showVacunas(Map m) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple)));
    final res = await ApiService.getVacunas(m['id_mascota']);
    if (!mounted) return;
    Navigator.pop(context);
    final vacunas = res['data'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: PetSpaTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text('💉 Vacunas — ${m['nombre_mascota']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary))),
              if (ApiService.role == 'Administrador' || ApiService.role == 'Groomers')
                IconButton(
                  icon: const Icon(Icons.add_circle, color: PetSpaTheme.teal, size: 28),
                  onPressed: () { Navigator.pop(context); _showNuevaVacunaSheet(m); },
                ),
            ]),
            const SizedBox(height: 16),
            if (vacunas.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Sin vacunas registradas', style: TextStyle(color: PetSpaTheme.textSecondary))))
            else
              ...vacunas.map((v) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: PetSpaTheme.teal.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: PetSpaTheme.teal.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.vaccines, color: PetSpaTheme.teal, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(v['nombre_vacuna'] ?? '—', style: const TextStyle(color: PetSpaTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Aplicada: ${v['fecha_aplicacion'] ?? '—'}', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
                    if (v['fecha_proxima'] != null)
                      Text('Próxima: ${v['fecha_proxima']}', style: const TextStyle(color: PetSpaTheme.gold, fontSize: 11)),
                    if (v['observacion'] != null && v['observacion'].toString().isNotEmpty)
                      Text('Obs: ${v['observacion']}', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11, fontStyle: FontStyle.italic)),
                  ])),
                ]),
              )),
          ]),
        ),
      ),
    );
  }

  void _showNuevaVacunaSheet(Map m) async {
    final catRes = await ApiService.getCatalogoVacunas();
    final empsRes = await ApiService.getEmpleados();
    if (!mounted) return;
    
    final catalogo = catRes['data'] as List? ?? [];
    final empleados = empsRes['data'] as List? ?? [];
    
    int? idVacuna = catalogo.isNotEmpty ? catalogo[0]['id_vacuna'] : null;
    int? idTrabajador = empleados.isNotEmpty ? empleados[0]['id_trabajadores'] : null;
    final fechaCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final proximaCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => SingleChildScrollView(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('💉 Registrar Vacuna', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<int?>(
              isExpanded: true, value: idVacuna, dropdownColor: PetSpaTheme.bgCard2, style: const TextStyle(color: PetSpaTheme.textPrimary),
              hint: const Text('Seleccionar vacuna'),
              items: catalogo.map((v) => DropdownMenuItem<int?>(value: v['id_vacuna'] as int?, child: Text(v['nombre_vacuna']))).toList(),
              onChanged: (v) => setS(() => idVacuna = v),
            )),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<int?>(
              isExpanded: true, value: idTrabajador, dropdownColor: PetSpaTheme.bgCard2, style: const TextStyle(color: PetSpaTheme.textPrimary),
              hint: const Text('Aplicada por'),
              items: empleados.map((e) => DropdownMenuItem<int?>(value: e['id_trabajadores'] as int?, child: Text(e['nombre']))).toList(),
              onChanged: (v) => setS(() => idTrabajador = v),
            )),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PetSpaTextField(controller: fechaCtrl, label: 'Fecha aplicación', icon: Icons.calendar_today)),
            const SizedBox(width: 12),
            Expanded(child: PetSpaTextField(controller: proximaCtrl, label: 'Próxima (Opc)', icon: Icons.event)),
          ]),
          const SizedBox(height: 12),
          PetSpaTextField(controller: obsCtrl, label: 'Observaciones', icon: Icons.notes),
          const SizedBox(height: 20),
          GradientButton(
            text: 'Registrar Vacuna',
            onPressed: () async {
              if (idVacuna == null || idTrabajador == null) { PetSpaSnack.show(context, 'Faltan datos', error: true); return; }
              final res = await ApiService.registrarVacuna({
                'id_mascota': m['id_mascota'], 'id_vacuna': idVacuna, 'id_trabajadores': idTrabajador,
                'fecha_aplicacion': fechaCtrl.text, 'fecha_proxima': proximaCtrl.text.isEmpty ? null : proximaCtrl.text, 'observacion': obsCtrl.text,
              });
              if (!mounted) return;
              Navigator.pop(ctx);
              if (res['success'] == true) { PetSpaSnack.show(context, 'Vacuna registrada'); _showVacunas(m); }
              else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
            },
          ),
        ]),
      )),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('🐾', style: TextStyle(fontSize: 64)),
    const SizedBox(height: 12),
    const Text('Sin mascotas aún', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
    const SizedBox(height: 6),
    const Text('Agrega tu primera mascota con el botón +', style: TextStyle(color: PetSpaTheme.textSecondary, fontSize: 13)),
  ]));
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
