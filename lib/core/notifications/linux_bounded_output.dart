final class LinuxBoundedOutput {
  const LinuxBoundedOutput({
    required this.text,
    required this.totalBytes,
    required this.retainedBytes,
    required this.droppedBytes,
    required this.truncated,
    required this.malformedUtf8,
  }) : assert(totalBytes >= 0),
       assert(retainedBytes >= 0),
       assert(droppedBytes >= 0),
       assert(totalBytes == retainedBytes + droppedBytes),
       assert(truncated == (droppedBytes > 0));

  final String text;
  final int totalBytes;
  final int retainedBytes;
  final int droppedBytes;
  final bool truncated;
  final bool malformedUtf8;
}
