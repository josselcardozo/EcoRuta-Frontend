import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'mapa_page.dart';

void main() {
  runApp(const EcoRutaApp());
}

class EcoRutaApp extends StatelessWidget {
  const EcoRutaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoRuta',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
      ),
      home: const InicioPage(),
    );
  }
}

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  List<dynamic> rutas = [];
  List<dynamic> rutasFiltradas = [];

  bool cargando = true;
  String? error;
  String textoBusqueda = '';

  static const String urlApi =
      'http://127.0.0.1:3000/rutas';

  @override
  void initState() {
    super.initState();
    obtenerRutas();
  }

  Future<void> obtenerRutas() async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final respuesta = await http
          .get(Uri.parse(urlApi))
          .timeout(const Duration(seconds: 10));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);

        setState(() {
          rutas = datos;
          rutasFiltradas = datos;
          cargando = false;
        });
      } else {
        setState(() {
          error =
              'Error del servidor: ${respuesta.statusCode}';
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        error =
            'No se pudo conectar con el servidor.\n\n'
            'Verifica que EcoRuta Backend esté ejecutándose '
            'en el puerto 3000.';
        cargando = false;
      });
    }
  }

  void buscarRuta(String texto) {
    setState(() {
      textoBusqueda = texto.toLowerCase().trim();

      rutasFiltradas = rutas.where((ruta) {
        final nombre =
            ruta['nombre_ruta'].toString().toLowerCase();

        final origen =
            ruta['origen'].toString().toLowerCase();

        final destino =
            ruta['destino'].toString().toLowerCase();

        return nombre.contains(textoBusqueda) ||
            origen.contains(textoBusqueda) ||
            destino.contains(textoBusqueda);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),

      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,

        title: const Row(
          children: [
            Icon(Icons.directions_bus),
            SizedBox(width: 10),
            Text(
              'EcoRuta',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: obtenerRutas,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar rutas',
          ),
        ],
      ),

      body: cargando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? _mostrarError()
              : _mostrarContenido(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,

        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MapaPage(),
              ),
            );
          }

          if (index == 2) {
            _mostrarInformacion();
          }
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Información',
          ),
        ],
      ),
    );
  }

  Widget _mostrarContenido() {
    return RefreshIndicator(
      onRefresh: obtenerRutas,

      child: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Container(
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),

            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  '¡Bienvenido a EcoRuta! 🚌',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'Encuentra rutas de transporte público de manera rápida y sencilla.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            onChanged: buscarRuta,

            decoration: InputDecoration(
              hintText:
                  'Buscar ruta, origen o destino...',

              prefixIcon:
                  const Icon(Icons.search),

              suffixIcon:
                  textoBusqueda.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            buscarRuta('');
                          },
                          icon:
                              const Icon(Icons.clear),
                        )
                      : null,

              filled: true,
              fillColor: Colors.white,

              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Rutas disponibles',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (rutasFiltradas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No se encontraron rutas.',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          else
            ...rutasFiltradas.map(
              (ruta) => _tarjetaRuta(ruta),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaRuta(dynamic ruta) {
    final bool activa =
        ruta['estado']
                .toString()
                .toUpperCase() ==
            'ACTIVA';

    return Card(
      margin:
          const EdgeInsets.only(bottom: 15),

      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color:
                        Colors.green.shade100,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),

                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.green,
                    size: 28,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    ruta['nombre_ruta']
                        .toString(),

                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration:
                      BoxDecoration(
                    color: activa
                        ? Colors.green.shade100
                        : Colors.red.shade100,

                    borderRadius:
                        BorderRadius.circular(20),
                  ),

                  child: Text(
                    activa
                        ? 'ACTIVA'
                        : 'INACTIVA',

                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,

                      color: activa
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                const Icon(
                  Icons.trip_origin,
                  size: 20,
                  color: Colors.blue,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Origen: ${ruta['origen']}',
                    style:
                        const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding:
                  const EdgeInsets.only(
                left: 9,
              ),

              child: Container(
                height: 18,
                width: 2,
                color:
                    Colors.grey.shade300,
              ),
            ),

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 20,
                  color: Colors.red,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Destino: ${ruta['destino']}',
                    style:
                        const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            const Divider(),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 20,
                  color: Colors.orange,
                ),

                const SizedBox(width: 8),

                Text(
                  '${ruta['tiempo_estimado']} minutos',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const Spacer(),

                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MapaPage(),
                      ),
                    );
                  },

                  icon: const Icon(
                    Icons.directions,
                    color: Colors.green,
                  ),

                  label: const Text(
                    'Ver ruta',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mostrarError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.cloud_off,
              size: 70,
              color: Colors.red,
            ),

            const SizedBox(height: 20),

            const Text(
              'No se pudo conectar con EcoRuta',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              error ?? 'Error desconocido',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: obtenerRutas,

              icon:
                  const Icon(Icons.refresh),

              label:
                  const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarInformacion() {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.info,
                color: Colors.green,
              ),

              SizedBox(width: 10),

              Text('EcoRuta'),
            ],
          ),

          content: const Text(
            'EcoRuta es una aplicación móvil '
            'diseñada para facilitar la consulta '
            'de rutas de transporte público.\n\n'
            'Permite consultar rutas, conocer su '
            'origen, destino, tiempo estimado y '
            'visualizar información geográfica.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child:
                  const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
}