# Import the module
$modulePath = ".\\powershellModule.psm1"
$logFile = ".\setup.log"
$ErrorLog=".\Error.log"
# powershellModule\Reset-Module $modulePath
# import  powershellModule 
try {
    Write-Progress -Activity "1: -----importing module:  $modulePath" -Status "start importing" -PercentComplete 0
    Import-Module $modulePath -Verbose
    Write-Progress -Activity "importing module $modulePath" -Status "done" -PercentComplete 100
    }
catch {
    Write-Error "Failed to import module: $_"
    return
}
#clean errorlog
powershellModule\Write-ProgressLog -Message '' -logFile $ErrorLog -clean $true

Write-Host "--- Checking Dear ImGui Module-----" -ForegroundColor Yellow
$imguiZip = ".\\imgui.zip"
$imguiUri = "https://github.com/ocornut/imgui/archive/refs/heads/master.zip"

# Check if the zip file already exists
$testImguiFileExisting = powershellModule\Test-FileExistence -FilePath $imguiZip
if ($testImguiFileExisting) {
    Write-Output "$imguiZip already exists in the current working directory"
} else {
    # Download the zip file
    if (powershellModule\Test-Uri -Uri $imguiUri) {
        powershellModule\Invoke-WebFile -Url $imguiUri -DestinationPath $imguiZip
    } else {
        powershellModule\Write-ProgressLog "Error: the link is not valid: $imguiUri" -logFile $ErrorLog
        Write-Host "Error: the link is not valid: $imguiUri" -ForegroundColor Red
        return
    }
}

# Extract specific Dear ImGui files
$imguiRoot = ".\\imgui"
$imguiList = @("imgui.h", "imgui.cpp", "backends/imgui_impl_glfw.cpp", "backends/imgui_impl_opengl3.cpp")
powershellModule\Expand-SpecificFilesFromZip -zipFilePath $imguiZip -destinationPath $imguiRoot -filesTracked $imguiList

# ------------------ Setup GLAD --------------------------------
Write-Host "--- Checking GLAD Module-----" -ForegroundColor Yellow
$gladZip = ".\\glad.zip"
$gladUri = "https://github.com/Dav1dde/glad/archive/refs/heads/master.zip"

# Check if the zip file already exists
$testGladFileExisting = powershellModule\Test-FileExistence -FilePath $gladZip
if ($testGladFileExisting) {
    Write-Output "$gladZip already exists in the current working directory"
} else {
    # Download the zip file
    if (powershellModule\Test-Uri -Uri $gladUri) {
        powershellModule\Invoke-WebFile -Url $gladUri -DestinationPath $gladZip
    } else {
        powershellModule\Write-ProgressLog "Error: the link is not valid: $gladUri" -logFile $ErrorLog
        Write-Host "Error: the link is not valid: $gladUri" -ForegroundColor Red
        return
    }
}

# Extract specific GLAD files
$gladRoot = ".\\glad"
$gladList = @("include/glad/glad.h", "src/glad.c")
powershellModule\Expand-SpecificFilesFromZip -zipFilePath $gladZip -destinationPath $gladRoot -filesTracked $gladList

# ------------------ Setup GLFW (already present) --------------------------------
Write-Host "--- Checking GLFW Module-----" -ForegroundColor Yellow
$glfwZip=".\\glfw-3.4.zip"
$uri="https://github.com/glfw/glfw/releases/download/3.4/glfw-3.4.bin.WIN64.zip"

# check zip file or download
$testZipfileExisting=powershellModule\Test-FileExistence -FilePath $glfwZip
if ($testZipfileExisting) {
    Write-Output "$glfwZip is existing in current working directory"
} else {
    if (powershellModule\Test-Uri -Uri $uri) {
        powershellModule\Invoke-WebFile -Url $uri -DestinationPath $glfwZip
    } else {
        powershellModule\Write-ProgressLog "Error: the link is not a valid: $uri " -logFile $ErrorLog
        Write-Host "Error: the link is not a valid: $uri" -ForegroundColor Red
        return
    }
}

# Extract the necessary GLFW files
$glfwRoot=".\\glfw-3.4"
$glfwList=@("include/GLFW/glfw3.h", "include/GLFW/glfw3native.h")
powershellModule\Expand-SpecificFilesFromZip -zipFilePath $glfwZip -destinationPath $glfwRoot -filesTracked $glfwList

# Extract GLFW library files for MinGW
$glfwList=@("lib-mingw-w64\\glfw3.dll", "lib-mingw-w64\\libglfw3.a", "lib-mingw-w64\\libglfw3dll.a")
powershellModule\Expand-SpecificFilesFromZip -zipFilePath $glfwZip -destinationPath $glfwRoot -filesTracked $glfwList

# Extract GLFW library files for Visual Studio
$glfwList=@("lib-vc2022\\glfw3.dll", "lib-vc2022\\glfw3.lib", "lib-vc2022\\glfw3dll.lib", "lib-vc2022\\glfw3_mt.lib")
powershellModule\Expand-SpecificFilesFromZip -zipFilePath $glfwZip -destinationPath $glfwRoot -filesTracked $glfwList

Write-Host "------------Settings successfully completed.---------------------------" -ForegroundColor Green




