import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

fun isRunningOnCI(): Boolean {
    return System.getenv("CI") != null || 
           System.getenv("GITHUB_ACTIONS") != null ||
           System.getenv("GITLAB_CI") != null
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else if (isRunningOnCI()) {
    // If running on CI, the keystore properties must be set as environment variables.
    keystoreProperties["keyAlias"] = System.getenv("ALIAS")
    keystoreProperties["storePassword"] = System.getenv("KEY_STORE_PASSWORD")
    keystoreProperties["storeFile"] = System.getenv("KEY_PATH")
    keystoreProperties["keyPassword"] = System.getenv("KEY_PASSWORD")
}

android {
    namespace = "codes.merritt.adventurelist"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion
    // ndkVersion = "27.0.12077973"
    ndkVersion = "25.1.8937393"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "codes.merritt.adventurelist"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk = flutter.minSdkVersion
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists() || isRunningOnCI()) {
                storeFile = file(keystoreProperties["storeFile"])
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            } else {
                throw GradleException("key.properties not found")
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            // signingConfig = signingConfigs.getByName("debug")
            signingConfig = signingConfigs.getByName("release")
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")
}

flutter {
    source = "../.."
}
