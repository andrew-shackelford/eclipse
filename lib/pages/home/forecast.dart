import 'package:eclipse/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../objects/location.dart';
import '../../components/map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ForecastPage extends StatefulWidget {
  const ForecastPage({Key? key}) : super(key: key);

  @override
  _ForecastPageState createState() => _ForecastPageState();
}

Future<List<String>> get forecastUrls async {
  var eclipse = mockEclipseTime;

  var utcForecast = DateTime.now().toUtc();
  if (utcForecast.hour >= 18) {
    utcForecast = utcForecast.copyWith(hour: 18);
  } else if (utcForecast.hour >= 12) {
    utcForecast = utcForecast.copyWith(hour: 12);
  } else if (utcForecast.hour >= 6) {
    utcForecast = utcForecast.copyWith(hour: 6);
  } else {
    utcForecast = utcForecast.copyWith(hour: 0);
  }

  final hours = eclipse.toUtc().difference(utcForecast).inHours;

  List<String> urls = [];
  final formatter = DateFormat('yyyyMMddHH');
  final utcForecastStr = formatter.format(utcForecast);
  final oldUtcForecastStr =
      formatter.format(utcForecast.subtract(const Duration(hours: 6)));
  for (var i = hours; i < hours + 6; i++) {
    final hourStr = i.toString().padLeft(3, '0');
    final oldHoursStr = (i + 6).toString().padLeft(3, '0');

    final currentUrl =
        'https://weather.gc.ca/data/prog/regional/${utcForecastStr}/${utcForecastStr}_054_R1_north@america@northeast_I_ASTRO_nt_${hourStr}.png';
    final pastUrl =
        'https://weather.gc.ca/data/prog/regional/${oldUtcForecastStr}/${oldUtcForecastStr}_054_R1_north@america@northeast_I_ASTRO_nt_${oldHoursStr}.png';

    final response = await fetchWithoutCors(currentUrl);
    if (response.statusCode == 200) {
      urls.add(currentUrl);
    } else {
      urls.add(pastUrl);
    }
  }

  return urls;
}

class _ForecastPageState extends State<ForecastPage> {
  List<String> urls = [];
  Set<Polyline> polylines = Set.identity();
  Set<Marker> cloudCoverMarkers = Set.identity();
  Set<Marker> ecmwfCloudMarkers = Set.identity();
  Set<Marker> cloudCoverMarkers4PM = Set.identity();
  Set<Marker> ecmwfCloudMarkers4PM = Set.identity();

  @override
  void initState() {
    super.initState();
    forecastUrls.then((value) => setState(() {
          urls = value;
        }));
    getEclipseLines().then((value) => setState(() {
          polylines = value;
        }));
    final cloudCoverMarkerFutures =
        locations.values.map((e) => e.cloudCoverMarker).toList();
    Future.wait(cloudCoverMarkerFutures).then((value) => setState(() {
          cloudCoverMarkers = value.toSet();
        }));
    final ecmwfCloudMarkerFutures =
        locations.values.map((e) => e.ecmwfCloudMarker).toList();
    Future.wait(ecmwfCloudMarkerFutures).then((value) => setState(() {
          ecmwfCloudMarkers = value.toSet();
        }));
    final cloudCoverMarker4PMFutures =
        locations.values.map((e) => e.cloudCoverMarker4PM).toList();
    Future.wait(cloudCoverMarker4PMFutures).then((value) => setState(() {
          cloudCoverMarkers4PM = value.toSet();
        }));
    final ecmwfCloudMarker4PMFutures =
        locations.values.map((e) => e.ecmwfCloudMarker4PM).toList();
    Future.wait(ecmwfCloudMarker4PMFutures).then((value) => setState(() {
          ecmwfCloudMarkers4PM = value.toSet();
        }));
  }

  Set<Marker> get selectedMarkers {
    if (selectedModel[0]) {
      if (selectedTime[0]) {
        return cloudCoverMarkers;
      } else {
        return cloudCoverMarkers4PM;
      }
    } else {
      if (selectedTime[0]) {
        return ecmwfCloudMarkers;
      } else {
        return ecmwfCloudMarkers4PM;
      }
    }
  }

  var selectedModel = [true, false];
  var selectedTime = [true, false];

  @override
  Widget build(BuildContext context) {
    return Container(
        child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Cloud cover forecast:'),
          const Text('Dark blue is GOOD/clear. Grey/White is BAD/cloudy.'),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('model type: '),
            ToggleButtons(
              isSelected: selectedModel,
              children: const [Text('Cloud Cover'), Text('ECMWF Cloud')],
              onPressed: (index) {
                setState(() {
                  selectedModel = [index == 0, index == 1];
                });
              },
            ),
            const SizedBox(width: 25),
            ToggleButtons(
              isSelected: selectedTime,
              children: const [Text('3 PM'), Text('4 PM')],
              onPressed: (index) {
                setState(() {
                  selectedTime = [index == 0, index == 1];
                });
              },
            )
          ]),
          const SizedBox(height: 10),
          GoogleMapWidget(
            markers: selectedMarkers,
            polylines: polylines,
            location: locations['plattsburgh']!,
            showCurrentLocation: true,
            showWeatherStationLocation: false,
          ),
          const SizedBox(height: 50),
          Text(zuluString),
          const Text('The eclipse is from 1915Z to 1930Z'),
          const Text('You can pinch and zoom on the images.'),
          ...urls.map(
              (e) => InteractiveViewer(maxScale: 5, child: Image.network((e))))
        ],
      ),
    ));
  }
}
