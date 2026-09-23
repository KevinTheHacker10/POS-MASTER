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

## Firebase Studio

El repositorio incluye `.idx/dev.nix`. Al abrirlo en un espacio de trabajo
Flutter de Firebase Studio se ejecuta `flutter pub get` automáticamente y se
habilitan las vistas previas Web y Android. Si Firebase Studio solicita aplicar
la configuración, seleccioná **Rebuild environment**.

El paquete Dart, los ejecutables y los identificadores de aplicación usan la
identidad `pos_master` / `com.posmaster.app`; el nombre público es `POS-MASTER`.
