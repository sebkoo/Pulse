rootProject.name = "pulse-android"

// The core module is pure Kotlin/JVM — the same architecture as PulseCore on
// iOS, testable without the Android SDK. The Compose app module is added on top.
include(":core")
