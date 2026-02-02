# Secure Boot CA 2023 – Remediation Script (Optimized)

# 1. Ensure admin
$IsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Output "NON-COMPLIANT: Must run as admin"
    exit 1
}

# 2. Secure Boot enabled?
try {
    if (-not (Confirm-SecureBootUEFI)) {
        Write-Output "NON-COMPLIANT: Secure Boot disabled"
        exit 1
    }
}
catch {
    Write-Output "NON-COMPLIANT: Secure Boot unsupported"
    exit 1
}

# 3. Registry paths
$SecureBootKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot"
$ServicingKey  = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing"
$ValueName     = "AvailableUpdates"
$TriggerValue  = 0x5944

# 4. Check if already updated
$AlreadyUpdated = $false
$Capable = 0
$Status  = "UNKNOWN"

if (Test-Path $ServicingKey) {
    $props = Get-ItemProperty -Path $ServicingKey -ErrorAction SilentlyContinue
    $Capable = $props.WindowsUEFICA2023Capable
    $Status  = $props.UEFICA2023Status

    if ($Capable -eq 2 -and $Status -eq "Updated") {
        $AlreadyUpdated = $true
    }
}

if ($AlreadyUpdated) {
    Write-Output "COMPLIANT: Already updated (Capable=2, Status=Updated)"
    exit 0
}

# 5. Trigger update only if needed
if (Test-Path $SecureBootKey) {
    $current = (Get-ItemProperty -Path $SecureBootKey -Name $ValueName -ErrorAction SilentlyContinue).$ValueName

    if ($current -eq $null -or $current -eq 0) {
        Set-ItemProperty -Path $SecureBootKey -Name $ValueName -Type DWord -Value $TriggerValue -Force
        Write-Output "Triggered Secure Boot CA 2023 update via registry"
    }
    else {
        Write-Output "Update already staged (AvailableUpdates=$current)"
    }
}

# 6. Start Microsoft Secure Boot update task
$TaskName = "Secure-Boot-Update"
$TaskPath = "\Microsoft\Windows\PI\"

try {
    $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction Stop
    Start-ScheduledTask -InputObject $task
    Write-Output "Started Secure-Boot-Update scheduled task"
}
catch {
    Write-Output "Scheduled task not found or failed to start"
}

exit 0
