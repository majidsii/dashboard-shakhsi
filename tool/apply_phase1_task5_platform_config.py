#!/usr/bin/env python3
from pathlib import Path
import xml.etree.ElementTree as ET

gradle_path = Path('android/app/build.gradle.kts')
gradle = gradle_path.read_text(encoding='utf-8')

if 'isCoreLibraryDesugaringEnabled = true' not in gradle:
    anchor = '    compileOptions {\n'
    if anchor not in gradle:
        raise SystemExit('Android compileOptions block was not found.')
    gradle = gradle.replace(
        anchor,
        anchor + '        isCoreLibraryDesugaringEnabled = true\n',
        1,
    )

if 'multiDexEnabled = true' not in gradle:
    anchor = '    defaultConfig {\n'
    if anchor not in gradle:
        raise SystemExit('Android defaultConfig block was not found.')
    gradle = gradle.replace(
        anchor,
        anchor + '        multiDexEnabled = true\n',
        1,
    )

dependency = (
    'coreLibraryDesugaring('
    '"com.android.tools:desugar_jdk_libs:2.1.4"'
    ')'
)
if dependency not in gradle:
    gradle = gradle.rstrip() + (
        '\n\n'
        'dependencies {\n'
        f'    {dependency}\n'
        '}\n'
    )

gradle_path.write_text(gradle, encoding='utf-8')

manifest_path = Path('android/app/src/main/AndroidManifest.xml')
ET.register_namespace('android', 'http://schemas.android.com/apk/res/android')
tree = ET.parse(manifest_path)
root = tree.getroot()
android_ns = '{http://schemas.android.com/apk/res/android}'

permission_name = 'android.permission.RECEIVE_BOOT_COMPLETED'
permissions = {
    item.attrib.get(android_ns + 'name')
    for item in root.findall('uses-permission')
}
if permission_name not in permissions:
    permission = ET.Element(
        'uses-permission',
        {android_ns + 'name': permission_name},
    )
    root.insert(0, permission)

application = root.find('application')
if application is None:
    raise SystemExit('Android application element was not found.')

receiver_names = {
    item.attrib.get(android_ns + 'name')
    for item in application.findall('receiver')
}

scheduled_receiver = (
    'com.dexterous.flutterlocalnotifications.'
    'ScheduledNotificationReceiver'
)
if scheduled_receiver not in receiver_names:
    ET.SubElement(
        application,
        'receiver',
        {
            android_ns + 'exported': 'false',
            android_ns + 'name': scheduled_receiver,
        },
    )

boot_receiver = (
    'com.dexterous.flutterlocalnotifications.'
    'ScheduledNotificationBootReceiver'
)
if boot_receiver not in receiver_names:
    receiver = ET.SubElement(
        application,
        'receiver',
        {
            android_ns + 'exported': 'false',
            android_ns + 'name': boot_receiver,
        },
    )
    intent_filter = ET.SubElement(receiver, 'intent-filter')
    for action_name in (
        'android.intent.action.BOOT_COMPLETED',
        'android.intent.action.MY_PACKAGE_REPLACED',
        'android.intent.action.QUICKBOOT_POWERON',
        'com.htc.intent.action.QUICKBOOT_POWERON',
    ):
        ET.SubElement(
            intent_filter,
            'action',
            {android_ns + 'name': action_name},
        )

ET.indent(tree, space='    ')
tree.write(
    manifest_path,
    encoding='unicode',
    xml_declaration=False,
)
manifest_path.write_text(
    manifest_path.read_text(encoding='utf-8').rstrip() + '\n',
    encoding='utf-8',
)

print('Phase 1 Task 5 Android platform configuration applied.')
