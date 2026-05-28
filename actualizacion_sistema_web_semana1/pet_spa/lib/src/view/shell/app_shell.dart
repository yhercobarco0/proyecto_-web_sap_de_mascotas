import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';
import '../auth/login_screen.dart';
import '../pages/dashboard_page.dart';
import '../pages/mascotas_page.dart';
import '../pages/citas_page.dart';
import '../pages/servicios_page.dart';
import '../pages/productos_page.dart';
import '../pages/grooming_page.dart';
import '../pages/reportes_page.dart';
import '../pages/empleados_page.dart';
import '../pages/clientes_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  List<_NavItem> get _navItems {
    final role = ApiService.role ?? 'Clientes';
    switch (role) {
      case 'Administrador':
        return [
          _NavItem('Dashboard', '📊', const DashboardPage()),
          _NavItem('Mascotas', '🐾', const MascotasPage()),
          _NavItem('Citas', '📅', const CitasPage()),
          _NavItem('Servicios', '✂️', const ServiciosPage()),
          _NavItem('Productos', '🛒', const ProductosPage()),
          _NavItem('Grooming', '🛁', const GroomingPage()),
          _NavItem('Clientes', '👥', const ClientesPage()),
          _NavItem('Empleados', '👷', const EmpleadosPage()),
          _NavItem('Reportes', '📈', const ReportesPage()),
        ];
      case 'Recepción':
        return [
          _NavItem('Dashboard', '📊', const DashboardPage()),
          _NavItem('Mascotas', '🐾', const MascotasPage()),
          _NavItem('Citas', '📅', const CitasPage()),
          _NavItem('Servicios', '✂️', const ServiciosPage()),
          _NavItem('Productos', '🛒', const ProductosPage()),
          _NavItem('Clientes', '👥', const ClientesPage()),
        ];
      case 'Groomers':
        return [
          _NavItem('Mis Servicios', '📅', const CitasPage(isGroomer: true)),
          _NavItem('Grooming', '🛁', const GroomingPage()),
          _NavItem('Productos', '🛒', const ProductosPage()),
        ];
      default: // Clientes
        return [
          _NavItem('Mis Mascotas', '🐾', const MascotasPage(soloMias: true)),
          _NavItem('Mis Citas', '📅', const CitasPage(soloMias: true)),
          _NavItem('Servicios', '✂️', const ServiciosPage()),
          _NavItem('Tienda', '🛒', const ProductosPage(esTienda: true)),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _navItems;
    final safeIndex = _selectedIndex.clamp(0, items.length - 1);

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR para tablet/desktop
          if (MediaQuery.of(context).size.width > 768)
            _buildSidebar(items, safeIndex),
          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                _buildTopBar(items[safeIndex]),
                Expanded(child: items[safeIndex].page),
              ],
            ),
          ),
        ],
      ),
      // BOTTOM NAV para móvil
      bottomNavigationBar: MediaQuery.of(context).size.width <= 768
          ? _buildBottomNav(items, safeIndex)
          : null,
      drawer: MediaQuery.of(context).size.width <= 768
          ? _buildDrawer(items, safeIndex)
          : null,
    );
  }

  Widget _buildTopBar(_NavItem item) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20, right: 20, bottom: 12,
      ),
      decoration: BoxDecoration(
        color: PetSpaTheme.bgCard,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width <= 768)
            Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu, color: PetSpaTheme.textPrimary),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            )),
          Text(item.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(item.label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
          const Spacer(),
          _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    final email = ApiService.email ?? '';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : '?';
    return PopupMenuButton(
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: PetSpaTheme.gradientPurpleTeal),
            child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(email.split('@').first, style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(ApiService.role ?? '', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down, color: PetSpaTheme.textSecondary, size: 18),
        ],
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red, size: 18), SizedBox(width: 8), Text('Cerrar sesión')])),
      ],
      onSelected: (v) async {
        if (v == 'logout') {
          await ApiService.clearSession();
          if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
        }
      },
    );
  }

  Widget _buildSidebar(List<_NavItem> items, int selected) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: PetSpaTheme.bgCard,
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          // LOGO
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20, left: 20, right: 20),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: PetSpaTheme.gradientPurpleTeal,
                    boxShadow: [BoxShadow(color: PetSpaTheme.purple.withOpacity(0.4), blurRadius: 12)]),
                  child: const Center(child: Text('🐾', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback: (b) => PetSpaTheme.gradientPurpleTeal.createShader(b),
                  child: const Text('PetSpa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ],
            ),
          ),
          // NAV ITEMS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              itemCount: items.length,
              itemBuilder: (_, i) => _SidebarItem(
                item: items[i],
                isSelected: i == selected,
                onTap: () => setState(() => _selectedIndex = i),
              ),
            ),
          ),
          // USER INFO
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: PetSpaTheme.gradientPurpleTeal),
                  child: Center(child: Text(
                    (ApiService.email ?? '?')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  )),
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ApiService.email?.split('@').first ?? '', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    Text(ApiService.role ?? '', style: const TextStyle(color: PetSpaTheme.textSecondary, fontSize: 10)),
                  ],
                )),
                GestureDetector(
                  onTap: () async { await ApiService.clearSession(); if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false); },
                  child: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(List<_NavItem> items, int selected) {
    final visible = items.take(5).toList();
    return NavigationBar(
      backgroundColor: PetSpaTheme.bgCard,
      selectedIndex: selected.clamp(0, visible.length - 1),
      onDestinationSelected: (i) => setState(() => _selectedIndex = i),
      destinations: visible.map((it) => NavigationDestination(
        icon: Text(it.emoji, style: const TextStyle(fontSize: 22)),
        label: it.label,
      )).toList(),
    );
  }

  Widget _buildDrawer(List<_NavItem> items, int selected) {
    return Drawer(
      backgroundColor: PetSpaTheme.bgCard,
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                const Text('🐾', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (b) => PetSpaTheme.gradientPurpleTeal.createShader(b),
                  child: const Text('PetSpa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ]),
            ),
            ...items.asMap().entries.map((e) => _SidebarItem(
              item: e.value,
              isSelected: e.key == selected,
              onTap: () { setState(() => _selectedIndex = e.key); Navigator.pop(context); },
            )),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String emoji;
  final Widget page;
  const _NavItem(this.label, this.emoji, this.page);
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  const _SidebarItem({required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [Color(0x337c3aed), Color(0x1514b8a6)], begin: Alignment.centerLeft, end: Alignment.centerRight) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? PetSpaTheme.purple.withOpacity(0.4) : Colors.transparent),
        ),
        child: Row(children: [
          Text(item.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(item.label, style: TextStyle(
            color: isSelected ? PetSpaTheme.textPrimary : PetSpaTheme.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          )),
          if (isSelected) ...[
            const Spacer(),
            Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: PetSpaTheme.purple)),
          ],
        ]),
      ),
    );
  }
}
