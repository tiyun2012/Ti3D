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

# ------------------Setup  GLFW--------------------------------
Write-Host "--- Checking GLFW Module-----" -ForegroundColor Yellow
$glfwZip=".\glfw-3.4.zip"
$uri="https://github.com/glfw/glfw/releases/download/3.4/glfw-3.4.bin.WIN64.zip"
# check zip file or download
$testZipfileExisting=powershellModule\Test-FileExistence -FilePath $glfwZip
if ($testZipfileExisting)
    {
        Write-Output "$glfwZip is existing in current working directory"
    }
    else 
    {
        
        if(powershellModule\Test-Uri -Uri $uri)
        {
        
            powershellModule\Invoke-WebFile -Url $uri -DestinationPath $glfwZip
        }
        else
        {
            powershellModule\Write-ProgressLog "Error: the link is not a valid: $Uri " -logFile $ErrorLog
            Write-Host "Error: the link is not a valid: $uri" -ForegroundColor Red
            return
        }       <# Action when all if and elseif conditions are false #>
    }
#extract the necessary files from zip file
# -----FLFW InCLude -----
$glfwZip=".\glfw-3.4.zip"
$glfwRoot=".\glfw-3.4"
$glfwList=@("include\GLFW\glfw3.h","\include\GLFW\glfw3native.h")

powershellModule\Expand-SpecificFilesFromZip -zipFilePath $glfwZip -destinationPath $glfwRoot -filesTracked  $glfwList  
# for mingw
$glfwZip=".\glfw-3.4.zip"
$glfwRoot=".\glfw-3.4"
$glfwList=@("lib-mingw-w64\glfw3.dll","lib-mingw-w64\libglfw3.a","lib-mingw-w64\libglfw3dll.a")
powershellModule\Expand-SpecificFilesFromZip -zipFilePath $glfwZip -destinationPath $glfwRoot -filesTracked  $glfwList  
# -----------for visual studio
$glfwZip=".\glfw-3.4.zip"
$glfwRoot=".\glfw-3.4"
$glfwList=@("lib-vc2022\glfw3.dll","lib-vc2022\glfw3.lib","lib-vc2022\glfw3dll.lib","lib-vc2022\glfw3_mt.lib")
powershellModule\Expand-SpecificFilesFromZip -zipFilePath $glfwZip -destinationPath $glfwRoot -filesTracked  $glfwList  
Write-Host "------------Settings successfully completed.---------------------------" -ForegroundColor Green