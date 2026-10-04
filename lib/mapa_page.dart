import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final MapController mapaController = MapController();

  static const String urlApi =
      'http://127.0.0.1:3000/rutas';

  List<dynamic> rutas = [];

  bool cargando = true;
  String? error;

  int rutaSeleccionada = 0;

  // Coordenadas de los puntos de las rutas.
  // Más adelante podremos guardar estas coordenadas
  // directamente en la base de datos.

  final Map<String, LatLng> ubicaciones = {
    'Terminal': const LatLng(
      -2.19616,
      -79.88621,
    ),

    'Universidad': const LatLng(
      -2.14570,
      -79.96470,
    ),

    'Hospital': const LatLng(
      -2.17150,
      -79.90550,
    ),

    'Centro': const LatLng(
      -2.18940,
      -79.88900,
    ),

    'Mercado': const LatLng(
      -2.19050,
      -79.88750,
    ),

    'Parque': const LatLng(
      -2.17800,
      -79.89200,
    ),
  };

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
          .timeout(
            const Duration(seconds: 10),
          );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(
          respuesta.body,
        );

        setState(() {
          rutas = datos;
          cargando = false;

          if (rutas.isEmpty) {
            rutaSeleccionada = 0;
          } else if (rutaSeleccionada >= rutas.length) {
            rutaSeleccionada = 0;
          }
        });

        if (rutas.isNotEmpty) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            centrarRuta(0);
          });
        }
      } else {
        setState(() {
          error =
              'Error del servidor: '
              '${respuesta.statusCode}';

          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        error =
            'No se pudo conectar con el servidor.\n\n'
            'Verifica que EcoRuta Backend esté '
            'ejecutándose en el puerto 3000.';

        cargando = false;
      });
    }
  }

  LatLng? obtenerCoordenada(
    String nombre,
  ) {
    final nombreNormalizado =
        nombre.trim();

    return ubicaciones[
        nombreNormalizado];
  }

  List<LatLng> coordenadasRuta(
    dynamic ruta,
  ) {
    final origen =
        ruta['origen'].toString();

    final destino =
        ruta['destino'].toString();

    final puntoOrigen =
        obtenerCoordenada(origen);

    final puntoDestino =
        obtenerCoordenada(destino);

    if (puntoOrigen == null ||
        puntoDestino == null) {
      return [];
    }

    return [
      puntoOrigen,
      puntoDestino,
    ];
  }

  void seleccionarRuta(int indice) {
    if (indice < 0 ||
        indice >= rutas.length) {
      return;
    }

    setState(() {
      rutaSeleccionada = indice;
    });

    centrarRuta(indice);
  }

  void centrarRuta(int indice) {
    if (rutas.isEmpty ||
        indice >= rutas.length) {
      return;
    }

    final puntos =
        coordenadasRuta(
      rutas[indice],
    );

    if (puntos.length == 2) {
      final latitud =
          (puntos[0].latitude +
                  puntos[1].latitude) /
              2;

      final longitud =
          (puntos[0].longitude +
                  puntos[1].longitude) /
              2;

      mapaController.move(
        LatLng(
          latitud,
          longitud,
        ),
        12.5,
      );
    }
  }

  Color colorRuta(dynamic ruta) {
    final estado =
        ruta['estado']
            .toString()
            .toUpperCase();

    if (estado == 'ACTIVA') {
      return Colors.green;
    }

    return Colors.red;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.map),
            SizedBox(width: 10),
            Text(
              'Mapa de EcoRuta',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),

        backgroundColor:
            Colors.green,

        foregroundColor:
            Colors.white,

        actions: [
          IconButton(
            onPressed: obtenerRutas,
            icon: const Icon(
              Icons.refresh,
            ),
            tooltip:
                'Actualizar rutas',
          ),
        ],
      ),

      body: Stack(
        children: [
          FlutterMap(
            mapController:
                mapaController,

            options: const MapOptions(
              initialCenter: LatLng(
                -2.170998,
                -79.922359,
              ),

              initialZoom: 12,

              minZoom: 5,

              maxZoom: 18,
            ),

            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                userAgentPackageName:
                    'com.example.ecoruta',
              ),

              if (!cargando &&
                  rutas.isNotEmpty)
                PolylineLayer(
                  polylines:
                      _crearLineas(),
                ),

              if (!cargando &&
                  rutas.isNotEmpty)
                MarkerLayer(
                  markers:
                      _crearMarcadores(),
                ),
            ],
          ),

          if (cargando)
            const Center(
              child:
                  CircularProgressIndicator(),
            ),

          if (error != null &&
              !cargando)
            Center(
              child: Card(
                margin:
                    const EdgeInsets.all(
                  25,
                ),

                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    25,
                  ),

                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [
                      const Icon(
                        Icons.cloud_off,
                        size: 60,
                        color: Colors.red,
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      const Text(
                        'Error de conexión',
                        style:
                            TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        error!,
                        textAlign:
                            TextAlign.center,
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      ElevatedButton.icon(
                        onPressed:
                            obtenerRutas,

                        icon:
                            const Icon(
                          Icons.refresh,
                        ),

                        label:
                            const Text(
                          'Reintentar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!cargando &&
              error == null &&
              rutas.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child:
                  _panelRutas(),
            ),

          if (!cargando &&
              error == null &&
              rutas.isEmpty)
            const Center(
              child: Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(20),

                  child: Text(
                    'No existen rutas registradas.',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Polyline> _crearLineas() {
    final List<Polyline> lineas = [];

    for (int i = 0;
        i < rutas.length;
        i++) {
      final puntos =
          coordenadasRuta(
        rutas[i],
      );

      if (puntos.length == 2) {
        lineas.add(
          Polyline(
            points: puntos,

            strokeWidth:
                i == rutaSeleccionada
                    ? 7
                    : 4,

            color:
                colorRuta(
              rutas[i],
            ),

            pattern:
                const StrokePattern
                    .solid(),
          ),
        );
      }
    }

    return lineas;
  }

  List<Marker> _crearMarcadores() {
    final List<Marker> marcadores = [];

    for (int i = 0;
        i < rutas.length;
        i++) {
      final ruta = rutas[i];

      final puntos =
          coordenadasRuta(
        ruta,
      );

      if (puntos.length != 2) {
        continue;
      }

      final color =
          colorRuta(ruta);

      final bool seleccionada =
          i == rutaSeleccionada;

      marcadores.add(
        Marker(
          point: puntos[0],

          width: 100,

          height: 90,

          child: GestureDetector(
            onTap: () {
              seleccionarRuta(i);
            },

            child: Column(
              children: [
                Icon(
                  Icons.trip_origin,
                  color: color,
                  size:
                      seleccionada
                          ? 38
                          : 30,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),

                  color:
                      Colors.white,

                  child: Text(
                    ruta['origen']
                        .toString(),

                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      marcadores.add(
        Marker(
          point: puntos[1],

          width: 100,

          height: 90,

          child: GestureDetector(
            onTap: () {
              seleccionarRuta(i);
            },

            child: Column(
              children: [
                Icon(
                  Icons.location_on,
                  color: color,
                  size:
                      seleccionada
                          ? 42
                          : 34,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),

                  color:
                      Colors.white,

                  child: Text(
                    ruta['destino']
                        .toString(),

                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return marcadores;
  }

  Widget _panelRutas() {
    final ruta =
        rutas[rutaSeleccionada];

    final activa =
        ruta['estado']
                .toString()
                .toUpperCase() ==
            'ACTIVA';

    final color =
        activa
            ? Colors.green
            : Colors.red;

    return Card(
      elevation: 8,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(
          15,
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      color,

                  child: const Icon(
                    Icons.directions_bus,
                    color:
                        Colors.white,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        ruta['nombre_ruta']
                            .toString(),

                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        '${ruta['origen']} → ${ruta['destino']}',

                        style:
                            const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),

                  decoration:
                      BoxDecoration(
                    color: color
                        .withValues(
                      alpha: 0.15,
                    ),

                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),

                  child: Text(
                    activa
                        ? 'ACTIVA'
                        : 'INACTIVA',

                    style:
                        TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 20,
                  color:
                      Colors.orange,
                ),

                const SizedBox(
                  width: 7,
                ),

                Text(
                  '${ruta['tiempo_estimado']} minutos',

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const Spacer(),

                Text(
                  '${rutaSeleccionada + 1}/${rutas.length}',

                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            SizedBox(
              height: 45,

              child: ListView.builder(
                scrollDirection:
                    Axis.horizontal,

                itemCount:
                    rutas.length,

                itemBuilder:
                    (context, index) {
                  final rutaItem =
                      rutas[index];

                  final seleccionada =
                      index ==
                          rutaSeleccionada;

                  return Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      right: 8,
                    ),

                    child:
                        ChoiceChip(
                      selected:
                          seleccionada,

                      label: Text(
                        rutaItem[
                                'nombre_ruta']
                            .toString(),
                      ),

                      onSelected:
                          (_) {
                        seleccionarRuta(
                          index,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}