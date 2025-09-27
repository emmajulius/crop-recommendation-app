import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:loading_overlay/loading_overlay.dart';

import '../utils/translator.dart';
import 'result_screen.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();
  final TextEditingController _nitrogenController = TextEditingController();
  final TextEditingController _phosphorusController = TextEditingController();
  final TextEditingController _potassiumController = TextEditingController();
  final TextEditingController _rainfallController = TextEditingController();
  final TextEditingController _phController = TextEditingController();

  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  String _selectedMode = 'Manual Input';
  bool _isLoading = false;

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(translate(context, 'error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
            child: Text(translate(context, 'ok')),
          )
        ],
      ),
    );
  }

  Future<void> _predictCrop() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final url = Uri.parse('https://ddc3c85d209e.ngrok-free.app/predict');

      final headers = {"Content-Type": "application/json"};

      try {
        final body = jsonEncode({
          "N": double.parse(_nitrogenController.text),
          "P": double.parse(_phosphorusController.text),
          "K": double.parse(_potassiumController.text),
          "temperature": double.parse(_temperatureController.text),
          "humidity": double.parse(_humidityController.text),
          "ph": double.parse(_phController.text),
          "rainfall": double.parse(_rainfallController.text),
        });

        final response = await http.post(url, headers: headers, body: body);
        setState(() => _isLoading = false);

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final List<dynamic>? recommendations =
              responseData['recommended_crops'] ?? responseData['top_3_recommendations'];

          if (recommendations == null || recommendations.isEmpty) {
            _showError("No recommendations received.");
            return;
          }

          // Cast List<dynamic> to List<Map<String, dynamic>>
          final typedRecommendations = List<Map<String, dynamic>>.from(recommendations);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(topRecommendations: typedRecommendations),
            ),
          );
        } else {
          _showError("Server error: ${response.statusCode}");
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError("Failed to connect to the server.");
      }
    }
  }

  Future<void> _predictCropFromWeatherAPI() async {
    if (_latitudeController.text.isEmpty || _longitudeController.text.isEmpty) {
      _showError("${translate(context, 'enter_latitude')} & ${translate(context, 'enter_longitude')}");
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('https://ddc3c85d209e.ngrok-free.app/predict-weather');

    final headers = {"Content-Type": "application/json"};
    final body = jsonEncode({
      "latitude": double.parse(_latitudeController.text),
      "longitude": double.parse(_longitudeController.text),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic>? recommendations =
            responseData['recommended_crops'] ?? responseData['top_3_recommendations'];

        if (recommendations == null || recommendations.isEmpty) {
          _showError("No recommendations received.");
          return;
        }

        final typedRecommendations = List<Map<String, dynamic>>.from(recommendations);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResultScreen(topRecommendations: typedRecommendations, locationData: responseData),
          ),
        );
      } else {
        _showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Failed to connect to the server.");
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError("Location permission permanently denied.");
      return;
    }

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    if (!mounted) return;
    setState(() {
      _latitudeController.text = position.latitude.toString();
      _longitudeController.text = position.longitude.toString();
    });
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _humidityController.dispose();
    _nitrogenController.dispose();
    _phosphorusController.dispose();
    _potassiumController.dispose();
    _rainfallController.dispose();
    _phController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Widget _buildTextField(TextEditingController controller, String label, String errorMessage) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white70,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return errorMessage;
        if (double.tryParse(value) == null) return 'Enter a valid number';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      progressIndicator: const CircularProgressIndicator(color: Colors.green),
      child: Scaffold(
        appBar: AppBar(
          title: Text(translate(context, 'crop_recommendation')),
          backgroundColor: Colors.green.shade700,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: DropdownButton<String>(
                dropdownColor: Colors.green.shade100,
                value: _selectedMode,
                items: ['Manual Input', 'Use Weather API']
                    .map((mode) => DropdownMenuItem(
                          value: mode,
                          child: Text(mode),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMode = value!;
                  });
                },
              ),
            )
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/background.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  if (_selectedMode == 'Manual Input') ...[
                    _buildTextField(_nitrogenController, 'N', translate(context, 'enter_n')),
                    const SizedBox(height: 20),
                    _buildTextField(_phosphorusController, 'P', translate(context, 'enter_p')),
                    const SizedBox(height: 20),
                    _buildTextField(_potassiumController, 'K', translate(context, 'enter_k')),
                    const SizedBox(height: 20),
                    _buildTextField(_temperatureController, translate(context, 'temperature'), translate(context, 'enter_temp')),
                    const SizedBox(height: 20),
                    _buildTextField(_humidityController, translate(context, 'humidity'), translate(context, 'enter_humidity')),
                    const SizedBox(height: 20),
                    _buildTextField(_rainfallController, translate(context, 'rainfall'), translate(context, 'enter_rainfall')),
                    const SizedBox(height: 20),
                    _buildTextField(_phController, translate(context, 'ph'), translate(context, 'enter_ph')),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _predictCrop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        translate(context, 'recommend_crop'),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                  if (_selectedMode == 'Use Weather API') ...[
                    _buildTextField(_latitudeController, translate(context, 'latitude'), translate(context, 'enter_latitude')),
                    const SizedBox(height: 20),
                    _buildTextField(_longitudeController, translate(context, 'longitude'), translate(context, 'enter_longitude')),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.gps_fixed),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      label: Text(
                        translate(context, 'use_current_location'),
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _predictCropFromWeatherAPI,
                      icon: const Icon(Icons.cloud),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      label: Text(
                        translate(context, 'get_recommendation'),
                        style: const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
