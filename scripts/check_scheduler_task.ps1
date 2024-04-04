$taskName = "AutoUpdateAppTaskName"

try {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    Write-Output "Task '$taskName' already exists: True"
} catch {
    Write-Output "Task '$taskName' does not exist: False"    
}