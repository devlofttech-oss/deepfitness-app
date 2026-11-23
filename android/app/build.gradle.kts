import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The upload key, when there is one.
//
// `key.properties` holds the keystore path and its passwords and is in
// android/.gitignore, so it never reaches the repository. A machine without
// it still builds — see the release build type below — which keeps
// `flutter run --release` working for anyone who has not been given the key.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasUploadKey = keystorePropertiesFile.exists()

android {
    namespace = "com.deepfitness.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.deepfitness.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasUploadKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug keys so a developer without the upload
            // key can still build and install a release APK. That fallback is
            // also a trap: a debug-signed artifact looks normal and Play will
            // reject it, so CI checks the signer after building rather than
            // trusting this. See the "Verify the signer" step in ci.yml.
            signingConfig = if (hasUploadKey) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "WARNING: no android/key.properties — signing the release " +
                        "build with the DEBUG key. This artifact cannot be " +
                        "uploaded to the Play Console.",
                )
                signingConfigs.getByName("debug")
            }
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
