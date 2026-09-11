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
    project.evaluationDependsOn(":app")
}

// Override all plugin subprojects (including permission_handler_android)
// to compile with SDK 37 instead of lower versions
subprojects {
    val configureSdk: Project.() -> Unit = {
        if (project.name != "app") {
            project.extensions.findByName("android")?.let { ext ->
                try {
                    val compileSdkMethod = ext.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                    compileSdkMethod.invoke(ext, 37)
                } catch (_: Exception) {
                    try {
                        val setCompileSdkMethod = ext.javaClass.getMethod("setCompileSdk", java.lang.Integer::class.java)
                        setCompileSdkMethod.invoke(ext, 37)
                    } catch (_: Exception) {}
                }
            }
        }
    }
    if (state.executed) {
        configureSdk()
    } else {
        afterEvaluate {
            configureSdk()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}