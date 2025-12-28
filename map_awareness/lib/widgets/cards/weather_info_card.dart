import 'package:flutter/material.dart';
import 'package:map_awareness/models/dto/dto.dart';
import 'package:map_awareness/utils/app_theme.dart';
import 'package:map_awareness/widgets/common/premium_card.dart';

/// Widget for displaying start and end location weather forecasts side-by-side.
class WeatherInfoCard extends StatelessWidget {
  final String startName;
  final String endName;
  final WeatherDto? departureWeather;
  final WeatherDto? arrivalWeather;

  const WeatherInfoCard({
    super.key,
    required this.startName,
    required this.endName,
    this.departureWeather,
    this.arrivalWeather,
  });

  @override
  Widget build(BuildContext context) {
    if (departureWeather == null && arrivalWeather == null) {
      return const SizedBox.shrink();
    }

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accentLight]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Weather Forecast', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          if (departureWeather != null) _buildWeatherRow('Departure', startName, departureWeather!),
          if (departureWeather != null && arrivalWeather != null) const SizedBox(height: 10),
          if (arrivalWeather != null) _buildWeatherRow('Arrival', endName, arrivalWeather!),
        ],
      ),
    );
  }

  /// Renders a single weather data row with icon, temp, description, and wind speed.
  Widget _buildWeatherRow(String label, String location, WeatherDto weather) {
    return Row(
      children: [
        Text(weather.icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                '${weather.temperature?.toStringAsFixed(1) ?? '--'}°C · ${weather.description}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              if (weather.precipitation != null && weather.precipitation! > 0)
                Text(
                  'Rain: ${weather.precipitation!.toStringAsFixed(1)}mm',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
            ],
          ),
        ),
        if (weather.windSpeed != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.air, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(
                  '${weather.windSpeed!.toStringAsFixed(0)} km/h',
                  style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
