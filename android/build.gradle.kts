allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    configurations.configureEach {
        resolutionStrategy {
            force("androidx.glance:glance:1.1.1")
            force("androidx.glance:glance-appwidget:1.1.1")
            force("androidx.work:work-runtime:2.8.1")
            force("androidx.work:work-runtime-ktx:2.8.1")
            force("org.jetbrains.kotlin:kotlin-stdlib:1.8.22")
            force("org.jetbrains.kotlin:kotlin-stdlib-common:1.8.22")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.8.22")
            force("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.22")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
            force("org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.7.3")
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
