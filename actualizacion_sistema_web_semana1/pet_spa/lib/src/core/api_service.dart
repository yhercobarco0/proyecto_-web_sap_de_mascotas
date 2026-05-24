import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _baseUrl = 'http://localhost:3000/api';

class ApiService {
  static String? _token;
  static String? _role;
  static String? _email;

  static String? get token => _token;
  static String? get role => _role;
  static String? get email => _email;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('petspa_token');
    _role = prefs.getString('petspa_role');
    _email = prefs.getString('petspa_email');
  }

  static Future<void> saveSession(String token, String role, String email) async {
    _token = token;
    _role = role;
    _email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('petspa_token', token);
    await prefs.setString('petspa_role', role);
    await prefs.setString('petspa_email', email);
  }

  static Future<void> clearSession() async {
    _token = null; _role = null; _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('petspa_token');
    await prefs.remove('petspa_role');
    await prefs.remove('petspa_email');
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> _handleResponse(http.Response res) async {
    try {
      final data = json.decode(res.body);
      return data is Map<String, dynamic> ? data : {'data': data, 'success': true};
    } catch (_) {
      return {'success': false, 'message': 'Respuesta inválida del servidor'};
    }
  }

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers);
      return _handleResponse(res);
    } catch (_) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(Uri.parse('$_baseUrl$path'), headers: _headers, body: json.encode(body));
      return _handleResponse(res);
    } catch (_) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.put(Uri.parse('$_baseUrl$path'), headers: _headers, body: json.encode(body));
      return _handleResponse(res);
    } catch (_) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await http.delete(Uri.parse('$_baseUrl$path'), headers: _headers);
      return _handleResponse(res);
    } catch (_) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // AUTH
  static login(String email, String pass) => post('/login', {'email': email, 'password': pass});
  static registroCliente(Map<String, dynamic> d) => post('/registro_cliente', d);
  static verify2FA(String tempToken, String otp) => post('/verify_2fa', {'token': tempToken, 'otp': otp});

  // MASCOTAS
  static getMisMascotas() => get('/mascotas/mis_mascotas');
  static getAllMascotas() => get('/mascotas/admin');
  static crearMascota(Map<String, dynamic> d) => post('/mascotas', d);
  static actualizarMascota(int id, Map<String, dynamic> d) => put('/mascotas/$id', d);
  static getVacunas(int id) => get('/mascotas/$id/vacunas');
  static registrarVacuna(Map<String, dynamic> d) => post('/mascotas/vacunas/registrar', d);
  static getCatalogoVacunas() => get('/mascotas/vacunas/catalogo');

  // CITAS
  static getAllCitas() => get('/citas/admin');
  static getCitasByFecha(String fecha) => get('/citas/por_fecha?fecha=$fecha');
  static getMisCitas() => get('/citas/mis_citas');
  static getMisServicios() => get('/citas/mis_servicios');
  static crearCita(Map<String, dynamic> d) => post('/citas', d);
  static actualizarCita(int id, Map<String, dynamic> d) => put('/citas/$id', d);
  static terminarCita(int id, Map<String, dynamic> d) => post('/citas/$id/terminar', d);
  static cancelarCita(int id) => post('/citas/$id/cancelar', {'motivo': 'Cancelado por usuario'});
  static registrarOpinion(Map<String, dynamic> d) => post('/citas/registrar_opinion', d);
  static getMisOpiniones() => get('/citas/mis_opiniones');
  static getAllOpiniones() => get('/citas/opiniones/admin');

  // SERVICIOS
  static getServicios() => get('/servicios');
  static crearServicio(Map<String, dynamic> d) => post('/servicios', d);
  static actualizarServicio(int id, Map<String, dynamic> d) => put('/servicios/$id', d);
  static eliminarServicio(int id) => delete('/servicios/$id');

  // PRODUCTOS
  static getProductos() => get('/productos');
  static crearProducto(Map<String, dynamic> d) => post('/productos', d);
  static actualizarProducto(int id, Map<String, dynamic> d) => put('/productos/$id', d);
  static ajustarStock(int id, int cant) => post('/productos/$id/stock', {'cantidad': cant});
  static getStockBajo() => get('/productos/bajo_stock');
  static crearPedido(List items) => post('/productos/pedidos/nuevo', {'items': items});
  static getMisPedidos() => get('/productos/pedidos/mis_pedidos');
  static getAllPedidos() => get('/productos/pedidos/admin');

  // GROOMING
  static getGroomers() => get('/grooming/groomers');
  static crearFicha(Map<String, dynamic> d) => post('/grooming/fichas', d);
  static getFichaByCita(int id) => get('/grooming/fichas/cita/$id');
  static cerrarFicha(int id) => post('/grooming/fichas/$id/cerrar', {});
  static registrarInsumo(Map<String, dynamic> d) => post('/grooming/fichas/insumos', d);
  static getMisFichas() => get('/grooming/fichas/mis_fichas');
  static getCajas() => get('/grooming/cajas');
  static crearCaja(Map<String, dynamic> d) => post('/grooming/cajas', d);
  static crearTransaccion(Map<String, dynamic> d) => post('/grooming/transacciones', d);
  static getAllTransacciones() => get('/grooming/transacciones');
  static getAllPagos() => get('/grooming/pagos');
  static registrarPago(Map<String, dynamic> d) => post('/grooming/pagos', d);

  // REPORTES
  static getDashboard() => get('/reportes/dashboard');
  static getResumenVentas() => get('/reportes/ventas');
  static getServiciosPopulares() => get('/reportes/servicios_populares');
  static getRendimientoGroomers() => get('/reportes/rendimiento_groomers');
  static getStockCritico() => get('/reportes/stock_critico');
  static getOpinionesRecientes() => get('/reportes/opiniones_recientes');

  // EMPLEADOS / CLIENTES
  static getEmpleados() => get('/empleados');
  static registroEmpleado(Map<String, dynamic> d) => post('/registro_empleado', d);
  static updateEmpleado(int id, Map<String, dynamic> d) => put('/empleados/$id', d);
  static deleteEmpleado(int id) => delete('/empleados/$id');
  static getHabilidades() => get('/habilidades');
  static getClientes() => get('/clientes');
  static updateCliente(int id, Map<String, dynamic> d) => put('/clientes/$id', d);
  static deleteCliente(int id) => delete('/clientes/$id');
}
