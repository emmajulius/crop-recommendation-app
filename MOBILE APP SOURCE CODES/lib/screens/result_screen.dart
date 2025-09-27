import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:html' as html; // For Flutter web

import 'map_screen.dart';
import '../utils/translator.dart';

class ResultScreen extends StatelessWidget {
  final List<dynamic> topRecommendations;
  final Map<String, dynamic>? locationData;

  const ResultScreen({
    super.key,
    required this.topRecommendations,
    this.locationData,
  });

  List<PieChartSectionData> _buildPieChartSections(BuildContext context) {
    final total = topRecommendations.fold<double>(
        0, (sum, item) => sum + (item['probability'] ?? 1.0));
    return topRecommendations.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final value = (item['probability'] ?? 1.0).toDouble();
      final percentage = (value / total) * 100;

      final colors = [Colors.green, Colors.orange, Colors.blue];
      final color = colors[idx % colors.length];

      final translatedCrop =
          translate(context, (item['crop'] ?? '').toString().toLowerCase());

      return PieChartSectionData(
        color: color,
        value: value,
        title: '$translatedCrop\n${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  String _buildResultText(BuildContext context) {
    final buffer = StringBuffer();
    buffer.writeln("${translate(context, 'crop_recommendation_results')}:\n");
    for (var item in topRecommendations) {
      final crop = item['crop'];
      final translatedCrop =
          translate(context, crop.toString().toLowerCase());
      final prob = (item['probability'] * 100).toStringAsFixed(1);
      buffer.writeln("${translate(context, 'crop')}: $translatedCrop, ${translate(context, 'probability')}: $prob%");
    }
    return buffer.toString();
  }

  List<LatLng> _parsePolygonPoints(dynamic polygonData) {
    final points = <LatLng>[];
    if (polygonData is String) {
      for (final pair in polygonData.split(';')) {
        final coords = pair.split(',');
        if (coords.length == 2) {
          try {
            final lat = double.parse(coords[0]);
            final lng = double.parse(coords[1]);
            points.add(LatLng(lat, lng));
          } catch (_) {
            // Skip invalid coordinates
          }
        }
      }
    }
    return points;
  }

  Future<void> _downloadResults(BuildContext context) async {
    try {
      final content = _buildResultText(context);

      if (kIsWeb) {
        final bytes = html.Blob([content]);
        final url = html.Url.createObjectUrlFromBlob(bytes);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "crop_recommendation_results.txt")
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate(context, 'download_success'))),
        );
      } else {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(translate(context, 'permission_denied'))),
          );
          return;
        }

        final dir = await getExternalStorageDirectory();
        final filePath = '${dir!.path}/crop_recommendation_results.txt';
        final file = File(filePath);
        await file.writeAsString(content);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translate(context, 'download_success'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${translate(context, 'download_failed')}: $e')),
      );
    }
  }

  void _shareResults(BuildContext context) {
    final message = _buildResultText(context);
    Share.share(message,
        subject: translate(context, 'crop_recommendation_results'));
  }

  @override
  Widget build(BuildContext context) {
    LatLng? soilLocation;
    String? soilRegion;
    List<LatLng> polygonPoints = [];

    if (locationData != null) {
      if (locationData!.containsKey('soil_latitude') &&
          locationData!.containsKey('soil_longitude')) {
        soilLocation = LatLng(
            locationData!['soil_latitude'], locationData!['soil_longitude']);
      }
      soilRegion = locationData!['soil_region'] ?? '';

      if (locationData!.containsKey('polygon')) {
        polygonPoints = _parsePolygonPoints(locationData!['polygon']);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(translate(context, 'prediction_result')),
        backgroundColor: Colors.green.shade700,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'share') {
                _shareResults(context);
              } else if (value == 'download') {
                _downloadResults(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: const [
                    Icon(Icons.share, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Share Results'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'download',
                child: Row(
                  children: const [
                    Icon(Icons.download, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Download Results'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (topRecommendations.isNotEmpty) ...[
              SizedBox(
                height: 300,
                child: PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(context),
                    centerSpaceRadius: 40,
                    sectionsSpace: 4,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                translate(context, 'recommended_crop'),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700),
              ),
              const SizedBox(height: 10),
              ...topRecommendations.map((item) {
                final crop = item['crop'];
                final translatedCrop =
                    translate(context, crop.toString().toLowerCase());
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading:
                        const Icon(Icons.agriculture, color: Colors.green),
                    title: Text(translatedCrop),
                    trailing: Text(
                      '${(item['probability'] * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ],

            if (soilRegion != null && soilRegion.isNotEmpty) ...[
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.terrain, color: Colors.brown),
                  const SizedBox(width: 8),
                  Text(
                    '${translate(context, 'soil_region')}: $soilRegion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ],

            if (soilLocation != null) ...[
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapScreen(
                        soilLocation: soilLocation!,
                        polygonPoints: polygonPoints,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: Text(translate(context, 'view_map')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
