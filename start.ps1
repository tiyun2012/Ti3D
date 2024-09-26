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
# make third party root directory
[string]$thirdPartyRoot=".\ThirdParty"
$message="checking the existing directory: $thirdPartyRoot"
Write-Host $message -ForegroundColor DarkGreen
if (-not(powershellModule\Test-FolderExistence -FolderName $thirdPartyRoot))
    {
        Write-Host "making  $thirdPartyRoot" -ForegroundColor Cyan
        Write-Output "Creating folder: $thirdPartyRoot"
        New-Item -ItemType Directory -Path $thirdPartyRoot
    }
else
{
    Write-Host "The directory already exists: $thirdPartyRoot" -ForegroundColor Green
}

#clean errorlog
powershellModule\Write-ProgressLog -Message '' -logFile $ErrorLog -clean $true

Write-Host "--- Checking Dear ImGui Module-----" -ForegroundColor Yellow
$imguiZip = "$thirdPartyRoot\imgui.zip"
$imguiUri = "https://github.com/ocornut/imgui/archive/refs/heads/master.zip"

# Check if the zip file already exists
$testImguiFileExisting = powershellModule\Test-FileExistence -FilePath $imguiZip
if ($testImguiFileExisting) 
{
    Write-Output "$imguiZip already exists in the current working directory"
} else 
{
    try
    {
        powershellModule\Invoke-WebFile -Url $imguiUri -DestinationPath $imguiZip
    }
    catch
    {
        Write-Error "Failed to download: $_"
        return
    }


}

# Extract specific Dear ImGui files
$imguiRoot = "$thirdPartyRoot\imgui"
$imguiList = @("imgui.h", "imgui.cpp", "backends/imgui_impl_glfw.cpp", "backends/imgui_impl_opengl3.cpp")
powershellModule\Expand-SpecificFilesFromZip -zipFilePath $imguiZip -destinationPath $imguiRoot -filesTracked $imguiList

# ------------------ Setup GLAD --------------------------------
Write-Host "--- Checking GLAD Module-----" -ForegroundColor Yellow

# Test existing  GLAD files
$gladRoot = "$thirdPartyRoot\gladLib"
$gladList = @("include/glad/glad.h", "src/glad.c")
$gladZip = "$thirdPartyRoot\glad.zip"
$gladUri = "https://github.com/Dav1dde/glad/archive/refs/heads/master.zip"
try 
{
    foreach ($gladFile in $gladList)
    {
        $relativeGladPath = Join-Path -Path $gladRoot -ChildPath $gladFile
        $testGladFileExisting=powershellModule\Test-FileExistence -FilePath $relativeGladPath
        if ($testGladFileExisting) 
        {
            Write-Host "$gladFile already exists in $gladRoot" -ForegroundColor Green
        } else  
        {
            throw "$gladFile is not available in $gladRoot"

        }
    }
}
catch 
{
    Write-Host " $_"
    # Check if the zip file already exists
    $testGladZipExisting = powershellModule\Test-FileExistence -FilePath $gladZip
    if ($testGladZipExisting) 
    {
        Write-Output "$gladZip already exists in the current working directory"
    } 
    else 
    {
        # Download the zip file
        if (powershellModule\Test-Uri -Uri $gladUri) 
        {
            powershellModule\Invoke-WebFile -Url $gladUri -DestinationPath $gladZip
        } 
        else 
        {
            powershellModule\Write-ProgressLog "Error: the link is not valid: $gladUri" -logFile $ErrorLog
            Write-Host "Error: the link is not valid: $gladUri" -ForegroundColor Red
            return
        }
        
    }
    Write-Host "--------1: try to Generate Cmake project using Cmake UI " -ForegroundColor Cyan
    Write-Host "--------2:Build Project Using Visual Studio " -ForegroundColor Cyan
    Write-Host "--------3:Copy $gladList to $Gladroot then run start.ps1 again" -ForegroundColor Cyan 
    return
}


# ------------------ Setup GLFW (already present) --------------------------------
Write-Host "--- Checking GLFW Module-----" -ForegroundColor Yellow
$glfwZip="$thirdPartyRoot\glfw-3.4.zip"
$uri="https://github.com/glfw/glfw/releases/download/3.4/glfw-3.4.bin.WIN64.zip"

# check zip file or download
$testZipfileExisting=powershellModule\Test-FileExistence -FilePath $glfwZip
if ($testZipfileExisting) {
    Write-Output "$glfwZip is existing in current working directory"
} else {
    try
    {
        powershellModule\Invoke-WebFile -Url $uri -DestinationPath $glfwZip
    }
    catch
    {
        Write-Error "Failed to download: $_"
        return
    }
}

# Extract the necessary GLFW files
$glfwRoot="$thirdPartyRoot\glfw-3.4"
$glfwList=@("include/GLFW/glfw3.h", "include/GLFW/glfw3native.h")
powershellModule\Expand-SpecificFilesFromZip -zipFilePath $glfwZip -destinationPath $glfwRoot -filesTracked $glfwList

# Extract GLFW library files for MinGW
$glfwList=@("lib-mingw-w64\\glfw3.dll", "lib-mingw-w64\\libglfw3.a", "lib-mingw-w64\\libglfw3dll.a")
powershellModule\Expand-SpecificFilesFromZip -zipFilePath $glfwZip -destinationPath $glfwRoot -filesTracked $glfwList

# Extract GLFW library files for Visual Studio
$glfwList=@("lib-vc2022\\glfw3.dll", "lib-vc2022\\glfw3.lib", "lib-vc2022\\glfw3dll.lib", "lib-vc2022\\glfw3_mt.lib")
powershellModule\Expand-SpecificFilesFromZip -zipFilePath $glfwZip -destinationPath $glfwRoot -filesTracked $glfwList

Write-Host "------------Settings successfully completed.---------------------------" -ForegroundColor Green




