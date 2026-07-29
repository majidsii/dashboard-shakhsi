import 'linux_systemd_environment.dart';

/// Configuration failure while resolving the systemd user-unit directory.
final class LinuxSystemdConfigurationException implements Exception {
  const LinuxSystemdConfigurationException({
    required this.message,
    this.variableName,
  });

  final String message;
  final String? variableName;

  @override
  String toString() {
    final variable = variableName;
    if (variable == null) {
      return 'LinuxSystemdConfigurationException: $message';
    }

    return 'LinuxSystemdConfigurationException($variable): $message';
  }
}

/// Resolves the current user's systemd unit directory without creating it.
final class LinuxSystemdUserUnitPathResolver {
  const LinuxSystemdUserUnitPathResolver(this._environment);

  final LinuxSystemdEnvironment _environment;

  String resolve() {
    final xdgConfigHome = _clean(_environment.value('XDG_CONFIG_HOME'));
    if (xdgConfigHome.isNotEmpty) {
      return _append(
        _validateAbsoluteBase(xdgConfigHome, variableName: 'XDG_CONFIG_HOME'),
        'systemd/user',
      );
    }

    final home = _clean(_environment.value('HOME'));
    if (home.isNotEmpty) {
      return _append(
        _validateAbsoluteBase(home, variableName: 'HOME'),
        '.config/systemd/user',
      );
    }

    throw const LinuxSystemdConfigurationException(
      message:
          'Neither XDG_CONFIG_HOME nor HOME contains a usable '
          'absolute path.',
    );
  }

  String _clean(String? value) => value?.trim() ?? '';

  String _validateAbsoluteBase(String value, {required String variableName}) {
    if (_containsControlCharacter(value)) {
      throw LinuxSystemdConfigurationException(
        variableName: variableName,
        message: 'The configured path contains a control character.',
      );
    }

    if (!value.startsWith('/')) {
      throw LinuxSystemdConfigurationException(
        variableName: variableName,
        message: 'The configured path must be absolute.',
      );
    }

    return _removeTrailingSlashes(value);
  }

  bool _containsControlCharacter(String value) {
    for (final codeUnit in value.codeUnits) {
      if (codeUnit < 0x20 || codeUnit == 0x7f) {
        return true;
      }
    }

    return false;
  }

  String _removeTrailingSlashes(String value) {
    var end = value.length;

    while (end > 1 && value.codeUnitAt(end - 1) == 0x2f) {
      end -= 1;
    }

    return value.substring(0, end);
  }

  String _append(String base, String suffix) {
    if (base == '/') {
      return '/$suffix';
    }

    return '$base/$suffix';
  }
}
