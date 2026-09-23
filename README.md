# POS-MASTER

Sistema de punto de venta configurable y multiplataforma para restaurantes,
sodas, cafeterías, ventanillas, pulperías, comercios y establecimientos de
servicios.

## Funciones actuales

- Configuración inicial de nombre comercial, tipo de negocio y paleta de color.
- Acceso diferenciado para administrador y mesero.
- Catálogo editable con productos, categorías, precios, disponibilidad e imágenes.
- Carrito, cobro, impuestos, SINPE, tarjeta y efectivo.
- Historial de órdenes, usuarios, reportes y productos más vendidos.
- Interfaz adaptable para web, Android, iOS, Windows y Linux.

## Desarrollo

Requiere Flutter con Dart 3.6 o superior.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

El identificador interno del paquete Dart se conserva temporalmente como
`matcha_lovers_506` para no romper importaciones ni instalaciones existentes;
el nombre público del producto y de las aplicaciones es `POS-MASTER`.
