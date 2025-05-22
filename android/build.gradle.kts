plugins {
    id("com.android.application") apply false
    id("com.android.library") apply false
    // id("org.jetbrains.kotlin.android") version "1.9.22" apply false // Sử dụng cách khai báo plugin Kotlin chính xác hơn nếu cần
    // Dòng kotlin("android") version "2.1.21" apply false có vẻ không chuẩn,
    // phiên bản Kotlin thường được quản lý ở một chỗ khác hoặc qua plugin 'org.jetbrains.kotlin.android'.
    // Tạm thời giữ nguyên để tập trung vào lỗi google-services.

    // SỬA Ở ĐÂY: Đổi version "1.9.22" thành "2.1.21" để khớp với phiên bản đã có trên classpath
    kotlin("android") version "2.1.21" apply false

    // SỬA Ở ĐÂY: Đổi version "4.4.0" thành "4.3.15" để khớp với phiên bản đã có trên classpath
    id("com.google.gms.google-services") version "4.3.15" apply false
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

