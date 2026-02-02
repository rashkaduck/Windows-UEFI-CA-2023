# Secure Boot CA 2023 – Updated Detection Script

# 1. Secure Boot enabled?
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

# 2. Check DB for CA 2023 certificate
$SBCA2023 = "NOTPresent"
try {
    $db = Get-SecureBootUEFI -Name db -ErrorAction Stop
    $dbText = [System.Text.Encoding]::ASCII.GetString($db.Bytes)
    if ($dbText -match "Windows UEFI CA 2023") {
        $SBCA2023 = "Present"
    }
}
catch {}

# 3. Check servicing registry
$ServicingKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing"
$UEFIStatus = "UNKNOWN"
$Capable = 0

if (Test-Path $ServicingKey) {
    $props = Get-ItemProperty -Path $ServicingKey -ErrorAction SilentlyContinue
    $UEFIStatus = $props.UEFICA2023Status
    $Capable = $props.WindowsUEFICA2023Capable
}

# 4. Check Event ID 1808 (optional)
$Event1808 = "NotPresent"
try {
    $evt = Get-WinEvent -FilterHashtable @{LogName='System'; ID=1808} -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($evt) { $Event1808 = "Present" }
}
catch {}

# 5. Final compliance logic
# Capable = 2 means: CA2023 in DB AND system booted with 2023-signed boot manager
if (
    ($SBCA2023 -eq "Present" -or $Capable -eq 2) -and
    $UEFIStatus -eq "Updated"
) {
    Write-Output "COMPLIANT: CA2023 present or Capable=2; Status=Updated"
    exit 0
}

Write-Output "NON-COMPLIANT: CA2023=$SBCA2023;Status=$UEFIStatus;Capable=$Capable;Event1808=$Event1808"
exit 1
