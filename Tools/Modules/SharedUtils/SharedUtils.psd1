@{
    RootModule        = 'SharedUtils.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'b4e8f2a1-3c5d-4e6f-8a9b-0c1d2e3f4a5b'
    Author            = 'Microsoft Corporation'
    Description       = 'Shared utility functions for winget-pkgs Tools scripts'
    PowerShellVersion = '5.0'
    FunctionsToExport = @(
        'Initialize-RequiredModule'
        'Get-ManifestsFolder'
        'Invoke-FileCleanup'
    )
    CmdletsToExport   = @()
    VariablesToExport  = @()
    AliasesToExport    = @()
}
