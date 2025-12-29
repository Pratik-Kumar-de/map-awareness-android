import 'package:flutter/material.dart';
import 'package:map_awareness/models/dto/dto.dart';

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

    final theme = Theme.of(context);

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
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.wb_sunny_rounded, color: theme.colorScheme.onSecondaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Weather Forecast', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          if (departureWeather != null) _buildWeatherRow(theme, 'Departure', startName, departureWeather!),
          if (departureWeather != null && arrivalWeather != null) const SizedBox(height: 10),
          if (arrivalWeather != null) _buildWeatherRow(theme, 'Arrival', endName, arrivalWeather!),
        ],
      ),
    );
  }

  /// Renders a single weather data row with icon, temp, description, and wind speed.
  Widget _buildWeatherRow(ThemeData theme, String label, String location, WeatherDto weather) {
    return Row(
      children: [
        Text(weather.icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(
                '${weather.temperature?.toStringAsFixed(1) ?? '--'}°C · ${weather.description}',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (weather.precipitation != null && weather.precipitation! > 0)
                Text(
                  'Rain: ${weather.precipitation!.toStringAsFixed(1)}mm',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        if (weather.windSpeed != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.air, size: 14, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 4),
                Text(
                  '${weather.windSpeed!.toStringAsFixed(0)} km/h',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
