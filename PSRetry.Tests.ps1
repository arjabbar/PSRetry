Describe "Invoke-WithRetry" {
    BeforeAll {
        . "$PSScriptRoot\Invoke-WithRetry.ps1"
    }
    
    It "takes a script block and the number of times to invoke as parameters" {
        { Invoke-WithRetry {} -Times 3 } | Should -Not -Throw
    }

    It "Runs a successful script only once" {
        $Global:timesRan = 0
        Invoke-WithRetry { $Global:timesRan++ } -Times 3
        $Global:timesRan | Should -Be 1
    }
    
    It "Runs a failing script the number of times" {
        $Script:timesRan = 0
        try { Invoke-WithRetry { $Script:timesRan++; Throw "some error" } -Times 3 } catch {}
        $Script:timesRan | Should -Be 3
    }
    
    It "Throws an error when the script never runs successfully" {
        { Invoke-WithRetry { $Script:timesRan++; Throw "some error" } -Times 3 } | Should -Throw
    }
    
    It "Runs the BeforeRetry block only after failing at least once." {
        $Script:timesRan = 0
        try { Invoke-WithRetry { Throw "some error" } -BeforeRetry { $Script:timesRan = 'some string' } -Times 2 } catch {}
        $Script:timesRan | Should -Be 'some string'
    }
    
    It "Does not run the BeforeRetry block when there are no more attempts." {
        $Script:timesRan = 0
        try { Invoke-WithRetry { Throw "some error" } -BeforeRetry { $Script:timesRan = 'some string' } -Times 1 } catch {}
        $Script:timesRan | Should -Be 0
    }
    
    It "Waits the throttle time before retrying." {
        Mock Start-Sleep
        $Script:timesRan = 0
        Invoke-WithRetry {
            if ($Script:timesRan -lt 1) {
                $Script:timesRan++
                Throw "some error" 
            }
        } -Throttle 2 -Times 2
        Assert-MockCalled Start-Sleep -ParameterFilter { $Seconds -eq 2 }
    }
}