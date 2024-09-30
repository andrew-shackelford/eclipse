import 'package:http/http.dart' as http;
import 'dart:core';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String linkWithoutCors(String url) {
  return 'https://corsproxy.io/?' + Uri.encodeComponent(url);
}

Future<http.Response> fetchWithoutCors(String url) {
  return http.get(Uri.parse(linkWithoutCors(url)));
}

String get zuluString {
  return 'The current time is: ${DateTime.now().toUtc().hour.toString().padLeft(2, '0')}${DateTime.now().toUtc().minute.toString().padLeft(2, '0')}Z';
}

extension ImageUtils on img.Image {
  static const TIME_TOP = 58;
  static const TIME_HEIGHT = 14;
  static const FORECAST_LEFT = 134;
  static const FORECAST_TOP = 77;
  static const FORECAST_WIDTH = 12;
  static const FORECAST_HEIGHT = 12;
  static const FORECAST_HORIZONTAL_SPACING = 2;
  static const FORECAST_VERTICAL_SPACING = 4;

  img.Image imageAtCoords(Rect coords) {
    return img.copyCrop(this,
        x: coords.left.toInt(),
        y: coords.top.toInt(),
        width: (coords.right - coords.left).toInt(),
        height: (coords.bottom - coords.top).toInt());
  }

  img.Image cloudCoverPicture(int index) {
    final left =
        FORECAST_LEFT + (FORECAST_WIDTH + FORECAST_HORIZONTAL_SPACING) * index;
    return imageAtCoords(Rect.fromLTWH(left.toDouble(), FORECAST_TOP.toDouble(),
        FORECAST_WIDTH.toDouble(), FORECAST_HEIGHT.toDouble()));
  }

  img.Image ecmwfCloudPicture(int index) {
    final left =
        FORECAST_LEFT + (FORECAST_WIDTH + FORECAST_HORIZONTAL_SPACING) * index;
    return imageAtCoords(Rect.fromLTWH(
        left.toDouble(),
        (FORECAST_TOP + FORECAST_HEIGHT + FORECAST_VERTICAL_SPACING).toDouble(),
        FORECAST_WIDTH.toDouble(),
        FORECAST_HEIGHT.toDouble()));
  }

  Image get imageWidget {
    return Image.memory(Uint8List.fromList(img.encodePng(this)));
  }

  Image get croppedForecastImage {
    var width = 1240;
    if (DateTime.now().day == 6) {
      width = 1200;
    } else if (DateTime.now().day == 7) {
      width = 750;
    } else if (DateTime.now().day == 8) {
      width = 400;
    }
    return img
        .copyCrop(this, x: 0, y: 0, width: width, height: 180)
        .imageWidget;
  }

  Image get croppedNameImage {
    return img.copyCrop(this, x: 410, y: 0, width: 400, height: 25).imageWidget;
  }

  img.Image bottomTimePicture(int index) {
    final left =
        FORECAST_LEFT + (FORECAST_WIDTH + FORECAST_HORIZONTAL_SPACING) * index;
    return imageAtCoords(Rect.fromLTWH(left.toDouble(), TIME_TOP.toDouble(),
        FORECAST_WIDTH.toDouble(), TIME_HEIGHT.toDouble()));
  }

  img.Image scaleAndAddBorder(int scaleFactor, int borderWidth) {
    // Scale the image up by a factor of 2
    final scaledImage = img.copyResize(this,
        width: width * scaleFactor, height: height * scaleFactor);

    // Create a bright red border
    final borderColor = img.ColorInt8.rgb(255, 0, 0);

    // Create a new image with the border
    final outputImage = img.Image(
        width: scaledImage.width + borderWidth * 2,
        height: scaledImage.height + borderWidth * 2);

    // Fill the output image with the border color
    img.fill(outputImage, color: borderColor);

    // Copy the scaled image onto the center of the output image
    img.compositeImage(
      outputImage,
      scaledImage,
      dstX: borderWidth,
      dstY: borderWidth,
      srcW: scaledImage.width,
      srcH: scaledImage.height,
      center: true,
    );

    return outputImage;
  }
}

List<List<List<int>>> convertImageToRgbArray(img.Image image) {
  final width = image.width;
  final height = image.height;

  List<List<List<int>>> rgbArray = List.generate(
    height,
    (_) => List.generate(
      width,
      (_) => List.filled(3, 0),
    ),
  );

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;

      rgbArray[y][x] = [r.toInt(), g.toInt(), b.toInt()];
    }
  }

  return rgbArray;
}

List<int> detectColorChanges(List<img.Image> images, int threshold) {
  List<int> colorChangeIndexes = [];
  List<int> prevAvgRgb = [0, 0, 0];

  for (int i = 0; i < images.length; i++) {
    final rgbArray = convertImageToRgbArray(images[i]);
    const nonBlackThreshold = 30;

    int redSum = 0;
    int greenSum = 0;
    int blueSum = 0;
    int nonBlackCount = 0;

    for (final row in rgbArray) {
      for (final pixel in row) {
        final r = pixel[0];
        final g = pixel[1];
        final b = pixel[2];

        if (r + g + b > nonBlackThreshold) {
          redSum += r;
          greenSum += g;
          blueSum += b;
          nonBlackCount++;
        }
      }
    }

    if (nonBlackCount > 0) {
      final avgRed = redSum ~/ nonBlackCount;
      final avgGreen = greenSum ~/ nonBlackCount;
      final avgBlue = blueSum ~/ nonBlackCount;

      if (i > 0 && (avgRed - prevAvgRgb[0]).abs() > threshold ||
          (avgGreen - prevAvgRgb[1]).abs() > threshold ||
          (avgBlue - prevAvgRgb[2]).abs() > threshold) {
        colorChangeIndexes.add(i);
      }

      prevAvgRgb = [avgRed, avgGreen, avgBlue];
    }
  }

  return colorChangeIndexes;
}

DateTime get mockEclipseTime {
  return DateTime(2024, 4, usingMockEclipseTime ? 6 : 8, 15);
}

DateTime get mockEclipseTime4PM {
  return DateTime(2024, 4, usingMockEclipseTime ? 6 : 8, 16);
}

bool get usingMockEclipseTime {
  return DateTime.now().day < 6;
}

DateTime parseEclipseTime(String timeString) {
  List<String> parts = timeString.split(':');
  int hours = int.parse(parts[0]);
  int minutes = int.parse(parts[1]);

  List<String> secondParts = parts[2].split('.');
  int seconds = int.parse(secondParts[0]);
  int tenths = int.parse(secondParts[1]);

  int milliseconds = (tenths * 100).toInt();

  DateTime now = DateTime.now();
  return DateTime.utc(
          now.year, now.month, now.day, hours, minutes, seconds, milliseconds)
      .toLocal();
}

String formatEclipseTime(DateTime dateTime) {
  DateFormat formatter = DateFormat('h:mm:ss a');
  return formatter.format(dateTime);
}

String eclipseStringForIndex(int index) {
  if (index == 0) return 'Eclipse begins: ';
  if (index == 1) return 'Totality begins: ';
  if (index == 2) return 'Totality ends: ';
  if (index == 3) return 'Eclipse ends: ';
  return '';
}

String shortEclipseStringForIndex(int index) {
  if (index == 0) return 'Begin: ';
  if (index == 1) return 'Begin: ';
  if (index == 2) return 'End: ';
  if (index == 3) return 'Ends: ';
  return '';
}
