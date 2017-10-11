function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [scriptblock]$BeforeRetry = {},

        [Parameter(Mandatory = $false)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [int]$Throttle = 0,

        [Parameter(Mandatory)]
        [int]$Times
    )

    End {
        $timesAttempted = 0
        if ($Times -lt 0) {
            Write-Warning "The number of times the script should be greater than 0. Passed '$Times'. Only attempting once."
            $Times = 1
        }
        if ($Throttle -lt 0) {
            Write-Warning "The throttle time should be greater than 0. Passed '$Throttle'. Setting throttle time to '0'."
            $Throttle = 1
        }
        do {
            $timesAttempted++
            try {
                $ScriptBlock.Invoke($ArgumentList)
                Return
            }
            catch {
                Write-Warning "Failed to run script, but another attempt will be made. Error: $($Error[0])" 
                if ($timesAttempted -lt $Times) {
                    if ($Throttle) {
                        Write-Verbose "Waiting $Throttle seconds before retrying."
                        Start-Sleep -Seconds $Throttle
                    }
                    $BeforeRetry.Invoke($ArgumentList)
                }
                Write-Verbose "Attempted to run the script $ScriptBlock. Attempt '$timesAttempted' of '$Times'."
            }
        } while ($timesAttempted -lt $Times)
        Throw "The max number of attempts ('$Times') have been exceeded.`n$($Error[0])"
    }
}