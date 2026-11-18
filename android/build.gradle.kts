allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

fun fixCompileSdk(p: Project) {
    val android = p.extensions.findByName("android") ?: return
    for (method in android.javaClass.methods) {
        if (method.name in listOf("setCompileSdkVersion", "compileSdkVersion", "setCompileSdk") && method.parameterCount == 1) {
            try {
                val paramType = method.parameterTypes[0]
                if (paramType == Int::class.javaPrimitiveType || paramType == Integer::class.java) {
                    method.invoke(android, 36)
                }
            } catch (_: Exception) {
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
    if (project.state.executed) {
        fixCompileSdk(project)
    } else {
        project.afterEvaluate {
            fixCompileSdk(project)
        }
    }
}

tasks.register<Delete>("clean") {
    description = "Deletes the build directory"
    delete(rootProject.layout.buildDirectory)
}

