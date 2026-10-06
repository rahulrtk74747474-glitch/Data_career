import 'dart:io';

void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml');
  final gradle = File('android/app/build.gradle.kts');

  if (!manifest.existsSync() || !gradle.existsSync()) {
    stderr.writeln(
      'Android wrapper not found. Run flutter create --platforms=android . first.',
    );
    exitCode = 2;
    return;
  }

  var manifestText = manifest.readAsStringSync();
  if (!manifestText.contains('android.permission.RECEIVE_BOOT_COMPLETED')) {
    final manifestClose = manifestText.indexOf('>');
    manifestText = manifestText.replaceRange(
      manifestClose + 1,
      manifestClose + 1,
      '\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>',
    );
  }

  if (!manifestText.contains(
    'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
  )) {
    const receivers = '''
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver
            android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
''';
    manifestText = manifestText.replaceFirst(
      '    </application>',
      '${receivers}    </application>',
    );
  }
  manifest.writeAsStringSync(manifestText);

  var gradleText = gradle.readAsStringSync();
  if (!gradleText.contains('isCoreLibraryDesugaringEnabled = true')) {
    gradleText = gradleText.replaceFirst(
      'compileOptions {',
      'compileOptions {\n        isCoreLibraryDesugaringEnabled = true',
    );
  }

  gradleText = gradleText.replaceAll(
    'JavaVersion.VERSION_11',
    'JavaVersion.VERSION_17',
  );

  if (!gradleText.contains('multiDexEnabled = true')) {
    gradleText = gradleText.replaceFirst(
      'defaultConfig {',
      'defaultConfig {\n        multiDexEnabled = true',
    );
  }

  if (!gradleText.contains('coreLibraryDesugaring(')) {
    final dependency = StringBuffer()
      ..writeln()
      ..writeln('dependencies {')
      ..writeln(
        '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")',
      )
      ..writeln('}');
    gradleText = '${gradleText.trimRight()}\n${dependency.toString()}';
  }

  gradle.writeAsStringSync(gradleText);
  stdout.writeln('Android notification configuration applied.');
}
