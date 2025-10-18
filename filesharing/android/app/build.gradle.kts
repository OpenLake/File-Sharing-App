import java.io.FileInputStream
import java.util.Properties

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        load(FileInputStream(localPropertiesFile))
    }
}

val flutterRoot = localProperties.getProperty("flutter.sdk")
    ?: throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.filesharing"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.example.filesharing"
        minSdk = 24
        targetSdk = 36
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:2.1.0")
}

// temporary solution to path error during 'flutter run'
afterEvaluate {
    tasks.findByName("assembleDebug")?.doLast {
        val src = layout.buildDirectory.file("outputs/apk/debug/app-debug.apk").get().asFile
        val destDir = rootProject.layout.projectDirectory.dir("../build/app/outputs/flutter-apk").asFile
        destDir.mkdirs()
        if (src.exists()) {
            src.copyTo(File(destDir, "app-debug.apk"), overwrite = true)
            println("Copied debug APK to ${destDir.absolutePath}")
        } else {
            println("APK not found at ${src.absolutePath}")
        }
    }

    tasks.findByName("assembleRelease")?.doLast {
        val src = layout.buildDirectory.file("outputs/apk/release/app-release.apk").get().asFile
        val destDir = rootProject.layout.projectDirectory.dir("../build/app/outputs/flutter-apk").asFile
        destDir.mkdirs()
        if (src.exists()) {
            src.copyTo(File(destDir, "app-release.apk"), overwrite = true)
            println("Copied release APK to ${destDir.absolutePath}")
        } else {
            println("APK not found at ${src.absolutePath}")
        }
    }
}
