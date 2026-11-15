buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Mengunci Kotlin bawaan AGP ke versi katalog.
        classpath(libs.kotlin.gradle.plugin)
    }
}
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.compose.compiler) apply false
}
