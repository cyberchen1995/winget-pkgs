BeforeAll {
    # Import the VirtualTerminal module first since YamlCreate.Menuing depends on it
    $ModulePath = Split-Path -Parent $PSCommandPath
    $VTModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $ModulePath)) 'VirtualTerminal' 'VirtualTerminal.psd1'
    Import-Module $VTModulePath -Force

    # Import the module to test
    Import-Module (Join-Path $ModulePath 'YamlCreate.Menuing.psd1') -Force
}

Describe 'YamlCreate.Menuing Module' {
    Context 'Module Import' {
        It 'Should import the module successfully' {
            Get-Module 'YamlCreate.Menuing' | Should -Not -BeNullOrEmpty
        }

        It 'Should export all expected functions' {
            $ExportedFunctions = (Get-Module 'YamlCreate.Menuing').ExportedFunctions.Keys
            $ExpectedFunctions = @(
                'Get-Keypress'
                'Resolve-Keypress'
            )
            foreach ($Function in $ExpectedFunctions) {
                $ExportedFunctions | Should -Contain $Function
            }
        }
    }

    Context 'Exported Numeric Variables' {
        It 'Should export Numeric0 through Numeric9 variables' {
            $ExportedVars = (Get-Module 'YamlCreate.Menuing').ExportedVariables.Keys
            foreach ($i in 0..9) {
                $ExportedVars | Should -Contain "Numeric$i"
            }
        }

        It 'Numeric0 should contain D0 and NumPad0 keys' {
            $Numeric0 | Should -Contain ([System.ConsoleKey]::D0)
            $Numeric0 | Should -Contain ([System.ConsoleKey]::NumPad0)
            $Numeric0.Count | Should -Be 2
        }

        It 'Numeric1 should contain D1 and NumPad1 keys' {
            $Numeric1 | Should -Contain ([System.ConsoleKey]::D1)
            $Numeric1 | Should -Contain ([System.ConsoleKey]::NumPad1)
            $Numeric1.Count | Should -Be 2
        }

        It 'Numeric5 should contain D5 and NumPad5 keys' {
            $Numeric5 | Should -Contain ([System.ConsoleKey]::D5)
            $Numeric5 | Should -Contain ([System.ConsoleKey]::NumPad5)
            $Numeric5.Count | Should -Be 2
        }

        It 'Numeric9 should contain D9 and NumPad9 keys' {
            $Numeric9 | Should -Contain ([System.ConsoleKey]::D9)
            $Numeric9 | Should -Contain ([System.ConsoleKey]::NumPad9)
            $Numeric9.Count | Should -Be 2
        }

        It 'Each Numeric variable should have exactly 2 entries' {
            foreach ($i in 0..9) {
                (Get-Variable "Numeric$i" -ValueOnly).Count | Should -Be 2
            }
        }

        It 'Each Numeric variable should map to the correct D-key and NumPad key pair' {
            foreach ($i in 0..9) {
                $NumericVar = Get-Variable "Numeric$i" -ValueOnly
                $NumericVar | Should -Contain ([System.ConsoleKey]"D$i")
                $NumericVar | Should -Contain ([System.ConsoleKey]"NumPad$i")
            }
        }
    }
}

Describe 'Resolve-Keypress' {
    Context 'When the pressed key is in ValidKeys' {
        It 'Should return the pressed key when it is a valid key' {
            Mock Get-Keypress { return [System.ConsoleKey]::A } -ModuleName 'YamlCreate.Menuing'

            $Result = Resolve-Keypress -ValidKeys @([System.ConsoleKey]::A, [System.ConsoleKey]::B) -DefaultKey ([System.ConsoleKey]::B)
            $Result | Should -Be ([System.ConsoleKey]::A)
        }

        It 'Should return the key on first match without looping' {
            $Script:CallCount = 0
            Mock Get-Keypress {
                $Script:CallCount++
                return [System.ConsoleKey]::B
            } -ModuleName 'YamlCreate.Menuing'

            $Result = Resolve-Keypress -ValidKeys @([System.ConsoleKey]::A, [System.ConsoleKey]::B) -DefaultKey ([System.ConsoleKey]::A)
            $Result | Should -Be ([System.ConsoleKey]::B)
            $Script:CallCount | Should -Be 1
        }
    }

    Context 'When the pressed key is the DefaultKey' {
        It 'Should return the default key even if not in ValidKeys' {
            Mock Get-Keypress { return [System.ConsoleKey]::Enter } -ModuleName 'YamlCreate.Menuing'

            $Result = Resolve-Keypress -ValidKeys @([System.ConsoleKey]::A, [System.ConsoleKey]::B) -DefaultKey ([System.ConsoleKey]::Enter)
            $Result | Should -Be ([System.ConsoleKey]::Enter)
        }
    }

    Context 'When strict mode is disabled (default)' {
        It 'Should return DefaultKey when an invalid key is pressed' {
            Mock Get-Keypress { return [System.ConsoleKey]::Z } -ModuleName 'YamlCreate.Menuing'

            $Result = Resolve-Keypress -ValidKeys @([System.ConsoleKey]::A, [System.ConsoleKey]::B) -DefaultKey ([System.ConsoleKey]::Enter)
            $Result | Should -Be ([System.ConsoleKey]::Enter)
        }

        It 'Should return DefaultKey without prompting again' {
            $Script:CallCount = 0
            Mock Get-Keypress {
                $Script:CallCount++
                return [System.ConsoleKey]::Z
            } -ModuleName 'YamlCreate.Menuing'

            $Result = Resolve-Keypress -ValidKeys @([System.ConsoleKey]::A) -DefaultKey ([System.ConsoleKey]::B) -UseStrict $false
            $Result | Should -Be ([System.ConsoleKey]::B)
            $Script:CallCount | Should -Be 1
        }
    }

    Context 'When strict mode is enabled' {
        It 'Should keep prompting until a valid key is pressed' {
            $Script:StrictCallCount = 0
            Mock Get-Keypress {
                $Script:StrictCallCount++
                if ($Script:StrictCallCount -lt 3) {
                    return [System.ConsoleKey]::Z
                }
                return [System.ConsoleKey]::A
            } -ModuleName 'YamlCreate.Menuing'

            $Result = Resolve-Keypress -ValidKeys @([System.ConsoleKey]::A, [System.ConsoleKey]::B) -DefaultKey ([System.ConsoleKey]::Enter) -UseStrict $true
            $Result | Should -Be ([System.ConsoleKey]::A)
            $Script:StrictCallCount | Should -Be 3
        }

        It 'Should accept the default key even in strict mode' {
            Mock Get-Keypress { return [System.ConsoleKey]::Enter } -ModuleName 'YamlCreate.Menuing'

            $Result = Resolve-Keypress -ValidKeys @([System.ConsoleKey]::A) -DefaultKey ([System.ConsoleKey]::Enter) -UseStrict $true
            $Result | Should -Be ([System.ConsoleKey]::Enter)
        }
    }
}
