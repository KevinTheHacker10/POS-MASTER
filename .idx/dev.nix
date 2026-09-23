{ pkgs, ... }: {
  channel = "stable-25.05";

  packages = [
    pkgs.jdk17
    pkgs.unzip
  ];

  idx.extensions = [
    "Dart-Code.dart-code"
    "Dart-Code.flutter"
  ];

  idx.workspace.onCreate = {
    install-flutter-dependencies = "flutter pub get";
    default.openFiles = [ "lib/main.dart" ];
  };

  idx.previews = {
    enable = true;
    previews = {
      web = {
        command = [
          "flutter"
          "run"
          "--machine"
          "-d"
          "web-server"
          "--web-hostname"
          "0.0.0.0"
          "--web-port"
          "$PORT"
        ];
        manager = "flutter";
      };

      android = {
        manager = "flutter";
      };
    };
  };
}
