import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const iosSha =
      '5941547509b49a3756667905f18492dfdf4e59a977de1deacccfcf7ff94ac295';
  const macosSha =
      '8f83805217d979dc560d008fce66c1c77014f631cccff8978f31baf1d7ef3b28';
  const macosAssetsSha =
      '4bbbb036ce008f2213803ad05d7591ed4c0ac009f677a2e1d3d3b315ceb1ce31';

  File generatedReference() => File(
    'docs/superpowers/references/generated/apple_ui_kit_reference.json',
  );

  test('generated Apple reference is pinned to the frozen source hashes', () {
    final file = generatedReference();

    expect(
      file.existsSync(),
      isTrue,
      reason:
          'RED_EXPECTED: Gate A extractor has not generated the reference JSON yet.',
    );

    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final ios = data['ios'] as Map<String, dynamic>;
    final macos = data['macos'] as Map<String, dynamic>;
    final assets = data['macosAssets'] as Map<String, dynamic>;

    expect((ios['source'] as Map<String, dynamic>)['sha256'], iosSha);
    expect((macos['source'] as Map<String, dynamic>)['sha256'], macosSha);
    expect((assets['source'] as Map<String, dynamic>)['sha256'], macosAssetsSha);
  });

  test('generated reference contains the locked page counts', () {
    final file = generatedReference();

    expect(
      file.existsSync(),
      isTrue,
      reason:
          'RED_EXPECTED: Gate A extractor has not generated the reference JSON yet.',
    );

    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final ios = data['ios'] as Map<String, dynamic>;
    final macos = data['macos'] as Map<String, dynamic>;

    expect(ios['pageCount'], 34);
    expect(macos['pageCount'], 37);
  });
}
