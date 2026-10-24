plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    // Generates Google Sign-In resources from google-services.json.
    id("com.google.gms.google-services")
}

android {
    namespace = "com.intertaxi.intertaxi"
    compileSdk = 36
    ndkVersion = "30.0.16138531"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.intertaxi.intertaxi"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
