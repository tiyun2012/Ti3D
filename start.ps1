# Import the module
$modulePath = ".\\powershellModule.psm1"
$logFile = ".\setup.log"
# powershellModule\Reset-Module $modulePath
# import  powershellModule 
try {
    Write-Progress -Activity "1: -----importing module:  $modulePath" -Status "start importing" -PercentComplete 0
    Import-Module $modulePath -Verbose
    Write-Progress -Activity "importing module $modulePath" -Status "done" -PercentComplete 100
    Write-ProgressLog "module_imported"
}
catch {
    Write-Error "Failed to import module: $_"
    return
}

<# 
# Check Python version
$pythonVersion = "3.12"

if (-not (Test-StepCompleted -step "python_version_checked" -logFile $logFile)) {
    $isPythonVersionInstalled = powershellModule\Get-PythonVersion -RequiredVersion $pythonVersion
    if ($isPythonVersionInstalled -eq $true) {
        Write-Output "Python $pythonVersion is available in your system."
        Write-ProgressLog "python_version_checked"
    }
    else {
        Write-Error "Please install Python $pythonVersion in your system."
        return
    }
}
else {
    Write-Output "Python version already checked, skipping this step."
}

# Create virtual environment
$venvName = ".venv"

if (-not (Test-StepCompleted "venv_created" -logFile $logFile)) {
    &powershellModule\New-PythonVirtualEnvironment -venvName $venvName
    Write-ProgressLog "venv_created"
}
else {
    Write-Output "Virtual environment already created, skipping this step."
}

# Install required Python modules
if (-not (Test-StepCompleted "modules_installed")) {
    powershellModule\Install-RequiredPythonModules -EnvPath (".\\$venvName") -RequirementsFile ".\\requirements.txt" -ForceInstall $false
    Write-ProgressLog "modules_installed"
}
else {
    Write-Output "Required Python modules already installed, skipping this step."
}
 #>
Write-Output "Settings successfully completed."
