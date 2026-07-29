import 'linux_cancellation_token.dart';
import 'linux_process_request.dart';
import 'linux_process_result.dart';

abstract interface class LinuxProcessRunner {
  Future<LinuxProcessResult> run(
    LinuxProcessRequest request, {
    LinuxCancellationToken? cancellationToken,
  });
}
