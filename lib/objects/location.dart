import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';
import '../../utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:html/dom.dart';
import 'package:collection/collection.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:pair/pair.dart';

class Location {
  final String name;
  final String displayName;
  final String clearSkyId;
  final double lat;
  final double long;
  Future<img.Image>? forecastImage;
  Future<int>? indexOfDayChange;
  Future<List<DateTime>>? eclipseTimes;
  Future<Duration>? eclipseDuration;

  Location(this.name, this.displayName, this.clearSkyId, this.lat, this.long);

  String get pageUrl {
    return 'https://www.cleardarksky.com/c/${clearSkyId}key.html';
  }

  String get forecastImageUrl {
    final now = DateTime.now();
    var cacheBuster = '${now.millisecondsSinceEpoch ~/ (1000 * 60 * 5)}';
    return 'https://www.cleardarksky.com/c/${clearSkyId}csk.gif?c=$cacheBuster';
  }

  DateTime getEclipseTimeAtIndex(Document document, int index) {
    return parseEclipseTime(document
            .getElementsByTagName('table')
            .elementAtOrNull(1)
            ?.getElementsByTagName('tr')
            .elementAtOrNull(index)
            ?.getElementsByTagName('td')
            .elementAtOrNull(2)
            ?.innerHtml ??
        '0:00:00.0');
  }

  String get googleMapsLink {
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$long';
  }

  Future<Pair<List<DateTime>, Duration>> fetchEclipseData() async {
    eclipseTimes ??= fetchWithoutCors(
            'https://aa.usno.navy.mil/calculated/eclipse/solar?eclipse=12024&lat=${lat}&lon=${long}&label=&height=0&submit=Get+Data')
        .then((value) => parse(value.body))
        .then((value) => [
              getEclipseTimeAtIndex(value, 2),
              getEclipseTimeAtIndex(value, 3),
              getEclipseTimeAtIndex(value, 5),
              getEclipseTimeAtIndex(value, 6)
            ]);
    eclipseDuration ??=
        eclipseTimes!.then((value) => value[2].difference(value[1]));
    return Pair(await eclipseTimes!, await eclipseDuration!);
  }

  Future<img.Image> getForecastImage() {
    forecastImage ??= fetchWithoutCors(forecastImageUrl)
        .then((value) => value.bodyBytes)
        .then((value) => img.decodeImage(value)!);
    return forecastImage!;
  }

  Future<int> getIndexOfDayChange() async {
    indexOfDayChange ??= getForecastImage().then((value) {
      final images = [for (var i = 0; i <= 30; i++) i]
          .map((e) => value.bottomTimePicture(e))
          .toList();
      final results = detectColorChanges(images, 1);
      final index = results[1];
      // handle midnight
      return index >= 24 ? 0 : index;
    });
    return indexOfDayChange!;
  }

  Future<int> indexAtDateTime(DateTime datetime) async {
    final index = await getIndexOfDayChange();
    final now = DateTime.now();
    var indexChangeDate = DateTime(2024, now.month, now.day + 1);

    if (now.hour < 12 && index < 12) {
      // It's already tomorrow, but image hasn't updated.
      indexChangeDate = DateTime(2024, 4, now.month, now.day);
    }

    final imageStartDate = indexChangeDate.subtract(Duration(hours: index));
    final hourDiff = datetime.difference(imageStartDate).inHours;
    return hourDiff;
  }

  Future<img.Image> cloudCoverImageAtDateTime(DateTime datetime) async {
    final index = await indexAtDateTime(datetime);
    final image = await getForecastImage();
    return image.cloudCoverPicture(index);
  }

  Future<img.Image> ecmwfCloudImageAtDateTime(DateTime datetime) async {
    final index = await indexAtDateTime(datetime);
    final image = await getForecastImage();
    return image.ecmwfCloudPicture(index);
  }

  Future<Marker> get cloudCoverMarker async {
    final cloudCoverImage = await cloudCoverImageAtDateTime(mockEclipseTime);
    return marker(cloudCoverImage);
  }

  Future<Marker> get ecmwfCloudMarker async {
    final ecmwfCloudImage = await ecmwfCloudImageAtDateTime(mockEclipseTime);
    return marker(ecmwfCloudImage);
  }

  Future<Marker> get cloudCoverMarker4PM async {
    final cloudCoverImage = await cloudCoverImageAtDateTime(mockEclipseTime4PM);
    return marker(cloudCoverImage);
  }

  Future<Marker> get ecmwfCloudMarker4PM async {
    final ecmwfCloudImage = await ecmwfCloudImageAtDateTime(mockEclipseTime4PM);
    return marker(ecmwfCloudImage);
  }

  Future<Marker> marker(img.Image inputImage) async {
    /*
    final snippet = await fetchEclipseData().then((value) =>
        value.key
            .skip(1)
            .take(2)
            .mapIndexed((index, element) =>
                shortEclipseStringForIndex(index + 1) +
                formatEclipseTime(element))
            .join("\n") +
        '\nDuration: ${value.value.inMinutes}m:${value.value.inSeconds.remainder(60)}sec');
        */
    final icon = BitmapDescriptor.fromBytes(
        img.encodePng(inputImage.scaleAndAddBorder(2, 2)));
    return Marker(
        markerId: MarkerId(name),
        position: LatLng(lat, long),
        infoWindow: InfoWindow(
          title: '$displayName Weather Station',
          // snippet: snippet,
          onTap: () => launchUrl(Uri.parse(googleMapsLink)),
        ),
        icon: icon);
  }
}

final locationJson = [
  {
    "key": "EriePA",
    "name": "erie",
    "displayName": "Erie, PA",
    "latitude": 42.129,
    "longitude": -80.085
  },
  {
    "key": "FrdnObNY",
    "name": "fredonia",
    "displayName": "Fredonia, NY",
    "latitude": 42.449354,
    "longitude": -79.336103
  },
  {
    "key": "AnglBsObFL",
    "name": "kitters",
    "displayName": "Kitters Angola, NY",
    "latitude": 42.645739,
    "longitude": -79.029581
  },
  {
    "key": "BuffaloNY",
    "name": "buffalo",
    "displayName": "Buffalo, NY",
    "latitude": 42.886,
    "longitude": -78.879
  },
  {
    "key": "MshlHObNY",
    "name": "marshall",
    "displayName": "Marshall Hill, NY",
    "latitude": 43.2559,
    "longitude": -78.4188
  },
  {
    "key": "MdbryOBNY",
    "name": "middlebury",
    "displayName": "Middlebury, NY",
    "latitude": 42.849275,
    "longitude": -78.079275
  },
  {
    "key": "BrkprtStObNY",
    "name": "brockport",
    "displayName": "Brockport, NY",
    "latitude": 43.2052,
    "longitude": -77.9664
  },
  {
    "key": "RchstrHY",
    "name": "rochester",
    "displayName": "Rochester, NY",
    "latitude": 43.155,
    "longitude": -77.616
  },
  {
    "key": "LynsNY",
    "name": "lyons",
    "displayName": "Lyons, NY",
    "latitude": 43.0642,
    "longitude": -76.9902
  },
  {
    "key": "FrHvnCyNY",
    "name": "fair",
    "displayName": "Fair Haven, NY",
    "latitude": 43.316,
    "longitude": -76.703
  },
  {
    "key": "WtrtwnNY",
    "name": "watertown",
    "displayName": "Watertown, NY",
    "latitude": 43.975,
    "longitude": -75.911
  },
  {
    "key": "MllstLkNY",
    "name": "millsite",
    "displayName": "Millsite Lake, NY",
    "latitude": 44.2913,
    "longitude": -75.77855
  },
  {
    "key": "LwCtFgNY",
    "name": "lewis",
    "displayName": "Lewis County, NY",
    "latitude": 43.798041,
    "longitude": -75.489748
  },
  {
    "key": "HwlttObNY",
    "name": "hewlett",
    "displayName": "Hewlett, NY",
    "latitude": 44.563567,
    "longitude": -75.248267
  },
  {
    "key": "PtsdmNY",
    "name": "potsdam",
    "displayName": "Potsdam, NY",
    "latitude": 44.669840,
    "longitude": -74.986985
  },
  {
    "key": "OldFrgNY",
    "name": "forge",
    "displayName": "Old Forge, NY",
    "latitude": 43.71,
    "longitude": -74.975
  },
  {
    "key": "TlyPndNY",
    "name": "tooley",
    "displayName": "Tooley Pond, NY",
    "latitude": 44.2709,
    "longitude": -74.9188
  },
  {
    "key": "LngLkNY",
    "name": "long",
    "displayName": "Long Lake, NY",
    "latitude": 43.982222,
    "longitude": -74.451389
  },
  {
    "key": "TtsLkObNY",
    "name": "titus",
    "displayName": "Lake Titus, NY",
    "latitude": 44.725,
    "longitude": -74.287778
  },
  {
    "key": "SrncLkObNY",
    "name": "saranac",
    "displayName": "Saranac Lake, NY",
    "latitude": 44.33,
    "longitude": -74.13
  },
  {
    "key": "AltnObNY",
    "name": "altona",
    "displayName": "Altona, NY",
    "latitude": 44.861679,
    "longitude": -73.707533
  },
  {
    "key": "ASblFrkNY",
    "name": "sable",
    "displayName": "Au Sable Forks, NY",
    "latitude": 44.443333,
    "longitude": -73.675556
  },
  {
    "key": "PlttsbrgNY",
    "name": "plattsburgh",
    "displayName": "Plattsburgh, NY",
    "latitude": 44.699,
    "longitude": -73.453
  },
  {
    "key": "BrlngtnVT",
    "name": "burlington",
    "displayName": "Burlington, VT",
    "latitude": 44.476,
    "longitude": -73.213
  },
  {
    "key": "RgJchQC",
    "name": "joachim",
    "displayName": "Rang St-Joachim, CA",
    "latitude": 45.24054,
    "longitude": -73.16045
  },
  {
    "key": "StAbnsVT",
    "name": "albans",
    "displayName": "St Albans, VT",
    "latitude": 44.810515,
    "longitude": -73.083337
  },
  {
    "key": "3HrnObVT",
    "name": "herons",
    "displayName": "3 Herons, VT",
    "latitude": 44.656997,
    "longitude": -72.808505
  },
  {
    "key": "EnsbrgFVT",
    "name": "enosburg",
    "displayName": "Enosburg Falls, VT",
    "latitude": 44.905737,
    "longitude": -72.805875
  },
  {
    "key": "CwnsvlQC",
    "name": "cowansville",
    "displayName": "Cowansville, CA",
    "latitude": 45.2,
    "longitude": -72.75
  },
  {
    "key": "ObsrvtQC",
    "name": "etoiles",
    "displayName": "ObservEtoiles, CA",
    "latitude": 45.042231,
    "longitude": -72.565927
  },
  {
    "key": "LcLvrngQC",
    "name": "lovering",
    "displayName": "Lac Lovering, CA",
    "latitude": 45.17334,
    "longitude": -72.149963
  },
  {
    "key": "CtckQC",
    "name": "coaticook",
    "displayName": "Coaticook, CA",
    "latitude": 45.133686,
    "longitude": -71.803946
  }
];

final locations = {
  for (var element in locationJson.map((e) => Location(
      e['name'] as String,
      e['displayName'] as String,
      e['key'] as String,
      e['latitude'] as double,
      e['longitude'] as double)))
    element.name: element
};
