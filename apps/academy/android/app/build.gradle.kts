import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials — never committed (android/.gitignore already excludes
// key.properties, *.keystore, *.jks). Populate this file locally / in CI secrets from
// key.properties.example. Falls back to debug signing when absent so `flutter run --release`
// keeps working for local development without a real keystore.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigning = keystorePropertiesFile.exists()
if (hasReleaseSigning) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Escape hatch for `flutter run --release` on a machine with no keystore. It has to be asked
// for explicitly (-PallowDebugSigningForRelease=true) because the alternative — falling back
// silently, as this build did before — produces a real, installable, *shippable* release APK
// signed with the debug key, whose private half is identical on every Android install on
// earth. Anyone can then forge an update for it, and the app can never migrate to the real
// key afterwards, since Android refuses an update signed by a different certificate. See the
// taskGraph check at the bottom of this file for where it is enforced.
val allowDebugSigningForRelease = project.findProperty("allowDebugSigningForRelease") == "true"

android {
    namespace = "com.petrimonium.academy"
    // flutter_secure_storage requires compiling against SDK 37 — flutter.compileSdkVersion
    // (36 as of this Flutter version) is a version behind, which fails the build below.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.petrimonium.academy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real signing when key.properties is present (real builds/CI). Without it the
            // build fails unless -PallowDebugSigningForRelease=true was passed — this used to
            // fall through to debug signing silently, which is the one failure mode you cannot
            // notice by looking at the artifact. See key.properties.example for setup.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

// Fails a release assembly that would otherwise be signed with the debug key. Enforced here,
// on the resolved task graph, rather than inside `buildTypes { release { ... } }`: that block
// is configured on every Gradle invocation, so throwing from it would break `assembleDebug`
// and `flutter test` too. This fires only when a release artifact is genuinely about to be
// produced.
//
// This mirrors PetrimoniumEnvironment.assertConfiguredForRelease() on the Dart side — a
// release build missing its configuration should stop, loudly, at build time, instead of
// producing something that looks shippable and is not.
gradle.taskGraph.whenReady {
    if (hasReleaseSigning || allowDebugSigningForRelease) return@whenReady

    val producesReleaseArtifact = allTasks.any { task ->
        task.project == project &&
            task.name.contains("Release") &&
            (task.name.startsWith("assemble") || task.name.startsWith("bundle") || task.name.startsWith("package"))
    }
    if (producesReleaseArtifact) {
        throw GradleException(
            "Refusing to build a release artifact without release signing: android/key.properties " +
                "is missing, so this would be signed with the debug keystore — a key whose private " +
                "half ships with the Android SDK and is identical for everyone. Populate " +
                "android/key.properties (see key.properties.example), or, if you only want to run " +
                "a release build locally and will never distribute it, pass " +
                "-PallowDebugSigningForRelease=true."
        )
    }
}
