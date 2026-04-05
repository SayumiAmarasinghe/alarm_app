plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.alarm_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.alarm_app"
        minSdk = flutter.minSdkVersion // (Leave this as whatever it currently is!)
        targetSdk = 34 // <--- CHANGE THIS TO 34
        versionCode = 1
        versionName = "1.0"
        manifestPlaceholders["redirectSchemeName"] = "alarmapp"
        manifestPlaceholders["redirectHostName"] = "callback"
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
dependencies {
    // ADD THIS LINE
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3") // <--- KOTLIN SYNTAX
}
