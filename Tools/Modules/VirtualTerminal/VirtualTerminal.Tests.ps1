BeforeAll {
    # Import the module to test
    $ModulePath = Split-Path -Parent $PSCommandPath
    Import-Module (Join-Path $ModulePath 'VirtualTerminal.psd1') -Force
}

Describe 'VirtualTerminal Module' {
    Context 'Module Import' {
        It 'Should import the module successfully' {
            Get-Module 'VirtualTerminal' | Should -Not -BeNullOrEmpty
        }

        It 'Should export the Initialize-VirtualTerminalSequence function' {
            $ExportedFunctions = (Get-Module 'VirtualTerminal').ExportedFunctions.Keys
            $ExportedFunctions | Should -Contain 'Initialize-VirtualTerminalSequence'
        }
    }

    Context 'Exported Variables' {
        It 'Should export foreground color variables' {
            $ExportedVars = (Get-Module 'VirtualTerminal').ExportedVariables.Keys
            $ExpectedForegroundVars = @(
                'vtForegroundBlack'
                'vtForegroundRed'
                'vtForegroundGreen'
                'vtForegroundYellow'
                'vtForegroundBlue'
                'vtForegroundMagenta'
                'vtForegroundCyan'
                'vtForegroundWhite'
                'vtForegroundDefault'
            )
            foreach ($Var in $ExpectedForegroundVars) {
                $ExportedVars | Should -Contain $Var
            }
        }

        It 'Should export background color variables' {
            $ExportedVars = (Get-Module 'VirtualTerminal').ExportedVariables.Keys
            $ExpectedBackgroundVars = @(
                'vtBackgroundBlack'
                'vtBackgroundRed'
                'vtBackgroundGreen'
                'vtBackgroundYellow'
                'vtBackgroundBlue'
                'vtBackgroundMagenta'
                'vtBackgroundCyan'
                'vtBackgroundWhite'
                'vtBackgroundDefault'
            )
            foreach ($Var in $ExpectedBackgroundVars) {
                $ExportedVars | Should -Contain $Var
            }
        }

        It 'Should export text formatting variables' {
            $ExportedVars = (Get-Module 'VirtualTerminal').ExportedVariables.Keys
            $ExpectedFormattingVars = @(
                'vtBold'
                'vtNotBold'
                'vtUnderline'
                'vtNotUnderline'
                'vtNegative'
                'vtPositive'
            )
            foreach ($Var in $ExpectedFormattingVars) {
                $ExportedVars | Should -Contain $Var
            }
        }

        It 'Should export bright foreground color variables' {
            $ExportedVars = (Get-Module 'VirtualTerminal').ExportedVariables.Keys
            $ExpectedBrightFgVars = @(
                'vtForegroundBrightBlack'
                'vtForegroundBrightRed'
                'vtForegroundBrightGreen'
                'vtForegroundBrightYellow'
                'vtForegroundBrightBlue'
                'vtForegroundBrightMagenta'
                'vtForegroundBrightCyan'
                'vtForegroundBrightWhite'
            )
            foreach ($Var in $ExpectedBrightFgVars) {
                $ExportedVars | Should -Contain $Var
            }
        }

        It 'Should export bright background color variables' {
            $ExportedVars = (Get-Module 'VirtualTerminal').ExportedVariables.Keys
            $ExpectedBrightBgVars = @(
                'vtBackgroundBrightRed'
                'vtBackgroundBrightGreen'
                'vtBackgroundBrightYellow'
                'vtBackgroundBrightBlue'
                'vtBackgroundBrightMagenta'
                'vtBackgroundBrightCyan'
                'vtBackgroundBrightWhite'
            )
            foreach ($Var in $ExpectedBrightBgVars) {
                $ExportedVars | Should -Contain $Var
            }
        }
    }
}

Describe 'Initialize-VirtualTerminalSequence' {
    Context 'VT sequence generation' {
        It 'Should produce a string containing the ESC character and operation code when VT is supported' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            $Result = 1 | Initialize-VirtualTerminalSequence
            if ($vtSupported) {
                $Result | Should -Be "$([char]0x001B)[1m"
            } else {
                $Result | Should -BeNullOrEmpty
            }
        }

        It 'Should produce correct sequence for bold (code 1)' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            if ($vtSupported) {
                $Result = 1 | Initialize-VirtualTerminalSequence
                $Result | Should -Be "$([char]0x001B)[1m"
            } else {
                Set-ItResult -Skipped -Because 'VirtualTerminal is not supported in this host'
            }
        }

        It 'Should produce correct sequence for underline (code 4)' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            if ($vtSupported) {
                $Result = 4 | Initialize-VirtualTerminalSequence
                $Result | Should -Be "$([char]0x001B)[4m"
            } else {
                Set-ItResult -Skipped -Because 'VirtualTerminal is not supported in this host'
            }
        }

        It 'Should produce correct sequence for foreground red (code 31)' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            if ($vtSupported) {
                $Result = 31 | Initialize-VirtualTerminalSequence
                $Result | Should -Be "$([char]0x001B)[31m"
            } else {
                Set-ItResult -Skipped -Because 'VirtualTerminal is not supported in this host'
            }
        }

        It 'Should produce correct sequence for background blue (code 44)' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            if ($vtSupported) {
                $Result = 44 | Initialize-VirtualTerminalSequence
                $Result | Should -Be "$([char]0x001B)[44m"
            } else {
                Set-ItResult -Skipped -Because 'VirtualTerminal is not supported in this host'
            }
        }

        It 'Should return null or empty when VT is not supported' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            if (-not $vtSupported) {
                $Result = 1 | Initialize-VirtualTerminalSequence
                $Result | Should -BeNullOrEmpty
            } else {
                Set-ItResult -Skipped -Because 'VirtualTerminal is supported; cannot test unsupported path'
            }
        }

        It 'Should handle multiple values piped through the filter' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            $Results = @(1, 4, 31) | Initialize-VirtualTerminalSequence
            if ($vtSupported) {
                $Results.Count | Should -Be 3
                $Results[0] | Should -Be "$([char]0x001B)[1m"
                $Results[1] | Should -Be "$([char]0x001B)[4m"
                $Results[2] | Should -Be "$([char]0x001B)[31m"
            } else {
                $Results | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Variable values match expected VT codes' {
        It 'Should have correct code mapping for vtBold' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            $Expected = if ($vtSupported) { "$([char]0x001B)[1m" } else { $null }
            $vtBold | Should -Be $Expected
        }

        It 'Should have correct code mapping for vtNotBold' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            $Expected = if ($vtSupported) { "$([char]0x001B)[22m" } else { $null }
            $vtNotBold | Should -Be $Expected
        }

        It 'Should have correct code mapping for vtUnderline' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            $Expected = if ($vtSupported) { "$([char]0x001B)[4m" } else { $null }
            $vtUnderline | Should -Be $Expected
        }

        It 'Should have correct code mapping for vtNotUnderline' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            $Expected = if ($vtSupported) { "$([char]0x001B)[24m" } else { $null }
            $vtNotUnderline | Should -Be $Expected
        }

        It 'Should have correct code mapping for vtForegroundRed' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            $Expected = if ($vtSupported) { "$([char]0x001B)[31m" } else { $null }
            $vtForegroundRed | Should -Be $Expected
        }

        It 'Should have correct code mapping for vtForegroundDefault' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            $Expected = if ($vtSupported) { "$([char]0x001B)[39m" } else { $null }
            $vtForegroundDefault | Should -Be $Expected
        }

        It 'Should have correct code mapping for vtBackgroundDefault' {
            $vtSupported = (Get-Host).UI.SupportsVirtualTerminal
            $Expected = if ($vtSupported) { "$([char]0x001B)[49m" } else { $null }
            $vtBackgroundDefault | Should -Be $Expected
        }
    }
}
