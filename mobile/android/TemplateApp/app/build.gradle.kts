// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

// Платформын BFF хаяг. Локал `npm run dev`-д туршихдаа:
//   ./gradlew installDebug -PgeregeAppUrl=http://10.0.2.2:3000
// (10.0.2.2 = эмулятороос харагдах хостын localhost). http хаягийг зөвхөн
// debug build зөвшөөрнө — src/debug/res/xml/network_security_config.xml-ийг хар.
val geregeAppUrl: String =
    (project.findProperty("geregeAppUrl") as String? ?: "https://public.template.gerege.mn")
        .trim()
        .trimEnd('/')

android {
    namespace = "mn.gerege.temp"
    compileSdk = 35

    defaultConfig {
        applicationId = "mn.gerege.temp" // iOS-ийн bundle id-тай ижил
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"

        buildConfigField("String", "GEREGE_APP_URL", "\"$geregeAppUrl\"")
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }

    packaging {
        resources.excludes += setOf("/META-INF/{AL2.0,LGPL2.1}")
    }
}

// Гуравдагч сүлжээний/JSON сан ашиглахгүй — HttpURLConnection + org.json (Android-д
// суурилуулагдсан) л хангалттай. Хамаарал нь зөвхөн AndroidX/Compose.
dependencies {
    implementation("androidx.core:core-ktx:1.15.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.activity:activity-compose:1.9.3")

    val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-core")

    debugImplementation("androidx.compose.ui:ui-tooling")

    testImplementation("junit:junit:4.13.2")
    // JVM unit тестэд android.jar-ийн org.json нь stub тул жинхэнэ хэрэгжүүлэлт нэмнэ.
    testImplementation("org.json:json:20240303")
}
