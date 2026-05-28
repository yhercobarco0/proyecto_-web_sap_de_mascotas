import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import 'dart:math';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _stats;
  List _servicios = [];
  List _opiniones = [];
  List _stock = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait(<Future<Map<String,dynamic>>>[
      ApiService.getDashboard(),
      ApiService.getServiciosPopulares(),
      ApiService.getOpinionesRecientes(),
      ApiService.getStockCritico(),
    ]);
    if (mounted) setState(() {
      _stats = results[0]['data'] as Map<String, dynamic>?;
      _servicios = results[1]['data'] as List? ?? [];
      _opiniones = results[2]['data'] as List? ?? [];
      _stock = results[3]['data'] as List? ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildShimmer();
    return RefreshIndicator(
      onRefresh: _load,
      color: PetSpaTheme.purple,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // HERO BANNER
          _buildHeroBanner(),
          const SizedBox(height: 24),
          // STATS
          _buildStatsGrid(),
          const SizedBox(height: 28),
          // ROW: Servicios + Opiniones
          LayoutBuilder(builder: (ctx, c) {
            if (c.maxWidth > 600) {
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _buildServiciosPopulares()),
                const SizedBox(width: 16),
                Expanded(child: _buildOpinionesRecientes()),
              ]);
            }
            return Column(children: [
              _buildServiciosPopulares(),
              const SizedBox(height: 16),
              _buildOpinionesRecientes(),
            ]);
          }),
          const SizedBox(height: 20),
          _buildStockCritico(),
          const SizedBox(height: 20),
          _buildGroomingImage(),
        ]),
      ),
    );
  }

  Widget _buildHeroBanner() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? '🌅 Buenos días' : hour < 18 ? '☀️ Buenas tardes' : '🌙 Buenas noches';
    return Container(
      height: 180,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(children: [
          Positioned.fill(child: Image.asset('assets/images/hero_banner.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [PetSpaTheme.bgDark.withOpacity(0.6), Colors.transparent],
                begin: Alignment.centerLeft, end: Alignment.centerRight,
              ),
            ),
          )),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('${ApiService.email?.split('@').first ?? 'Admin'} 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: PetSpaTheme.purple.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(ApiService.role ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {'label': 'Citas hoy', 'value': '${_stats?['citas_hoy'] ?? 0}', 'emoji': '📅', 'colors': [PetSpaTheme.purple, PetSpaTheme.purpleLight]},
      {'label': 'Clientes', 'value': '${_stats?['clientes_total'] ?? 0}', 'emoji': '👥', 'colors': [PetSpaTheme.teal, PetSpaTheme.tealLight]},
      {'label': 'Mascotas', 'value': '${_stats?['mascotas_total'] ?? 0}', 'emoji': '🐾', 'colors': [PetSpaTheme.gold, PetSpaTheme.goldLight]},
      {'label': 'Ingresos mes', 'value': 'Bs. ${_stats?['ingresos_mes'] ?? 0}', 'emoji': '💰', 'colors': [PetSpaTheme.pink, const Color(0xFFf472b6)]},
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: stats.map((s) => StatCard(
        label: s['label'] as String,
        value: s['value'] as String,
        emoji: s['emoji'] as String,
        colors: (s['colors'] as List).cast<Color>(),
      )).toList(),
    );
  }

  Widget _buildServiciosPopulares() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle(title: 'Servicios Populares', emoji: '✂️'),
        const SizedBox(height: 16),
        if (_servicios.isEmpty)
          _emptyState('Aún no hay datos de servicios')
        else
          ..._servicios.take(4).map((s) {
            final max = (_servicios.first['total_citas'] as num? ?? 1).toDouble();
            final curr = (s['total_citas'] as num? ?? 0).toDouble();
            final pct = max > 0 ? curr / max : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(s['nombre_del_servicio'] ?? '', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text('${s['total_citas']} citas', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    valueColor: const AlwaysStoppedAnimation(PetSpaTheme.purple),
                    minHeight: 6,
                  ),
                ),
              ]),
            );
          }),
      ]),
    );
  }

  Widget _buildOpinionesRecientes() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle(title: 'Opiniones', emoji: '⭐'),
        const SizedBox(height: 16),
        if (_opiniones.isEmpty)
          _emptyState('Sin opiniones aún')
        else
          ..._opiniones.take(4).map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: PetSpaTheme.purple.withOpacity(0.2),
                  border: Border.all(color: PetSpaTheme.purple.withOpacity(0.3)),
                ),
                child: Center(child: Text(
                  (o['nombre_cliente'] ?? '?')[0].toUpperCase(),
                  style: const TextStyle(color: PetSpaTheme.purpleLight, fontWeight: FontWeight.w700),
                )),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(o['nombre_cliente'] ?? '—', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
                  Row(children: List.generate(5, (i) => Icon(Icons.star, size: 11, color: i < (o['calificacion'] ?? 0) ? PetSpaTheme.gold : Colors.white12))),
                ]),
                if (o['comentario'] != null)
                  Text(o['comentario'], style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ])),
            ]),
          )),
      ]),
    );
  }

  Widget _buildStockCritico() {
    if (_stock.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      borderColor: PetSpaTheme.gold.withOpacity(0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionTitle(title: 'Stock Crítico', emoji: '⚠️'),
        const SizedBox(height: 14),
        ..._stock.take(4).map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Expanded(child: Text(p['nombre_producto'] ?? '—', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13))),
            BadgeChip(
              label: '${p['stok_unidad']} unidades',
              color: (p['stok_unidad'] as num? ?? 0) == 0 ? PetSpaTheme.danger : PetSpaTheme.gold,
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _buildGroomingImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(children: [
        Image.asset('assets/images/grooming_scene.png', width: double.infinity, height: 200, fit: BoxFit.cover),
        Positioned.fill(child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, PetSpaTheme.bgDark.withOpacity(0.7)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
            ),
          ),
        )),
        const Positioned(bottom: 20, left: 20, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Grooming Premium', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          Text('Servicio de calidad para tu mascota ✨', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(child: Text(msg, style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 13))),
  );

  Widget _buildShimmer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: List.generate(4, (_) => Container(
        height: 100, margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: PetSpaTheme.bgCard, borderRadius: BorderRadius.circular(16)),
      ))),
    );
  }
}
