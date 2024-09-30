import 'package:eclipse/components/map.dart';
import 'package:eclipse/utils.dart';
import 'package:flutter/material.dart';
import '../../components/link.dart';
import '../../objects/location.dart';
import 'package:image/image.dart' as img;
import 'package:collection/collection.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPage extends StatefulWidget {
  Location? location;
  Set<Marker> markers = Set.identity();
  Set<Polyline> polylines = Set.identity();
  img.Image? forecastImage;
  List<DateTime> eclipseTimes = [];
  Duration eclipseDuration = Duration.zero;

  LocationPage({super.key, this.location});

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  @override
  void initState() {
    super.initState();
    getViewingLocations().then((value) => setState(() {
          widget.markers = value;
        }));
    getEclipseLines().then((value) => setState(() {
          widget.polylines = value;
        }));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        child: SingleChildScrollView(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownMenu(
              dropdownMenuEntries: locations.entries
                  .map((e) => DropdownMenuEntry(
                      value: e.value.name, label: e.value.displayName))
                  .toList(),
              onSelected: (value) {
                setState(() {
                  widget.location = locations[value];
                  widget.location?.getForecastImage().then((value) {
                    setState(() {
                      widget.forecastImage = value;
                    });
                  });
                  widget.location?.fetchEclipseData().then((value) {
                    setState(() {
                      widget.eclipseTimes = value.key;
                      widget.eclipseDuration = value.value;
                    });
                  });
                });
              },
            ),
            if (widget.location != null)
              ...locationInfo(context, widget.location!)
          ]),
    ));
  }

  List<Widget> locationInfo(BuildContext context, Location location) {
    return [
      ClickableLink(
          text: location.displayName,
          url: location.pageUrl,
          style: const TextStyle(fontSize: 24)),
      ...widget.eclipseTimes.mapIndexed((index, element) =>
          Text(eclipseStringForIndex(index) + formatEclipseTime(element))),
      if (widget.eclipseDuration.inSeconds > 1)
        Text(
            'Eclipse duration: ${widget.eclipseDuration.inMinutes}m:${widget.eclipseDuration.inSeconds.remainder(60)}sec'),
      ClickableLink(text: 'Google Maps', url: location.googleMapsLink),
      const Text('Dark blue is GOOD/clear. Grey/White is BAD/cloudy.'),
      if (widget.forecastImage != null) widget.forecastImage!.croppedNameImage,
      if (widget.forecastImage != null)
        widget.forecastImage!.croppedForecastImage,
      const Text(
          'Red: Viewing locations\nBlue: Current locations\nGreen: Weather station'),
      GoogleMapWidget(
        markers: widget.markers,
        polylines: widget.polylines,
        location: location,
        showCurrentLocation: true,
      ),
    ];
  }
}
