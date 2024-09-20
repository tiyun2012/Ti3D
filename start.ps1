
# Import the module 
$modulePath = ".\powershellModule.psm1" 
try 
{
    Write-Progress -Activity "import port $modulePath : " -Status "start importing" -PercentComplete 0
    Import-Module $modulePath -Verbose  # powershellModule\Reset-Module #-ModulePath $modulePath
    Write-Progress -Activity "import port $modulePath : " -Status "done" -PercentComplete 100
}
catch 
{
    Write-Error "Failed to import module: $_"
    return
}
#------------check Python version------------------

$pythonVersion ="3.12"
$isPythonVersionInstalled=powershellModule\Get-PythonVersion -RequiredVersion $pythonVersion    
if($isPythonVersionInstalled -eq $true)
{
    Write-Output "Python $pythonVersion is available in your system."
}
else 
    {
        Write-Error "Please install Python $pythonVersion in your system."
        return powershellModule\Get-CallerInfo
    }


# -----------------Call the virtual environment creation function-----------------------
$venvName = ".venv"
&powershellModule\New-PythonVirtualEnvironment -venvName $venvName
#----------------install python module----------------
# Install the required modules
powershellModule\Install-RequiredPythonModules -EnvPath (".\$venvName") -RequirementsFile ".\requirements.txt" -ForceInstall $false

Write-Output "settings is successfully"    


