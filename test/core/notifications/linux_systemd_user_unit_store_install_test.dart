import 'dart:convert';

import 'package:dashboard_shakhsi/core/notifications/linux_systemd_file_system.dart';
import 'package:dashboard_shakhsi/core/notifications/linux_systemd_user_unit_store_exception.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_linux_systemd_file_system.dart';

void main() {
  group('FakeLinuxSystemdFileSystem', () {
    test('writes and reads defensive byte copies', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final source = <int>[1, 2, 3];

      await fileSystem.writeBytes('/units/job.service', source);
      source.add(4);

      final firstRead = await fileSystem.readBytes('/units/job.service');
      firstRead.add(5);

      expect(await fileSystem.readBytes('/units/job.service'), <int>[1, 2, 3]);
    });

    test('seedFile copies bytes and stores the supplied mode', () {
      final fileSystem = FakeLinuxSystemdFileSystem();
      final source = <int>[10, 20];

      fileSystem.seedFile('/units/job.service', source, mode: 0x180);
      source.add(30);

      expect(fileSystem.bytesOf('/units/job.service'), <int>[10, 20]);
      expect(fileSystem.modeOf('/units/job.service'), 0x180);
    });

    test('rename preserves bytes and mode exactly', () async {
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..seedFile('/units/job.tmp', <int>[7, 8, 9], mode: 0x1A4);

      await fileSystem.rename('/units/job.tmp', '/units/job.service');

      expect(fileSystem.containsPath('/units/job.tmp'), isFalse);
      expect(fileSystem.bytesOf('/units/job.service'), <int>[7, 8, 9]);
      expect(fileSystem.modeOf('/units/job.service'), 0x1A4);
    });

    test('typeOf identifies symlinks without following them', () async {
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..seedFile('/units/target.service', <int>[1])
        ..seedSymlink('/units/link.service', '/units/target.service');

      expect(
        await fileSystem.typeOf('/units/link.service'),
        LinuxSystemdEntryType.symbolicLink,
      );
      expect(
        fileSystem.linkTargetOf('/units/link.service'),
        '/units/target.service',
      );
    });

    test('createDirectory records a directory entry', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();

      await fileSystem.createDirectory('/units');

      expect(
        await fileSystem.typeOf('/units'),
        LinuxSystemdEntryType.directory,
      );
    });

    test('deleteFile is idempotent for a missing path', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();

      await expectLater(
        fileSystem.deleteFile('/units/missing.service'),
        completes,
      );
    });

    test('deleteFile rejects a symlink and preserves its target', () async {
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..seedFile('/units/target.service', <int>[1, 2])
        ..seedSymlink('/units/link.service', '/units/target.service');

      await expectLater(
        fileSystem.deleteFile('/units/link.service'),
        throwsA(isA<LinuxSystemdUnsafeEntryException>()),
      );

      expect(fileSystem.containsPath('/units/link.service'), isTrue);
      expect(fileSystem.bytesOf('/units/target.service'), <int>[1, 2]);
    });

    test('an injected operation failure happens exactly once', () async {
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..failNext('write:/units/job.service', error: StateError('disk full'));

      await expectLater(
        fileSystem.writeBytes('/units/job.service', <int>[1]),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'disk full',
          ),
        ),
      );

      await fileSystem.writeBytes('/units/job.service', <int>[2]);

      expect(fileSystem.bytesOf('/units/job.service'), <int>[2]);
    });

    test('supports multiple queued failures for one operation', () async {
      final fileSystem = FakeLinuxSystemdFileSystem()
        ..failNext('delete:/units/job.service', error: StateError('first'))
        ..failNext('delete:/units/job.service', error: StateError('second'))
        ..seedFile('/units/job.service', <int>[1]);

      await expectLater(
        fileSystem.deleteFile('/units/job.service'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'first',
          ),
        ),
      );
      await expectLater(
        fileSystem.deleteFile('/units/job.service'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'second',
          ),
        ),
      );
      await fileSystem.deleteFile('/units/job.service');

      expect(fileSystem.containsPath('/units/job.service'), isFalse);
    });

    test('records attempted operations in execution order', () async {
      final fileSystem = FakeLinuxSystemdFileSystem();

      await fileSystem.createDirectory('/units');
      await fileSystem.writeBytes('/units/job.tmp', <int>[1]);
      await fileSystem.chmod('/units/job.tmp', 0x1A4);
      await fileSystem.rename('/units/job.tmp', '/units/job.service');

      expect(fileSystem.operations, <String>[
        'createDirectory:/units',
        'write:/units/job.tmp',
        'chmod:/units/job.tmp:420',
        'rename:/units/job.tmp->/units/job.service',
      ]);
    });
  });

  group('LinuxSystemdUserUnitStoreException', () {
    test('preserves operation, file names, cause, and stack trace', () {
      final cause = StateError('install failed');
      final stackTrace = StackTrace.current;
      final error = LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.install,
        serviceFileName: 'job.service',
        timerFileName: 'job.timer',
        cause: cause,
        causeStackTrace: stackTrace,
      );

      expect(error.operation, LinuxSystemdUserUnitStoreOperation.install);
      expect(error.serviceFileName, 'job.service');
      expect(error.timerFileName, 'job.timer');
      expect(error.cause, same(cause));
      expect(error.causeStackTrace, same(stackTrace));
      expect(error.rollbackFailures, isEmpty);
    });

    test('copies rollback failures into an immutable list', () {
      final failures = <LinuxSystemdRollbackFailure>[
        LinuxSystemdRollbackFailure(
          step: 'restore-service',
          error: StateError('restore failed'),
          stackTrace: StackTrace.current,
        ),
      ];

      final exception = LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.install,
        serviceFileName: 'job.service',
        timerFileName: 'job.timer',
        cause: StateError('install failed'),
        causeStackTrace: StackTrace.current,
        rollbackFailures: failures,
      );
      failures.clear();

      expect(exception.rollbackFailures, hasLength(1));
      expect(
        () => exception.rollbackFailures.add(
          LinuxSystemdRollbackFailure(
            step: 'unexpected',
            error: StateError('unexpected'),
            stackTrace: StackTrace.current,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('toString includes context but never unit contents', () {
      const secret = 'PRIVATE_UNIT_CONTENT';
      final exception = LinuxSystemdUserUnitStoreException(
        operation: LinuxSystemdUserUnitStoreOperation.remove,
        serviceFileName: 'job.service',
        timerFileName: 'job.timer',
        cause: StateError('remove failed'),
        causeStackTrace: StackTrace.current,
        rollbackFailures: <LinuxSystemdRollbackFailure>[
          LinuxSystemdRollbackFailure(
            step: 'cleanup',
            error: StateError('cleanup failed'),
            stackTrace: StackTrace.current,
          ),
        ],
      );

      final text = exception.toString();

      expect(text, contains('remove'));
      expect(text, contains('job.service'));
      expect(text, contains('job.timer'));
      expect(text, contains('rollbackFailures: 1'));
      expect(text, isNot(contains(secret)));
      expect(utf8.encode(text), isNot(containsAllInOrder(utf8.encode(secret))));
    });
  });
}
