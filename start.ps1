# Log file to track which steps have been completed
$logFile = ".\\setup.log"

# Function to log progress
function Write-ProgressLog {
    param(
        [string]$message
    )
    Add-Content -Path $logFile -Value $message
}

# Function to check if a step has been completed
function Test-StepCompleted {
    param(
        [string]$step
    )
    return Select-String -Path $logFile -Pattern $step -Quiet
}

# Import the module
$modulePath = ".\\powershellModule.psm1"

if (-not (Test-StepCompleted "module_imported")) {
    try {
        Write-Progress -Activity "importing module $modulePath" -Status "start importing" -PercentComplete 0
        Import-Module $modulePath -Verbose
        Write-Progress -Activity "importing module $modulePath" -Status "done" -PercentComplete 100
        Write-ProgressLog "module_imported"
    }
    catch {
        Write-Error "Failed to import module: $_"
        return
    }
}
else {
    Write-Output "Module already imported, skipping this step."
}

# Check Python version
$pythonVersion = "3.12"

if (-not (Test-StepCompleted "python_version_checked")) {
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

if (-not (Test-StepCompleted "venv_created")) {
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

Write-Output "Settings successfully completed."
