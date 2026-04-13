buildscript {
    val agp_version by extra("8.10.1")
    val agp_version1 by extra("8.10.1")
}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = File(rootProject.projectDir.parentFile, "build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    if (project.name == "app") {
        val newSubprojectBuildDir = File(newBuildDir, project.name)
        project.layout.buildDirectory.set(newSubprojectBuildDir)
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
