import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import '../entities/system_user.dart';

class LoggingRepository {
  SecureSocket _remoteLoggingSocket;

  StreamSubscription _remoteLogSubscription;

  String _logString(LogRecord record, {@required SystemUser user}) {
    var sanitizedMessage = record.message;

    // Source: https://stackoverflow.com/a/6967885
    final phoneNumberRegex = RegExp(
      r'\+(9[976]\d|8[987530]\d|6[987]\d|5[90]\d|42\d|3[875]\d|'
      r'2[98654321]\d|9[8543210]|8[6421]|6[6543210]|5[87654321]|'
      r'4[987654310]|3[9643210]|2[70]|7|1)\d{1,14}$',
    );

    // Source: https://emailregex.com/
    final emailRegex = RegExp(
      // The first one is not a raw string on purpose, so we can escape the
      // quotes (and other special characters).
      // The others aren't so that we don't have to escape anything.
      '(?:[a-z0-9!#\$%&\'*+/=?^_`{|}~-]+(?:\\.[a-z0-9!#\$%&\'*+/=?^_`{|}~-]+)*|'
      r'"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b'
      r'\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]'
      r'(?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'
      r'\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:'
      r'[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b'
      r'\x0c\x0e-\x7f])+)\])',
    );

    // Sanitize the logs, if this ever fires code should be changed to not
    // make this happen.
    sanitizedMessage = sanitizedMessage
        .replaceAll(phoneNumberRegex, '[REDACTED PHONE NUMBER]')
        .replaceAll(emailRegex, '[REDACTED EMAIL]');

    // If log message is the same as the sanitized message, no sanitation
    // has taken place and we're good.
    assert(record.message == sanitizedMessage);

    final uuid = user != null ? '${user.uuid} ' : '';

    return '[${record.time}] ${record.level.name} $uuid${record.loggerName}:'
        ' $sanitizedMessage';
  }

  Future<void> enableConsoleLogging({
    @required SystemUser user,
    void Function(String log) onLog,
  }) async {
    Logger.root.onRecord.listen((record) {
      final logString = _logString(record, user: user);
      if (logString != null) {
        onLog?.call(logString);
        print(logString);
      }
    });
  }

  Future<void> enableRemoteLogging({
    @required SystemUser user,
    @required String token,
  }) async {
    _remoteLoggingSocket = await SecureSocket.connect(
      'data.logentries.com',
      443,
    );

    if (token != null && token.isNotEmpty) {
      _remoteLogSubscription ??= Logger.root.onRecord.listen((record) async {
        final message = _logString(record, user: user);
        if (message == null) {
          return;
        }

        _remoteLoggingSocket.writeln('$token $message');
      });
    }
  }

  Future<void> sendLogsToRemote(
    String logs, {
    @required String token,
  }) async {
    assert(_remoteLoggingSocket != null);

    final savedLogs = logs.split('\n');

    _remoteLoggingSocket.write(
      savedLogs.map((line) => '$token $line').join('\n'),
    );
  }

  Future<void> disableRemoteLogging() async {
    await _remoteLogSubscription?.cancel();
    _remoteLogSubscription = null;
  }
}
