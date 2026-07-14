param(
    [string]$BackupDir = (Join-Path $env:TEMP 'disable-intel-dpst'),
    [switch]$NoSelfElevate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Log {
    param([string]$Message)

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -LiteralPath $script:LogPath -Value "[$stamp] $Message"
    Write-Host $Message
}

function Get-RegistryPropertyValue {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Properties,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [object]$Default = $null
    )

    $property = $Properties.PSObject.Properties[$Name]
    if ($property) {
        return $property.Value
    }

    return $Default
}

if (-not (Test-IsAdministrator)) {
    if ($NoSelfElevate) {
        throw 'This script must run as administrator to update the protected Intel graphics registry key.'
    }

    $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
    $arguments = @(
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        "`"$scriptPath`"",
        '-BackupDir',
        "`"$BackupDir`"",
        '-NoSelfElevate'
    )

    Start-Process -FilePath 'powershell.exe' -ArgumentList $arguments -Verb RunAs -Wait
    exit
}

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$script:LogPath = Join-Path $BackupDir 'disable-intel-dpst.log'

$displayClassPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}'
$intelAdapters = Get-ChildItem -LiteralPath $displayClassPath -ErrorAction Stop |
    Where-Object { $_.PSChildName -match '^\d{4}$' } |
    ForEach-Object {
        $props = Get-ItemProperty -LiteralPath $_.PSPath
        [pscustomobject]@{
            Item = $_
            Properties = $props
            DriverDesc = Get-RegistryPropertyValue -Properties $props -Name 'DriverDesc' -Default ''
            ProviderName = Get-RegistryPropertyValue -Properties $props -Name 'ProviderName' -Default ''
        }
    } |
    Where-Object {
        $_.DriverDesc -like '*Intel*Graphics*' -or
        $_.DriverDesc -like '*Intel*UHD*' -or
        $_.ProviderName -like '*Intel*'
    }

if (-not $intelAdapters) {
    throw 'No Intel graphics adapter registry key was found.'
}

Write-Log 'Starting Intel DPST battery color fix.'

foreach ($adapter in $intelAdapters) {
    $key = $adapter.Item
    $backupFile = Join-Path $BackupDir ("intel-graphics-{0}-before-dpst.reg" -f $key.PSChildName)
    & reg.exe export $key.Name $backupFile /y | Out-Null

    $featureTestControl = 0
    $featureTestControlValue = Get-RegistryPropertyValue -Properties $adapter.Properties -Name 'FeatureTestControl' -Default 0
    if ($null -ne $featureTestControlValue) {
        $featureTestControl = [int]$featureTestControlValue
    }

    $newFeatureTestControl = $featureTestControl -bor 0x10

    New-ItemProperty -LiteralPath $key.PSPath -Name FeatureTestControl -PropertyType DWord -Value $newFeatureTestControl -Force | Out-Null
    New-ItemProperty -LiteralPath $key.PSPath -Name PowerDpstAggressivenessLevel -PropertyType Binary -Value ([byte[]](0, 0, 0, 0)) -Force | Out-Null

    Write-Log ("Updated {0}: FeatureTestControl 0x{1:X} -> 0x{2:X}; PowerDpstAggressivenessLevel -> 0" -f $key.PSChildName, $featureTestControl, $newFeatureTestControl)
    Write-Log "Backup exported to $backupFile"
}

$powerCfgSettings = @(
    @('/setdcvalueindex', 'SCHEME_CURRENT', 'SUB_VIDEO', 'ADVANCEDCOLORQUALITYBIAS', '1'),
    @('/setdcvalueindex', 'SCHEME_CURRENT', 'SUB_VIDEO', 'ADAPTBRIGHT', '0'),
    @('/setdcvalueindex', 'SCHEME_CURRENT', 'SUB_VIDEO', 'VIDEOADAPT', '0')
)

foreach ($setting in $powerCfgSettings) {
    $output = & powercfg.exe @setting 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Warning: powercfg $($setting -join ' ') failed: $output"
    }
}

& powercfg.exe /S SCHEME_CURRENT | Out-Null

Write-Log 'Finished. Press Win+Ctrl+Shift+B or reboot if the display image does not refresh immediately.'
