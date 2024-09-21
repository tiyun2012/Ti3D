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
Write-Output "Settings successfully completed."
