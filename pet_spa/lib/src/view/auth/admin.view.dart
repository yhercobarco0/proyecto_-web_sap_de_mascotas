import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminScreen extends StatefulWidget {
  final String authToken;
  const AdminScreen({super.key, required this.authToken});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Empleados
  final _employeeFormKey = GlobalKey<FormState>();
  final TextEditingController _employeeEmailController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _employeePasswordController = TextEditingController();
  final TextEditingController _employeeSalaryController = TextEditingController();
  int? _selectedHabilidadId;
  bool _isSubmittingEmployee = false;
  String? _employeeStatusMessage;

  List<Map<String, dynamic>> empleados = [];
  List<Map<String, dynamic>> habilidades = [];
  bool isLoadingEmpleados = false;
  bool isLoadingHabilidades = false;

  // Clientes
  final _clientFormKey = GlobalKey<FormState>();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPasswordController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientAddressController = TextEditingController();
  bool _isSubmittingClient = false;
  String? _clientStatusMessage;

  List<Map<String, dynamic>> clientes = [];
  bool isLoadingClientes = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchHabilidades();
    fetchEmpleados();
    fetchClientes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _employeeEmailController.dispose();
    _employeeNameController.dispose();
    _employeePasswordController.dispose();
    _employeeSalaryController.dispose();
    _clientEmailController.dispose();
    _clientNameController.dispose();
    _clientPasswordController.dispose();
    _clientPhoneController.dispose();
    _clientAddressController.dispose();
    super.dispose();
  }

  Future<void> fetchEmpleados() async {
    setState(() => isLoadingEmpleados = true);
    final url = Uri.parse('http://localhost:3000/api/empleados');
    final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.authToken}'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() => empleados = data.map((e) => e as Map<String, dynamic>).toList());
    }
    setState(() => isLoadingEmpleados = false);
  }

  Future<void> fetchClientes() async {
    setState(() => isLoadingClientes = true);
    final url = Uri.parse('http://localhost:3000/api/clientes');
    final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.authToken}'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() => clientes = data.map((e) => e as Map<String, dynamic>).toList());
    }
    setState(() => isLoadingClientes = false);
  }

  Future<void> fetchHabilidades() async {
    setState(() => isLoadingHabilidades = true);
    final url = Uri.parse('http://localhost:3000/api/habilidades');
    final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.authToken}'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() => habilidades = data.map((e) => e as Map<String, dynamic>).toList());
    }
    setState(() => isLoadingHabilidades = false);
  }

  Future<void> _createEmployee() async {
    if (!_employeeFormKey.currentState!.validate()) return;
    setState(() {
      _isSubmittingEmployee = true;
      _employeeStatusMessage = null;
    });

    final url = Uri.parse('http://localhost:3000/api/registro_empleado');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.authToken}',
      },
      body: jsonEncode({
        'email': _employeeEmailController.text.trim(),
        'password': _employeePasswordController.text.trim(),
        'nombre': _employeeNameController.text.trim(),
        'rol': 'Personal',
        'sueldo_mensual': _employeeSalaryController.text.trim().isEmpty ? 0 : double.tryParse(_employeeSalaryController.text.trim()) ?? 0,
        'id_habilidad': _selectedHabilidadId,
      }),
    );

    setState(() => _isSubmittingEmployee = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      setState(() => _employeeStatusMessage = data['message'] ?? 'Empleado creado correctamente.');
      _employeeFormKey.currentState?.reset();
      _selectedHabilidadId = null;
      fetchEmpleados();
    } else {
      final data = jsonDecode(response.body);
      setState(() => _employeeStatusMessage = data['message'] ?? 'No se pudo crear el empleado.');
    }
  }

  Future<void> _createClient() async {
    if (!_clientFormKey.currentState!.validate()) return;
    setState(() {
      _isSubmittingClient = true;
      _clientStatusMessage = null;
    });

    final url = Uri.parse('http://localhost:3000/api/registro_cliente_admin');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.authToken}',
      },
      body: jsonEncode({
        'email': _clientEmailController.text.trim(),
        'password': _clientPasswordController.text.trim(),
        'nombre': _clientNameController.text.trim(),
        'telefono': _clientPhoneController.text.trim(),
        'direccion': _clientAddressController.text.trim(),
      }),
    );

    setState(() => _isSubmittingClient = false);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      setState(() => _clientStatusMessage = data['message'] ?? 'Cliente creado correctamente.');
      _clientFormKey.currentState?.reset();
      fetchClientes();
    } else {
      final data = jsonDecode(response.body);
      setState(() => _clientStatusMessage = data['message'] ?? 'No se pudo crear el cliente.');
    }
  }

  Future<void> _updateEmployee(int id, Map<String, dynamic> updates) async {
    final url = Uri.parse('http://localhost:3000/api/empleados/$id');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.authToken}',
      },
      body: jsonEncode(updates),
    );
    if (response.statusCode == 200) {
      fetchEmpleados();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empleado actualizado')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar')));
    }
  }

  Future<void> _deleteEmployee(int id) async {
    final url = Uri.parse('http://localhost:3000/api/empleados/$id');
    final response = await http.delete(url, headers: {'Authorization': 'Bearer ${widget.authToken}'});
    if (response.statusCode == 200) {
      fetchEmpleados();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empleado eliminado')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
    }
  }

  Future<void> _updateClient(int id, Map<String, dynamic> updates) async {
    final url = Uri.parse('http://localhost:3000/api/clientes/$id');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.authToken}',
      },
      body: jsonEncode(updates),
    );
    if (response.statusCode == 200) {
      fetchClientes();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente actualizado')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al actualizar')));
    }
  }

  Future<void> _deleteClient(int id) async {
    final url = Uri.parse('http://localhost:3000/api/clientes/$id');
    final response = await http.delete(url, headers: {'Authorization': 'Bearer ${widget.authToken}'});
    if (response.statusCode == 200) {
      fetchClientes();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente eliminado')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar')));
    }
  }

  void _showEditEmployeeDialog(Map<String, dynamic> employee) {
    final nameController = TextEditingController(text: employee['nombre']);
    final emailController = TextEditingController(text: employee['email']);
    final salaryController = TextEditingController(text: employee['sueldo_mensual']?.toString() ?? '');
    int? selectedHabilidad = employee['id_habilidad'] as int?;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Empleado'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: salaryController, decoration: const InputDecoration(labelText: 'Sueldo'), keyboardType: TextInputType.number),
              DropdownButtonFormField<int>(
                value: selectedHabilidad,
                items: habilidades.map((h) => DropdownMenuItem<int>(
                  value: h['id_habilidad'] as int,
                  child: Text(h['nombre_habilidad'] as String),
                )).toList(),
                onChanged: (value) => selectedHabilidad = value,
                decoration: const InputDecoration(labelText: 'Habilidad'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              _updateEmployee(employee['id_trabajadores'], {
                'nombre': nameController.text,
                'email': emailController.text,
                'sueldo_mensual': double.tryParse(salaryController.text) ?? 0,
                'id_habilidad': selectedHabilidad,
                'estado_trabajador': 'activo',
              });
              Navigator.pop(context);
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _showEditClientDialog(Map<String, dynamic> client) {
    final nameController = TextEditingController(text: client['nombre']);
    final emailController = TextEditingController(text: client['email']);
    final phoneController = TextEditingController(text: client['telefono']);
    final addressController = TextEditingController(text: client['direccion']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Teléfono')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Dirección')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              _updateClient(client['id_cliente'], {
                'nombre': nameController.text,
                'email': emailController.text,
                'telefono': phoneController.text,
                'direccion': addressController.text,
              });
              Navigator.pop(context);
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administrador'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Empleados'),
            Tab(text: 'Clientes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Empleados
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Crear Empleado', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Form(
                    key: _employeeFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _employeeEmailController,
                          decoration: const InputDecoration(labelText: 'Correo electrónico'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa un correo.';
                            if (!value.contains('@')) return 'Correo inválido.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _employeePasswordController,
                          decoration: const InputDecoration(labelText: 'Contraseña'),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa una contraseña.';
                            if (value.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _employeeNameController,
                          decoration: const InputDecoration(labelText: 'Nombre completo'),
                          validator: (value) => value == null || value.isEmpty ? 'Ingresa el nombre.' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _employeeSalaryController,
                          decoration: const InputDecoration(labelText: 'Sueldo mensual (opcional)'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: _selectedHabilidadId,
                          items: habilidades.map((h) => DropdownMenuItem<int>(
                            value: h['id_habilidad'] as int,
                            child: Text(h['nombre_habilidad'] as String),
                          )).toList(),
                          onChanged: (value) => setState(() => _selectedHabilidadId = value),
                          decoration: const InputDecoration(labelText: 'Habilidad'),
                        ),
                        const SizedBox(height: 24),
                        if (_employeeStatusMessage != null) ...[
                          Text(_employeeStatusMessage!, style: const TextStyle(color: Colors.black87)),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton(
                          onPressed: _isSubmittingEmployee ? null : _createEmployee,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(_isSubmittingEmployee ? 'Creando...' : 'Crear empleado'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Lista de Empleados', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (isLoadingEmpleados)
                    const CircularProgressIndicator()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: empleados.length,
                      itemBuilder: (context, index) {
                        final emp = empleados[index];
                        return Card(
                          child: ListTile(
                            title: Text(emp['nombre']),
                            subtitle: Text('${emp['email']} - ${emp['nombre_habilidad'] ?? 'Sin habilidad'}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showEditEmployeeDialog(emp),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Eliminar Empleado'),
                                      content: const Text('¿Estás seguro?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                        ElevatedButton(
                                          onPressed: () {
                                            _deleteEmployee(emp['id_trabajadores']);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          // Tab Clientes
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Crear Cliente', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Form(
                    key: _clientFormKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _clientEmailController,
                          decoration: const InputDecoration(labelText: 'Correo electrónico'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa un correo.';
                            if (!value.contains('@')) return 'Correo inválido.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _clientPasswordController,
                          decoration: const InputDecoration(labelText: 'Contraseña'),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa una contraseña.';
                            if (value.length < 8) return 'La contraseña debe tener al menos 8 caracteres.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _clientNameController,
                          decoration: const InputDecoration(labelText: 'Nombre completo'),
                          validator: (value) => value == null || value.isEmpty ? 'Ingresa el nombre.' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _clientPhoneController,
                          decoration: const InputDecoration(labelText: 'Teléfono'),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value == null || value.isEmpty ? 'Ingresa el teléfono.' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _clientAddressController,
                          decoration: const InputDecoration(labelText: 'Dirección'),
                          validator: (value) => value == null || value.isEmpty ? 'Ingresa la dirección.' : null,
                        ),
                        const SizedBox(height: 24),
                        if (_clientStatusMessage != null) ...[
                          Text(_clientStatusMessage!, style: const TextStyle(color: Colors.black87)),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton(
                          onPressed: _isSubmittingClient ? null : _createClient,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(_isSubmittingClient ? 'Creando...' : 'Crear cliente'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Lista de Clientes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (isLoadingClientes)
                    const CircularProgressIndicator()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: clientes.length,
                      itemBuilder: (context, index) {
                        final cli = clientes[index];
                        return Card(
                          child: ListTile(
                            title: Text(cli['nombre']),
                            subtitle: Text('${cli['email']} - ${cli['telefono']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showEditClientDialog(cli),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Eliminar Cliente'),
                                      content: const Text('¿Estás seguro?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                        ElevatedButton(
                                          onPressed: () {
                                            _deleteClient(cli['id_cliente']);
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
