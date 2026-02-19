val mapsApiKey = project.findProperty("MAPS_API_KEY") as String?

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
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
        minSdk = 21
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

