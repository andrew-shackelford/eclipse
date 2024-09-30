import 'dart:async';
import 'package:flutter/material.dart';
import '../../objects/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:geolocator/geolocator.dart';

import 'dart:ui' as ui;

class GoogleMapWidget extends StatefulWidget {
  Set<Marker> markers;
  Location location;
  GoogleMapController? controller;
  bool showCurrentLocation;
  bool showWeatherStationLocation;
  Set<Polyline> polylines;

  GoogleMapWidget(
      {super.key,
      this.markers = const <Marker>{},
      this.polylines = const <Polyline>{},
      required this.location,
      this.showCurrentLocation = false,
      this.showWeatherStationLocation = true});

  @override
  _GoogleMapWidgetState createState() => _GoogleMapWidgetState();

  void updateMapLocation() {
    controller?.animateCamera(
        CameraUpdate.newLatLng(LatLng(location.lat, location.long)));
  }
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  Marker? currentLocation;
  Marker? weatherStationLocation;

  Set<Marker> get getMarkersWithCurrentLocation {
    var newMarkers = widget.markers;
    if (widget.showCurrentLocation && currentLocation != null) {
      newMarkers = newMarkers.union({
        currentLocation!,
      });
    }
    if (widget.showWeatherStationLocation && weatherStationLocation != null) {
      newMarkers = newMarkers.union({weatherStationLocation!});
    }
    return newMarkers;
  }

  @override
  void initState() {
    super.initState();
    getWeatherStationLocation();
    if (widget.showCurrentLocation) {
      getCurrentLocation();
    }
  }

  void getWeatherStationLocation() async {
    final markerBitmap =
        await createCustomMarkerWithHue(BitmapDescriptor.hueGreen);

    setState(() {
      weatherStationLocation = Marker(
          markerId: MarkerId(widget.location.name),
          position: LatLng(widget.location.lat, widget.location.long),
          infoWindow: InfoWindow(
            title: '${widget.location.displayName} Weather Station',
          ),
          icon: markerBitmap);
    });
    widget.updateMapLocation();
  }

  void getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final markerBitmap =
        await createCustomMarkerWithHue(BitmapDescriptor.hueAzure);

    setState(() {
      currentLocation = Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(
            title: 'Current Location',
          ),
          icon: markerBitmap);
    });
  }

  @override
  void didUpdateWidget(GoogleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller ??= oldWidget.controller;
    if (widget.location != oldWidget.location) {
      widget.updateMapLocation();
      getWeatherStationLocation();
    }
    if (widget.showCurrentLocation && !oldWidget.showCurrentLocation) {
      getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(widget.location.lat,
              widget.location.long), // Set the initial map center
          zoom: 10,
        ),
        onMapCreated: (controller) {
          widget.controller = controller;
        },
        markers: getMarkersWithCurrentLocation,
        polylines: widget.polylines,
      ),
    );
  }
}

Future<Set<Marker>> getViewingLocations() async {
  const url =
      'https://www.google.com/maps/d/kml?forcekml=1&mid=1iOy0QAcifkMBqyuvncVQxvWaomQ9E58';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final kmlData = response.body;
    final kml = xml.XmlDocument.parse(kmlData);
    final placemarks = kml.findAllElements('Placemark');

    return placemarks
        .where((placemark) =>
            placemark
                .findAllElements('coordinates')
                .first
                .text
                .split("\n")
                .length <
            5)
        .map((placemark) {
      final name = placemark.findElements('name').first.text;
      final coordinates =
          placemark.findAllElements('coordinates').first.text.split(',');
      final latitude = double.parse(coordinates[1]);
      final longitude = double.parse(coordinates[0]);

      return Marker(
        markerId: MarkerId(name),
        position: LatLng(latitude, longitude),
        infoWindow: InfoWindow(
          title: name,
          snippet: 'Lat: $latitude\nLong: $longitude',
        ),
      );
    }).toSet();
  } else {
    return Set.identity();
  }
}

Future<Set<Polyline>> getEclipseLines() async {
  const url =
      'https://www.google.com/maps/d/kml?forcekml=1&mid=1iOy0QAcifkMBqyuvncVQxvWaomQ9E58';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final kmlData = response.body;
    final kml = xml.XmlDocument.parse(kmlData);
    final placemarks = kml.findAllElements('Placemark');

    return placemarks
        .where((placemark) =>
            placemark
                .findAllElements('coordinates')
                .first
                .text
                .split("\n")
                .length >
            5)
        .map((placemark) {
      final name = placemark.findElements('name').first.text;
      final coordinates = placemark
          .findAllElements('coordinates')
          .first
          .text
          .split("\n")
          .where((element) => element.contains(','))
          .map((e) => LatLng(
              double.parse(e.split(",")[1]), double.parse(e.split(",")[0])));

      return Polyline(
          polylineId: PolylineId(name),
          points: coordinates.toList(),
          width: 4,
          color: Colors.pink);
    }).toSet();
  } else {
    return Set.identity();
  }
}

Future<BitmapDescriptor> createCustomMarkerWithHue(double hue) async {
  const size = Size(24, 24);
  final circleRadius = size.width / 5;
  final circleOffset = Offset(size.width / 3.5, size.height / 3);
  final pinWidth = size.width / 2;
  final pinHeight = size.height * 0.7;

  final pictureRecorder = ui.PictureRecorder();
  final canvas = ui.Canvas(pictureRecorder);

  final fillPaint = ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..color = HSLColor.fromAHSL(1, hue, 1, 0.5).toColor();

  final strokePaint = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..color = Colors.black;

  final pinPath = ui.Path()
    ..moveTo(size.width / 2, size.height)
    ..lineTo(0, size.height - pinHeight)
    ..arcToPoint(Offset(pinWidth, size.height - pinHeight),
        radius: const Radius.circular(1), clockwise: false)
    ..lineTo(size.width / 2, 0)
    ..close();

  canvas.drawPath(pinPath, fillPaint);
  canvas.drawPath(pinPath, strokePaint);
  canvas.drawCircle(
      circleOffset, circleRadius, ui.Paint()..color = Colors.white);
  canvas.drawCircle(circleOffset, circleRadius, strokePaint);

  final picture = pictureRecorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}
