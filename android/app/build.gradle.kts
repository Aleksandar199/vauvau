import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun requireReleaseSigningProperty(name: String): String {
    val value = keystoreProperties.getProperty(name)?.trim().orEmpty()
    if (value.isEmpty() ||
        value.contains("YOUR_", ignoreCase = true) ||
        value.contains("CHANGE_ME", ignoreCase = true) ||
        value.contains("path/to", ignoreCase = true) ||
        value.contains("example", ignoreCase = true)
    ) {
        throw GradleException(
            "android/key.properties: missing or placeholder value for '$name'. " +
                "Release builds require a real upload keystore — see key.properties.example.",
        )
    }
    return value
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vauvau.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Omogućeno prevođenje novijih Java API-ja (potrebno za flutter_local_notifications)
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.vauvau.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Populated only when key.properties exists so debug sync still works.
            // Release buildType below hard-fails if anything is missing/placeholder.
            if (keystorePropertiesFile.exists()) {
                keyAlias = requireReleaseSigningProperty("keyAlias")
                keyPassword = requireReleaseSigningProperty("keyPassword")
                storePassword = requireReleaseSigningProperty("storePassword")
                val storePath = requireReleaseSigningProperty("storeFile")
                val resolved = file(storePath)
                if (!resolved.isFile) {
                    throw GradleException(
                        "android/key.properties storeFile does not exist: $storePath",
                    )
                }
                storeFile = resolved
            }
        }
    }

    buildTypes {
        release {
            // Never fall back to the debug keystore — Play rejects those AABs.
            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    "Missing android/key.properties. Release builds must use the upload keystore — " +
                        "copy key.properties.example to key.properties and fill in storeFile/passwords.",
                )
            }
            signingConfig = signingConfigs.getByName("release")
            // Explicit: do not inherit debug signing if release config is incomplete.
            if (signingConfig == signingConfigs.getByName("debug")) {
                throw GradleException("Release must not use the debug signing config.")
            }
            // R8: smaller AAB + strip unused code/resources for Play release.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    // Neophodna biblioteka za core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
