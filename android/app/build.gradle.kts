plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // FlutterFire
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.rrhfit_sys32"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.rrhfit_sys32"
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.1.0"))

    // Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    

    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth:20.7.0")
}
