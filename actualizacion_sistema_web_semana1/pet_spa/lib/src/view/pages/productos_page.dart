import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_service.dart';

class ProductosPage extends StatefulWidget {
  final bool esTienda;
  const ProductosPage({super.key, this.esTienda = false});
  @override State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  List _productos = [];
  List _filtered = [];
  List _carrito = [];
  bool _loading = true;
  final _search = TextEditingController();
  String _catFilter = '';

  final _categorias = ['', 'shampoo', 'accesorios', 'alimento', 'medicamento', 'juguetes', 'insumos'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getProductos();
    if (mounted) setState(() {
      _productos = res['data'] as List? ?? [];
      _filter();
      _loading = false;
    });
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() => _filtered = _productos.where((p) =>
      (p['nombre_producto'] ?? '').toLowerCase().contains(q) &&
      (_catFilter.isEmpty || (p['categoria'] ?? '').toLowerCase() == _catFilter)
    ).toList());
  }

  void _addToCart(Map p) {
    final idx = _carrito.indexWhere((c) => c['id_producto'] == p['id_producto']);
    if (idx >= 0) setState(() => _carrito[idx]['cantidad']++);
    else setState(() => _carrito.add({'id_producto': p['id_producto'], 'nombre': p['nombre_producto'], 'precio': p['precio'] ?? 0, 'cantidad': 1}));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${p['nombre_producto']} agregado 🛒'),
      backgroundColor: PetSpaTheme.teal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 1),
    ));
  }

  bool get _isAdmin => ApiService.role == 'Administrador' || ApiService.role == 'Recepción';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_carrito.isNotEmpty) FloatingActionButton.extended(
            heroTag: 'cart',
            onPressed: _showCarrito,
            backgroundColor: PetSpaTheme.teal,
            icon: Stack(children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              Positioned(right: 0, top: 0, child: Container(
                width: 14, height: 14,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: PetSpaTheme.gold),
                child: Center(child: Text('${_carrito.length}', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w900))),
              )),
            ]),
            label: Text('Bs. ${_carrito.fold<double>(0, (s, i) => s + (i['precio'] as num) * (i['cantidad'] as int)).toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          if (_isAdmin) ...[
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'add',
              onPressed: () => _showForm(),
              backgroundColor: PetSpaTheme.purple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nuevo Producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
      body: Column(children: [
        // BANNER
        Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [PetSpaTheme.teal.withOpacity(0.3), PetSpaTheme.purple.withOpacity(0.25)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: PetSpaTheme.teal.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('🛒 Tienda PetSpa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
                SizedBox(height: 4),
                Text('Los mejores productos para tu mascota', style: TextStyle(fontSize: 12, color: PetSpaTheme.textSecondary)),
              ])),
              Image.asset('assets/images/services_card.png', height: 80, fit: BoxFit.contain),
            ]),
          ),
        ),
        // SEARCH
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _search,
              onChanged: (_) => _filter(),
              style: const TextStyle(color: PetSpaTheme.textPrimary),
              decoration: const InputDecoration(hintText: 'Buscar producto...', prefixIcon: Icon(Icons.search, size: 20)),
            )),
          ]),
        ),
        // CATEGORY CHIPS
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _categorias.length,
            itemBuilder: (_, i) {
              final cat = _categorias[i];
              final label = cat.isEmpty ? 'Todos' : cat[0].toUpperCase() + cat.substring(1);
              final selected = cat == _catFilter;
              return GestureDetector(
                onTap: () { setState(() => _catFilter = cat); _filter(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: selected ? PetSpaTheme.gradientPurpleTeal : null,
                    color: selected ? null : PetSpaTheme.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? Colors.transparent : Colors.white.withOpacity(0.1)),
                  ),
                  child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : PetSpaTheme.textSecondary)),
                ),
              );
            },
          ),
        ),
        // GRID
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: PetSpaTheme.purple))
              : _filtered.isEmpty
                  ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('📦', style: TextStyle(fontSize: 48)), SizedBox(height: 12), Text('Sin productos', style: TextStyle(color: PetSpaTheme.textSecondary, fontSize: 16))]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: PetSpaTheme.purple,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 200, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.7),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildProductCard(_filtered[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildProductCard(Map p) {
    final stock = p['stok_unidad'] as int? ?? 0;
    final stockColor = stock == 0 ? PetSpaTheme.danger : stock <= 5 ? PetSpaTheme.gold : PetSpaTheme.success;
    final catEmoji = {'shampoo': '🧴', 'accesorios': '🎀', 'alimento': '🦴', 'medicamento': '💊', 'juguetes': '🎾', 'insumos': '🧹'}[p['categoria']] ?? '📦';

    return Container(
      decoration: BoxDecoration(
        color: PetSpaTheme.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [PetSpaTheme.teal.withOpacity(0.2), PetSpaTheme.purple.withOpacity(0.15)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Center(child: Text(catEmoji, style: const TextStyle(fontSize: 40))),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p['nombre_producto'] ?? '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Bs. ${p['precio'] ?? 0}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: PetSpaTheme.tealLight)),
            const SizedBox(height: 4),
            BadgeChip(label: '$stock und.', color: stockColor),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: stock > 0 ? () => (widget.esTienda || ApiService.role == 'Clientes') ? _addToCart(p) : _showStockModal(p) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    gradient: stock > 0 ? PetSpaTheme.gradientPurpleTeal : null,
                    color: stock == 0 ? Colors.white10 : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(
                    stock == 0 ? 'Sin stock' : (widget.esTienda || ApiService.role == 'Clientes') ? '🛒 Agregar' : '📦 Stock',
                    style: TextStyle(color: stock == 0 ? PetSpaTheme.textSecondary : Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  )),
                ),
              ),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showForm(prod: p),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white12)),
                  child: const Center(child: Text('✏️ Editar', style: TextStyle(color: PetSpaTheme.textSecondary, fontSize: 11))),
                ),
              ),
            ],
          ]),
        )),
      ]),
    );
  }

  void _showCarrito() {
    final total = _carrito.fold<double>(0, (s, i) => s + (i['precio'] as num) * (i['cantidad'] as int));
    showModalBottomSheet(
      context: context,
      backgroundColor: PetSpaTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('🛒 Mi Carrito', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 16),
          ..._carrito.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(child: Text(item['nombre'], style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
              Row(children: [
                GestureDetector(onTap: () => setS(() { if (item['cantidad'] > 1) item['cantidad']--; else _carrito.remove(item); }), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: PetSpaTheme.danger.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.remove, size: 14, color: PetSpaTheme.danger))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('${item['cantidad']}', style: const TextStyle(color: PetSpaTheme.textPrimary, fontWeight: FontWeight.w700))),
                GestureDetector(onTap: () => setS(() => item['cantidad']++), child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: PetSpaTheme.success.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.add, size: 14, color: PetSpaTheme.success))),
              ]),
              const SizedBox(width: 12),
              Text('Bs. ${((item['precio'] as num) * (item['cantidad'] as int)).toStringAsFixed(2)}', style: const TextStyle(color: PetSpaTheme.tealLight, fontWeight: FontWeight.w700)),
            ]),
          )),
          const Divider(color: Colors.white12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: PetSpaTheme.textPrimary)),
            Text('Bs. ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PetSpaTheme.tealLight)),
          ]),
          const SizedBox(height: 16),
          GradientButton(
            text: '✅ Confirmar Pedido',
            colors: const [PetSpaTheme.teal, PetSpaTheme.tealLight],
            onPressed: () async {
              final items = _carrito.map((i) => {'id_producto': i['id_producto'], 'cantidad': i['cantidad']}).toList();
              final res = await ApiService.crearPedido(items);
              if (!mounted) return;
              Navigator.pop(ctx);
              if (res['success'] == true) { PetSpaSnack.show(context, '¡Pedido realizado! 🎉'); setState(() => _carrito.clear()); }
              else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
            },
          ),
        ]),
      )),
    );
  }

  void _showStockModal(Map p) {
    final ctrl = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PetSpaTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('📦 Ajustar Stock — ${p['nombre_producto']}', style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 16)),
        content: TextField(controller: ctrl, keyboardType: TextInputType.number, style: const TextStyle(color: PetSpaTheme.textPrimary), decoration: const InputDecoration(labelText: 'Cantidad (+/-)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            final cant = int.tryParse(ctrl.text) ?? 0;
            final res = await ApiService.ajustarStock(p['id_producto'], cant);
            if (!mounted) return;
            Navigator.pop(ctx);
            if (res['success'] == true) { PetSpaSnack.show(context, 'Stock actualizado'); _load(); }
            else PetSpaSnack.show(context, res['message'] ?? 'Error', error: true);
          }, child: const Text('Confirmar')),
        ],
      ),
    );
  }

  void _showForm({Map? prod}) {
    final nameCtrl = TextEditingController(text: prod?['nombre_producto'] ?? '');
    final descCtrl = TextEditingController(text: prod?['descripcion'] ?? '');
    final precioCtrl = TextEditingController(text: prod?['precio']?.toString() ?? '');
    final stockCtrl = TextEditingController(text: prod?['stok_unidad']?.toString() ?? '0');
    String cat = prod?['categoria'] ?? 'accesorios';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PetSpaTheme.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(prod == null ? '📦 Nuevo Producto' : '✏️ Editar Producto', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: PetSpaTheme.textPrimary)),
          const SizedBox(height: 20),
          PetSpaTextField(controller: nameCtrl, label: 'Nombre *', icon: Icons.inventory_2_outlined),
          const SizedBox(height: 12),
          PetSpaTextField(controller: descCtrl, label: 'Descripción', icon: Icons.description_outlined),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: PetSpaTextField(controller: precioCtrl, label: 'Precio (Bs.)', icon: Icons.attach_money, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: PetSpaTextField(controller: stockCtrl, label: 'Stock', icon: Icons.warehouse_outlined, keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.12))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: cat,
                dropdownColor: PetSpaTheme.bgCard2,
                style: const TextStyle(color: PetSpaTheme.textPrimary, fontSize: 14),
                items: _categorias.where((c) => c.isNotEmpty).map((c) => DropdownMenuItem(value: c, child: Text(c[0].toUpperCase() + c.substring(1)))).toList(),
                onChanged: (v) => setS(() => cat = v ?? cat),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            text: prod == null ? 'Crear Producto' : 'Guardar Cambios',
            onPressed: () async {
              final data = {'nombre_producto': nameCtrl.text.trim(), 'descripcion': descCtrl.text.trim(), 'precio': double.tryParse(precioCtrl.text), 'stok_unidad': int.tryParse(stockCtrl.text) ?? 0, 'categoria': cat, if (prod != null) 'estado_de_producto': prod['estado_de_producto'] ?? 'activo'};
              final res = prod == null ? await ApiService.crearProducto(data) : await ApiService.actualizarProducto(prod['id_producto'], data);
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
}
