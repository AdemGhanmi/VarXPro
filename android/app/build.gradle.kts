plugins {
    id("com.android.application")
    id("kotlin-android")
    // Le plugin Flutter doit être appliqué après Android et Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.var_x_pro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" 

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // ⚠️ Remplace par ton vrai Application ID (unique sur le Play Store)
        applicationId = "com.example.var_x_pro"

        // Versions héritées de flutter.gradle
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Support multidex si tu as beaucoup de dépendances
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // ⚠️ IMPORTANT : Mets ta vraie clé de signature ici pour le Play Store
            // actuellement ça utilise la clé debug
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false // désactive R8/Proguard (à activer si tu configures rules.pro)
            isShrinkResources = false
        }
    }

    // Optionnel : si tu veux forcer le Java toolchain
    // java {
    //     toolchain {
    //         languageVersion.set(JavaLanguageVersion.of(11))
    //     }
    // }
}

flutter {
    source = "../.."
}

dependencies {
    // Obligatoire si tu utilises multidex
    implementation("androidx.multidex:multidex:2.0.1")
}
