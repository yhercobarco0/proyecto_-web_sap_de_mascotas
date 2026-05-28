import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});
  @override State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map? _dashboard;
  Map? _ventas;
  List _servicios = [];
  List _groomers = [];
  List _opiniones = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _tabs = TabController(length: 3, vsync: this); _load(); }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait(<Future<Map<String,dynamic>>>[
      ApiService.getDashboard(),
      ApiService.getResumenVentas(),
      ApiService.getServiciosPopulares(),
      ApiService.getRendimientoGroomers(),
      ApiService.getAllOpiniones(),
    ]);
    if (mounted) setState(() {
      _dashboard = results[0]['data'] as Map?;
      _ventas = results[1]['data'] as Map?;
      _servicios = results[2]['data'] as List? ?? [];
      _groomers = results[3]['data'] as List? ?? [];
      _opiniones = results[4]['data'] as List? ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple))
          : Column(children: [
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
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  tabs: const [Tab(text: '💰 Ventas'), Tab(text: '✂️ Groomers'), Tab(text: '⭐ Opiniones')],
                ),
              ),
              Expanded(child: TabBarView(controller: _tabs, children: [_buildVentas(), _buildGroomers(), _buildOpiniones()])),
            ]),
    );
  }

  Widget _buildVentas() {
    final stats = [
      {'label': 'Citas terminadas', 'value': '${_dashboard?['citas_mes'] ?? _ventas?['total_citas'] ?? 0}', 'emoji': '📅', 'colors': [PetSpaTheme.purple, PetSpaTheme.purpleLight]},
      {'label': 'Ingresos (Bs.)', 'value': '${_ventas?['ingresos_servicios'] ?? 0}', 'emoji': '💰', 'colors': [PetSpaTheme.teal, PetSpaTheme.tealLight]},
      {'label': 'Promedio cita', 'value': '${_ventas?['promedio_servicio'] ?? 0}', 'emoji': '📊', 'colors': [PetSpaTheme.gold, PetSpaTheme.goldLight]},
      {'label': 'Productos vend.', 'value': '${_ventas?['productos_vendidos'] ?? 0}', 'emoji': '🛒', 'colors': [PetSpaTheme.pink, const Color(0xFFf472b6)]},
    ];
    return RefreshIndicator(onRefresh: _load, color: PetSpaTheme.purple, child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.5, children: stats.map((s) => StatCard(label: s['label'] as String, value: s['value'] as String, emoji: s['emoji'] as String, colors: (s['colors'] as List).cast<Color>())).toList()),
        const SizedBox(height: 20),
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle(title: 'Servicios Más Populares', emoji: '✂️'),
          const SizedBox(height: 16),
          if (_servicios.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Sin datos', style: TextStyle(color: PetSpaTheme.textSecondary))))
          else ..._servicios.map((s) {
            final maxCitas = (_servicios.first['total_citas'] as num? ?? 1).toDouble();
            final curr = (s['total_citas'] as num? ?? 0).toDouble();
            final pct = maxCitas > 0 ? curr / maxCitas : 0.0;
            return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(s['nombre_del_servicio'] ?? '—', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text('${s['total_citas']} | Bs. ${s['ingresos_totales'] ?? 0}', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white.withOpacity(0.06), valueColor: const AlwaysStoppedAnimation(PetSpaTheme.purple), minHeight: 7)),
            ]));
          }),
        ])),
      ]),
    ));
  }

  Widget _buildGroomers() {
    if (_groomers.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('✂️', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('Sin datos de groomers', style: TextStyle(color: PetSpaTheme.textSecondary))]));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: _groomers.length,
      itemBuilder: (_, i) {
        final g = _groomers[i];
        final cal = (g['calificacion_promedio'] as num?)?.toDouble() ?? 0.0;
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: PetSpaTheme.bgCard, borderRadius: BorderRadius.circular(18), border: Border.all(color: PetSpaTheme.purple.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, gradient: PetSpaTheme.gradientPurpleTeal), child: Center(child: Text((g['nombre'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g['nombre'] ?? '—', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
                Text('${g['total_servicios'] ?? 0} servicios', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('Bs. ${g['ingresos_generados'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PetSpaTheme.tealLight)),
                Row(children: List.generate(5, (si) => Icon(Icons.star, size: 12, color: si < cal.round() ? PetSpaTheme.gold : Colors.white12))),
              ]),
            ]),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: cal / 5, backgroundColor: Colors.white.withOpacity(0.06), valueColor: const AlwaysStoppedAnimation(PetSpaTheme.gold), minHeight: 5)),
            const SizedBox(height: 4),
            Text('Calificación: ${cal.toStringAsFixed(1)} / 5.0', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
          ]),
        );
      },
    );
  }

  Widget _buildOpiniones() {
    if (_opiniones.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('⭐', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('Sin opiniones', style: TextStyle(color: PetSpaTheme.textSecondary))]));
    final promedio = _opiniones.fold<double>(0.0, (s, o) => s + ((o['calificacion'] as num?) ?? 0)) / _opiniones.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(children: [
        GlassCard(padding: const EdgeInsets.all(24), child: Column(children: [
          Text(promedio.toStringAsFixed(1), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: PetSpaTheme.goldLight)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => Icon(Icons.star, size: 28, color: i < promedio.round() ? PetSpaTheme.gold : Colors.white12))),
          const SizedBox(height: 6),
          Text('${_opiniones.length} opiniones en total', style: const TextStyle(color: PetSpaTheme.textSecondary)),
          const SizedBox(height: 16),
          ...[5, 4, 3, 2, 1].map((n) {
            final count = _opiniones.where((o) => o['calificacion'] == n).length;
            final pct = _opiniones.isNotEmpty ? count / _opiniones.length : 0.0;
            return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
              Text('$n', style: const TextStyle(color: PetSpaTheme.gold, fontWeight: FontWeight.w700, fontSize: 13)),
              const Icon(Icons.star, size: 12, color: PetSpaTheme.gold),
              const SizedBox(width: 8),
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white.withOpacity(0.06), valueColor: const AlwaysStoppedAnimation(PetSpaTheme.gold), minHeight: 8))),
              const SizedBox(width: 8),
              SizedBox(width: 24, child: Text('$count', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12), textAlign: TextAlign.right)),
            ]));
          }),
        ])),
        const SizedBox(height: 16),
        ..._opiniones.take(10).map((o) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: PetSpaTheme.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(o['nombre_cliente'] ?? '—', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
              Row(children: List.generate(5, (i) => Icon(Icons.star, size: 12, color: i < (o['calificacion'] as int? ?? 0) ? PetSpaTheme.gold : Colors.white12))),
            ]),
            if (o['comentario'] != null) ...[const SizedBox(height: 6), Text(o['comentario'], style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 12))],
            const SizedBox(height: 4),
            Text('${o['nombre_mascota'] ?? ''} • ${o['fecha_opinion'] ?? ''}', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 10)),
          ]),
        )),
      ]),
    );
  }
}
