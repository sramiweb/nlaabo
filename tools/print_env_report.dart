import 'dart:io';
import 'package:nlaabo/config/app_config.dart';

Future<void> main() async {
  final envs = [
    AppEnvironment.development,
    AppEnvironment.staging,
    AppEnvironment.production,
  ];

  for (final env in envs) {
    final envName = env == AppEnvironment.development ? 'development' : env == AppEnvironment.staging ? 'staging' : 'production';
    stdout.writeln('===== ${envName.toUpperCase()} =====');
    try {
      await AppConfig.initialize(environment: env);
      stdout.writeln('Valid: true');
      stdout.writeln('Configuration loaded successfully');
    } catch (e) {
      stdout.writeln('Valid: false');
      stdout.writeln('Error: $e');
    }
    stdout.writeln('');
  }

  stdout.writeln('Done.');
}