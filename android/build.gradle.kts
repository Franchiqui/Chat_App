// build.gradle.kts

buildscript {
    // Define la versión de Kotlin como una variable
    val kotlinVersion = "1.8.0"

    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Usa classpath con paréntesis y cadenas correctamente formateadas
        classpath("com.android.tools.build:gradle:7.4.2")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}