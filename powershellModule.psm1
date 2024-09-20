function Test-FolderExistence {
    param (
        [string]$FolderName
    )

    # Get the current directory
    $CurrentDirectory = Get-Location

    # Combine the current directory path with the folder name
    $FolderPath = Join-Path -Path $CurrentDirectory -ChildPath $FolderName

    # Check if the folder exists
    if (Test-Path -Path $FolderPath -PathType Container) {
        return $true
    } else {
        return $false
    }
}
function New-PythonVirtualEnvironment {
    param (
        [string]$venvName=".venv"
    )

    # Step 1: Start the virtual environment creation process
    Write-Progress -Activity "Setting up Python Virtual Environment" -Status "Initializing..." -PercentComplete 0

    # Step 2: Check if the folder for the virtual environment exists
    Write-Progress -Activity "Setting up Python Virtual Environment" -Status "Checking folder existence..." -PercentComplete 20
    if (-not (Test-FolderExistence -FolderName $venvName)) {
        New-Item -ItemType Directory -Path $venvName
    }

    # Step 3: Create the virtual environment
    Write-Progress -Activity "Setting up Python Virtual Environment" -Status "Creating virtual environment..." -PercentComplete 50
    & "python" -m venv $venvName

    # Step 4: Install dependencies (optional step)
    Write-Progress -Activity "Setting up Python Virtual Environment" -Status "Installing dependencies..." -PercentComplete 75
    & ".\$venvName\Scripts\pip.exe" install --upgrade pip

    # Step 5: Finalize the process
    Write-Progress -Activity "Setting up Python Virtual Environment" -Status "Finalizing..." -PercentComplete 100

    Write-Output "Virtual environment setup completed at $venvName."
}

# Function to reload the module
function Reset-Module {
    param (
        [string]$ModulePath=(Join-Path -Path (Get-Location) -ChildPath "powershellModule.psm1")
    )

    # Validate that ModulePath is not null or empty
    if ([string]::IsNullOrWhiteSpace($ModulePath)) {
        Write-Error "ModulePath cannot be null or empty."
        return $false
    }

    # Get the module name from the path
    $moduleName = [System.IO.Path]::GetFileNameWithoutExtension($ModulePath)

    # Validate that moduleName is not null or empty
    if ([string]::IsNullOrWhiteSpace($moduleName)) {
        Write-Error "Failed to determine the module name from the path '$ModulePath'."
        return $false
    }

    # Remove the existing module if loaded
    if (Get-Module -Name $moduleName) {
        Remove-Module -Name $moduleName -Force
        Write-Output "Module '$moduleName' removed successfully."
    }

    # Import the module
    try {
        Import-Module $ModulePath -Force
        Write-Output "Module '$moduleName' imported successfully."
        return $true
    } catch {
        Write-Error "Failed to import module '$moduleName': $_"
        return $false
    }
}

function Get-CallerInfo {
    $callStack = Get-PSCallStack
    if ($callStack.Count -gt 1) {
        $callerFrame = $callStack[1]
        return @{
            errorInfo="the starting breaks at line $($callerFrame.ScriptLineNumber) of the file $($callerFrame.ScriptName)"
            # ScriptName = $callerFrame.ScriptName
            # LineNumber = $callerFrame.ScriptLineNumber
        }
    } else {
        return $null
    }
}

function Get-PythonVersion {
    param (
        [string]$RequiredVersion,
        [string]$PythonPath = $(Get-Command python | Select-Object -ExpandProperty Source)
    )

    # Check if Python is available
    if (-not (Test-Path -Path $PythonPath)) {
        Write-Error "Python executable not found. Please provide a valid Python path."
        return $false
    }

    # Get the Python version $versionOutput='Python 4.12.0'
    $versionOutput = & $PythonPath --version 2>&1
    $versionPattern = "Python\s+(\d+\.\d+)\.\d+"
    if ($versionOutput -match $versionPattern) {
        $installedVersion = $matches[1]
        if ($installedVersion -eq $RequiredVersion) {
            return $true
        } else {
            Write-Output "Installed Python version is $installedVersion, but $RequiredVersion is required."
            return $false
        }
    } else {
        Write-Error "Failed to determine Python version."
        return $false
    }
}

function Install-RequiredPythonModules {
    param (
        [string]$EnvPath,
        [string]$RequirementsFile = ".\requirements.txt",
        [switch]$ForceInstall = $false
    )

    # Step 1: Read the requirements.txt file
    if (-not (Test-Path $RequirementsFile)) {
        Write-Error "Requirements file not found at $RequirementsFile"
        return
    }
    $modules = Get-Content -Path $RequirementsFile

    # Step 2: Activate the virtual environment
    $activateScript = "$EnvPath\Scripts\Activate.ps1"
    if (-not (Test-Path $activateScript)) {
        Write-Error "Virtual environment activation script not found at $activateScript"
        return
    }
    & $activateScript

    # Step 3: Check and install missing modules
    foreach ($module in $modules) {
        Write-Progress -Activity "Checking module $module" -Status "Checking if $module is installed..." -PercentComplete 0

        $isModuleInstalled = & "$EnvPath\Scripts\pip.exe" show $module

        if (-not $isModuleInstalled -or $ForceInstall) {
            Write-Progress -Activity "Installing $module" -Status "Installing $module..." -PercentComplete 50
            & "$EnvPath\Scripts\pip.exe" install $module
        } else {
            Write-Host "$module is already installed."
        }

        Write-Progress -Activity "Module Check Complete" -Status "$module check complete" -PercentComplete 100
    }

    Write-Host "All required modules are installed."
}
