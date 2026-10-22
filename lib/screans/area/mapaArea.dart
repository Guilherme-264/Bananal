import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Mapa de satélite com cantos arredondados.
/// Todas as telas que mostram mapa usam este widget.
class MapaArea extends StatefulWidget {
  /// Posição inicial do mapa (por padrão, o centro do Brasil)
  final LatLng centro;
  final double zoom;
  final double altura;

  /// Se tiver pontos aqui, a câmera ajusta para enquadrar todos eles
  /// (e ajusta de novo sempre que a lista mudar).
  final List<LatLng> pontosParaEnquadrar;

  final Set<Polygon> poligonos;
  final Set<Marker> marcadores;

  /// Chamado quando o usuário toca no mapa
  final ValueChanged<LatLng>? onTap;

  final bool controlesDeZoom;

  const MapaArea({
    super.key,
    this.centro = const LatLng(-14.235, -51.925),
    this.zoom = 4,
    this.altura = 240,
    this.pontosParaEnquadrar = const [],
    this.poligonos = const {},
    this.marcadores = const {},
    this.onTap,
    this.controlesDeZoom = false,
  });

  @override
  State<MapaArea> createState() => _MapaAreaState();
}

class _MapaAreaState extends State<MapaArea> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant MapaArea antigo) {
    super.didUpdateWidget(antigo);
    // trocou de área: leva a câmera até a nova
    if (!listEquals(antigo.pontosParaEnquadrar, widget.pontosParaEnquadrar)) {
      _enquadrar();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _enquadrar() async {
    final controller = _controller;
    final pontos = widget.pontosParaEnquadrar;
    if (controller == null || pontos.isEmpty) return;

    try {
      if (pontos.length == 1) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(pontos.first, 17),
        );
        return;
      }

      double minLat = pontos.first.latitude;
      double maxLat = pontos.first.latitude;
      double minLng = pontos.first.longitude;
      double maxLng = pontos.first.longitude;

      for (final p in pontos) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          48, // margem em pixels
        ),
      );
    } catch (_) {
      // se o mapa ainda não tiver tamanho, a câmera fica onde está
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.altura,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.centro,
            zoom: widget.zoom,
          ),
          mapType: MapType.satellite,
          polygons: widget.poligonos,
          markers: widget.marcadores,
          onTap: widget.onTap,
          onMapCreated: (controller) {
            _controller = controller;
            // espera o mapa ter tamanho antes de enquadrar a área
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _enquadrar();
            });
          },

          // controles que não combinam com o visual do app
          zoomControlsEnabled: widget.controlesDeZoom,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,

          // deixa o mapa arrastar mesmo estando dentro de uma lista que rola
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer()),
          },
        ),
      ),
    );
  }
}