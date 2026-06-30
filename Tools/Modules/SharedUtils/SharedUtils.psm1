#Requires -Version 5

class UnmetDependencyException : Exception {
    UnmetDependencyException([string] $message) : base($message) {}
    UnmetDependencyException([string] $message, [Exception] $exception) : base($message, $exception) {}
}

function Initialize-RequiredModule {
    <#
    .SYNOPSIS
        Ensures a PowerShell module is installed and available.
    .PARAMETER Name
        The name of the module to install.
    .PARAMETER MinimumVersion
        Optional minimum version for the module.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $false)]
        [string] $MinimumVersion
    )

    if (-not(Get-Module -ListAvailable -Name $Name)) {
        try {
            Write-Verbose "PowerShell module '$Name' was not found. Attempting to install it. . ."
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser
            $installParams = @{
                Name       = $Name
                Force      = $true
                Repository = 'PSGallery'
                Scope      = 'CurrentUser'
            }
            if ($MinimumVersion) {
                $installParams['MinimumVersion'] = $MinimumVersion
            }
            Install-Module @installParams
        } catch {
            throw [UnmetDependencyException]::new("'$Name' unable to be installed successfully", $_.Exception)
        } finally {
            if (-not(Get-Module -ListAvailable -Name $Name)) {
                throw [UnmetDependencyException]::new("'$Name' is not found")
            }
            Write-Verbose "PowerShell module '$Name' was installed successfully"
        }
    }
}

function Get-ManifestsFolder {
    <#
    .SYNOPSIS
        Resolves the path to the manifests folder relative to the Tools directory.
    .PARAMETER ScriptRoot
        The $PSScriptRoot of the calling script.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string] $ScriptRoot
    )

    if (Test-Path -Path "$ScriptRoot\..\manifests") {
        return (Resolve-Path "$ScriptRoot\..\manifests").Path
    } else {
        return (Resolve-Path '.\').Path
    }
}

function Invoke-FileCleanup {
    <#
    .SYNOPSIS
        Removes files and folders from the file system.
    .PARAMETER FilePaths
        List of paths to remove.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [AllowEmptyCollection()]
        [String[]] $FilePaths
    )
    if (!$FilePaths) { return }
    foreach ($path in $FilePaths) {
        Write-Debug "Removing $path"
        if (Test-Path $path) { Remove-Item -Path $path -Recurse }
        else { Write-Warning "Could not remove $path as it does not exist" }
    }
}

Export-ModuleMember -Function @(
    'Initialize-RequiredModule'
    'Get-ManifestsFolder'
    'Invoke-FileCleanup'
)
