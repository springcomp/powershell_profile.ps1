$Env:JAVA_HOME="C:\Program Files\Java\jdk-15.0.2"

$Env:M2_HOME="C:\opt\apache-maven-3.6.3"
$Env:MAVEN_HOME=$Env:M2_HOME
$Env:M2="$Env:M2_HOME\bin"

"$Env:JAVA_HOME\bin", `
"$Env:M2" `
    | Add-DirectoryToPath
