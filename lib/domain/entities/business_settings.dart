import 'package:flutter/material.dart';

enum BusinessType {
  restaurant,
  soda,
  cafeteria,
  bakery,
  bar,
  fastFood,
  foodTruck,
  serviceWindow,
  grocery,
  supermarket,
  pharmacy,
  retail,
  salon,
  services,
  other;

  String get label {
    switch (this) {
      case BusinessType.restaurant:
        return 'Restaurante';
      case BusinessType.soda:
        return 'Soda';
      case BusinessType.cafeteria:
        return 'Cafetería';
      case BusinessType.bakery:
        return 'Panadería o repostería';
      case BusinessType.bar:
        return 'Bar';
      case BusinessType.fastFood:
        return 'Comida rápida';
      case BusinessType.foodTruck:
        return 'Food truck';
      case BusinessType.serviceWindow:
        return 'Ventanilla';
      case BusinessType.grocery:
        return 'Pulpería o minisúper';
      case BusinessType.supermarket:
        return 'Supermercado';
      case BusinessType.pharmacy:
        return 'Farmacia';
      case BusinessType.retail:
        return 'Tienda minorista';
      case BusinessType.salon:
        return 'Salón o barbería';
      case BusinessType.services:
        return 'Servicios';
      case BusinessType.other:
        return 'Otro';
    }
  }
}

enum AppPalette {
  forest('Bosque', 0xFF667A45),
  ocean('Océano', 0xFF1565C0),
  sunset('Atardecer', 0xFFE65100),
  berry('Frutos rojos', 0xFF8E245F),
  graphite('Grafito', 0xFF455A64);

  final String label;
  final int colorValue;
  const AppPalette(this.label, this.colorValue);

  Color get color => Color(colorValue);
}

class BusinessSettings {
  final String businessName;
  final BusinessType businessType;
  final AppPalette palette;
  final bool isConfigured;

  const BusinessSettings({
    this.businessName = '',
    this.businessType = BusinessType.restaurant,
    this.palette = AppPalette.forest,
    this.isConfigured = false,
  });
}
