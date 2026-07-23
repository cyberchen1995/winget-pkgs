BeforeAll {
    # Import the VirtualTerminal module first since YamlCreate depends on it
    $ModulePath = Split-Path -Parent $PSCommandPath
    $VTModulePath = Join-Path (Split-Path -Parent $ModulePath) 'VirtualTerminal' 'VirtualTerminal.psd1'
    Import-Module $VTModulePath -Force

    # Import the module to test
    Import-Module (Join-Path $ModulePath 'YamlCreate.psd1') -Force

    # Create stub functions for external dependencies that may not be available
    $Script:AddedGetMSITable = $false
    if (-not (Get-Command Get-MSITable -ErrorAction SilentlyContinue)) {
        function Global:Get-MSITable {
            param([string]$Path)
            return $null
        }
        $Script:AddedGetMSITable = $true
    }

    $Script:AddedGetMSIProperty = $false
    if (-not (Get-Command Get-MSIProperty -ErrorAction SilentlyContinue)) {
        function Global:Get-MSIProperty {
            param([string]$Path, [string]$Property)
            return $null
        }
        $Script:AddedGetMSIProperty = $true
    }

    $Script:AddedGetWin32ModuleResource = $false
    if (-not (Get-Command Get-Win32ModuleResource -ErrorAction SilentlyContinue)) {
        function Global:Get-Win32ModuleResource {
            param([string]$Path, [switch]$DontLoadResource)
            return @()
        }
        $Script:AddedGetWin32ModuleResource = $true
    }
}

AfterAll {
    if ($Script:AddedGetMSITable) { Remove-Item Function:\Get-MSITable -ErrorAction SilentlyContinue }
    if ($Script:AddedGetMSIProperty) { Remove-Item Function:\Get-MSIProperty -ErrorAction SilentlyContinue }
    if ($Script:AddedGetWin32ModuleResource) { Remove-Item Function:\Get-Win32ModuleResource -ErrorAction SilentlyContinue }
}

Describe 'YamlCreate Parent Module' {
    Context 'Module Import' {
        It 'Should import the module successfully' {
            Get-Module 'YamlCreate' | Should -Not -BeNullOrEmpty
        }

        It 'Should have the correct module version' {
            (Get-Module 'YamlCreate').Version | Should -Be '0.0.1'
        }

        It 'Should have the correct GUID' {
            (Get-Module 'YamlCreate').Guid | Should -Be '7e3c36ac-436b-41fa-a89d-1deb466096cc'
        }
    }

    Context 'Sub-Module Loading' {
        It 'Should load the YamlCreate.InstallerDetection sub-module' {
            Get-Module 'YamlCreate.InstallerDetection' | Should -Not -BeNullOrEmpty
        }

        It 'Should load the YamlCreate.Menuing sub-module' {
            Get-Module 'YamlCreate.Menuing' | Should -Not -BeNullOrEmpty
        }

        It 'Should load the VirtualTerminal dependency module' {
            Get-Module 'VirtualTerminal' | Should -Not -BeNullOrEmpty
        }
    }

    Context 'InstallerDetection Functions Available' {
        It 'Should make InstallerDetection functions available globally' {
            $ExpectedFunctions = @(
                'Get-OffsetBytes'
                'Get-PESectionTable'
                'Test-IsZip'
                'Test-IsMsix'
                'Test-IsMsi'
                'Test-IsWix'
                'Test-IsNullsoft'
                'Test-IsInno'
                'Test-IsBurn'
                'Test-IsFont'
                'Resolve-InstallerType'
            )
            foreach ($FunctionName in $ExpectedFunctions) {
                Get-Command $FunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'Menuing Functions Available' {
        It 'Should make Menuing functions available globally' {
            $ExpectedFunctions = @(
                'Get-Keypress'
                'Resolve-Keypress'
            )
            foreach ($FunctionName in $ExpectedFunctions) {
                Get-Command $FunctionName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context 'VirtualTerminal Variables Available' {
        It 'Should make VirtualTerminal variables accessible' {
            $ExpectedVars = @(
                'vtBold'
                'vtForegroundRed'
                'vtForegroundDefault'
                'vtBackgroundDefault'
            )
            foreach ($VarName in $ExpectedVars) {
                { Get-Variable $VarName -ErrorAction Stop } | Should -Not -Throw
            }
        }
    }

    Context 'Menuing Variables Available' {
        It 'Should make Numeric variables accessible' {
            foreach ($i in 0..9) {
                { Get-Variable "Numeric$i" -ErrorAction Stop } | Should -Not -Throw
            }
        }
    }

    Context 'Cross-Module Integration' {
        It 'Should allow InstallerDetection functions to work after parent import' {
            $ByteArray = [byte[]](0x01, 0x02, 0x03, 0x04, 0x05)
            $Result = Get-OffsetBytes -ByteArray $ByteArray -Offset 1 -Length 2
            $Result | Should -Be @(0x02, 0x03)
        }

        It 'Should allow font detection after parent import' {
            $TempFile = New-TemporaryFile
            $TTFHeader = [byte[]](0x00, 0x01, 0x00, 0x00) + ([byte[]](0x00) * 100)
            Set-Content -Path $TempFile.FullName -Value $TTFHeader -AsByteStream
            $Result = Test-IsFont -Path $TempFile.FullName
            $Result | Should -Be $true
            Remove-Item $TempFile.FullName -Force
        }

        It 'Should allow zip detection after parent import' {
            $TempFile = New-TemporaryFile
            Set-Content -Path $TempFile.FullName -Value 'Not a zip file'
            $Result = Test-IsZip -Path $TempFile.FullName
            $Result | Should -Be $false
            Remove-Item $TempFile.FullName -Force
        }
    }
}
