plugins {
    id("com.android.application") apply false
    id("com.android.library") apply false
    kotlin("android") version "2.1.21" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false  // <-- PHẢI CÓ VERSION Ở ĐÂY
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
