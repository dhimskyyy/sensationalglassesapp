import java.util.Properties
import java.io.FileInputStream

// 1. Baca file .env dari folder root Flutter
val envProperties = Properties()
val envFile = rootProject.file("../.env")
if (envFile.exists()) {
    envProperties.load(FileInputStream(envFile))
}

// 2. Ambil nilai GOOGLE_MAPS_API_KEY dari .env
val mapsApiKey = envProperties.getProperty("GOOGLE_MAPS_API_KEY")

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.sensationalglassesapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {        
        applicationId = "com.example.sensationalglassesapp"
        // 3. Masukkan ke manifestPlaceholders dengan penanganan null
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey ?: ""
        
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
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
    // Firebase BOM (wajib)
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))

    // Untuk login Google & Facebook pakai Firebase Auth
    implementation("com.google.firebase:firebase-auth")

    // Opsional
    implementation("com.google.firebase:firebase-analytics")
}

