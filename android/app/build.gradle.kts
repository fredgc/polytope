import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = file("${System.getProperty("user.home")}/.android/key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}
val uploadStoreFile = file(
    keystoreProperties.getProperty("storeFile")
        ?: "${System.getProperty("user.home")}/.android/upload-keystore.jks"
)
val uploadPassword = System.getenv("KEYSTORE_PW")
    ?: keystoreProperties.getProperty("storePassword")

android {
    namespace = "org.gchouse.polytope"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "org.gchouse.polytope2"
        minSdk = maxOf(28, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (uploadStoreFile.exists() && !uploadPassword.isNullOrEmpty()) {
            create("release") {
                storeFile = uploadStoreFile
                storePassword = uploadPassword
                keyAlias = keystoreProperties.getProperty("keyAlias") ?: "gchouse-upload"
                keyPassword = keystoreProperties.getProperty("keyPassword") ?: uploadPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
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
