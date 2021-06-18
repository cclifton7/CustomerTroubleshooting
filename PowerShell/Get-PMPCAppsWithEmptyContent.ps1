param(
    [parameter(Mandatory = $true)]
    $SiteCode,
    [parameter(Mandatory = $false)]
    $ProviderMachineName = $env:COMPUTERNAME
)
$fastState = $CMPSSuppressFastNotUsedCheck
$CMPSSuppressFastNotUsedCheck = $true
# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if ((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

$TaskSequences = Get-CMTaskSequence | Where-Object { $_.References -ne $null }
$allapp = Get-CMApplication -Fast
$alPmpcApp = $allapp | Where-Object { $_.localizeddescription -match 'created by patch my pc' }
$appSearchResult = foreach ($pmpcApp in $alPmpcApp) {
    Write-Host "Now working on application - $($pmpcApp.LocalizedDisplayName)"
    [xml]$appXml = (Get-CMApplication -Id $pmpcApp.CI_ID).sdmpackagexml
    $contentPath = $appXML.AppMgmtDigest.DeploymentType.Installer.Contents.Content.Location
    $appFound = Test-Path -Path "filesystem::\\$($contentPath.TrimStart('\'))"
    if (!$appFound) {
        $deployments = Get-CMApplicationDeployment -InputObject $pmpcApp
        $tsRef = $TaskSequences | Where-Object { $_.references.package -eq $pmpcApp.ModelName }
        [pscustomobject]@{
            ApplicationName   = $pmpcApp.LocalizedDisplayName
            AppCIID           = $pmpcApp.CI_ID
            ContentPath       = $contentPath
            ContentExists     = $appFound
            HasDeployments    = $deployments.Count -ge 1
            TaskSequenceNames = $tsRef.name -join ';'
            TaskSequenceId    = $tsRef.packageid -join ';'
        }
    }
}

$CMPSSuppressFastNotUsedCheck = $fastState
$csvPath = Join-Path -Path $env:USERPROFILE\Desktop -ChildPath 'EmptyContentApps.csv'
if (($appSearchResult | Measure-Object).Count -gt 0) {
    $appSearchResult | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

    Write-Host "A CSV file has been generated - it can be found at $csvPath" -ForegroundColor Green
    Write-Warning "The applications listed in the CSV file generated by the script will need some remediation steps. Please reference the KB article found at the following link for additional information: $([System.Environment]::NewLine * 2)https://patchmypc.com/application-creation-bug-if-powershell-execution-policy-is-set-via-gpo"
}
else {
    Write-Host "No applications with empty content directories found. No further action is needed." -ForegroundColor Green
}
# SIG # Begin signature block
# MIIbzAYJKoZIhvcNAQcCoIIbvTCCG7kCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBSEE9zSv58+odW
# WtJJ8Hs3VPps7wfK3gEedDv1KXP/G6CCFrswggT+MIID5qADAgECAhANQkrgvjqI
# /2BAIc4UAPDdMA0GCSqGSIb3DQEBCwUAMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNV
# BAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBUaW1lc3RhbXBpbmcgQ0EwHhcN
# MjEwMTAxMDAwMDAwWhcNMzEwMTA2MDAwMDAwWjBIMQswCQYDVQQGEwJVUzEXMBUG
# A1UEChMORGlnaUNlcnQsIEluYy4xIDAeBgNVBAMTF0RpZ2lDZXJ0IFRpbWVzdGFt
# cCAyMDIxMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwuZhhGfFivUN
# CKRFymNrUdc6EUK9CnV1TZS0DFC1JhD+HchvkWsMlucaXEjvROW/m2HNFZFiWrj/
# ZwucY/02aoH6KfjdK3CF3gIY83htvH35x20JPb5qdofpir34hF0edsnkxnZ2OlPR
# 0dNaNo/Go+EvGzq3YdZz7E5tM4p8XUUtS7FQ5kE6N1aG3JMjjfdQJehk5t3Tjy9X
# tYcg6w6OLNUj2vRNeEbjA4MxKUpcDDGKSoyIxfcwWvkUrxVfbENJCf0mI1P2jWPo
# GqtbsR0wwptpgrTb/FZUvB+hh6u+elsKIC9LCcmVp42y+tZji06lchzun3oBc/gZ
# 1v4NSYS9AQIDAQABo4IBuDCCAbQwDgYDVR0PAQH/BAQDAgeAMAwGA1UdEwEB/wQC
# MAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwQQYDVR0gBDowODA2BglghkgBhv1s
# BwEwKTAnBggrBgEFBQcCARYbaHR0cDovL3d3dy5kaWdpY2VydC5jb20vQ1BTMB8G
# A1UdIwQYMBaAFPS24SAd/imu0uRhpbKiJbLIFzVuMB0GA1UdDgQWBBQ2RIaOpLqw
# Zr68KC0dRDbd42p6vDBxBgNVHR8EajBoMDKgMKAuhixodHRwOi8vY3JsMy5kaWdp
# Y2VydC5jb20vc2hhMi1hc3N1cmVkLXRzLmNybDAyoDCgLoYsaHR0cDovL2NybDQu
# ZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC10cy5jcmwwgYUGCCsGAQUFBwEBBHkw
# dzAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME8GCCsGAQUF
# BzAChkNodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNz
# dXJlZElEVGltZXN0YW1waW5nQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4IBAQBIHNy1
# 6ZojvOca5yAOjmdG/UJyUXQKI0ejq5LSJcRwWb4UoOUngaVNFBUZB3nw0QTDhtk7
# vf5EAmZN7WmkD/a4cM9i6PVRSnh5Nnont/PnUp+Tp+1DnnvntN1BIon7h6JGA078
# 9P63ZHdjXyNSaYOC+hpT7ZDMjaEXcw3082U5cEvznNZ6e9oMvD0y0BvL9WH8dQgA
# dryBDvjA4VzPxBFy5xtkSdgimnUVQvUtMjiB2vRgorq0Uvtc4GEkJU+y38kpqHND
# Udq9Y9YfW5v3LhtPEx33Sg1xfpe39D+E68Hjo0mh+s6nv1bPull2YYlffqe0jmd4
# +TaY4cso2luHpoovMIIFMTCCBBmgAwIBAgIQCqEl1tYyG35B5AXaNpfCFTANBgkq
# hkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5j
# MRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBB
# c3N1cmVkIElEIFJvb3QgQ0EwHhcNMTYwMTA3MTIwMDAwWhcNMzEwMTA3MTIwMDAw
# WjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQL
# ExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3Vy
# ZWQgSUQgVGltZXN0YW1waW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
# CgKCAQEAvdAy7kvNj3/dqbqCmcU5VChXtiNKxA4HRTNREH3Q+X1NaH7ntqD0jbOI
# 5Je/YyGQmL8TvFfTw+F+CNZqFAA49y4eO+7MpvYyWf5fZT/gm+vjRkcGGlV+Cyd+
# wKL1oODeIj8O/36V+/OjuiI+GKwR5PCZA207hXwJ0+5dyJoLVOOoCXFr4M8iEA91
# z3FyTgqt30A6XLdR4aF5FMZNJCMwXbzsPGBqrC8HzP3w6kfZiFBe/WZuVmEnKYmE
# UeaC50ZQ/ZQqLKfkdT66mA+Ef58xFNat1fJky3seBdCEGXIX8RcG7z3N1k3vBkL9
# olMqT4UdxB08r8/arBD13ays6Vb/kwIDAQABo4IBzjCCAcowHQYDVR0OBBYEFPS2
# 4SAd/imu0uRhpbKiJbLIFzVuMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3z
# bcgPMBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQM
# MAoGCCsGAQUFBwMIMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDov
# L29jc3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5k
# aWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8E
# ejB4MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1
# cmVkSURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20v
# RGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMFAGA1UdIARJMEcwOAYKYIZIAYb9
# bAACBDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BT
# MAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsFAAOCAQEAcZUS6VGHVmnN793afKpj
# erN4zwY3QITvS4S/ys8DAv3Fp8MOIEIsr3fzKx8MIVoqtwU0HWqumfgnoma/Capg
# 33akOpMP+LLR2HwZYuhegiUexLoceywh4tZbLBQ1QwRostt1AuByx5jWPGTlH0gQ
# GF+JOGFNYkYkh2OMkVIsrymJ5Xgf1gsUpYDXEkdws3XVk4WTfraSZ/tTYYmo9WuW
# wPRYaQ18yAGxuSh1t5ljhSKMYcp5lH5Z/IwP42+1ASa2bKXuh1Eh5Fhgm7oMLStt
# osR+u8QlK0cCCHxJrhO24XxCQijGGFbPQTS2Zl22dHv1VjMiLyI2skuiSpXY9aaO
# UjCCBcAwggSooAMCAQICEAushXLn0haurcj6SjfoprMwDQYJKoZIhvcNAQELBQAw
# bDELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTErMCkGA1UEAxMiRGlnaUNlcnQgRVYgQ29kZSBTaWdu
# aW5nIENBIChTSEEyKTAeFw0xOTA5MDUwMDAwMDBaFw0yMjA5MDgxMjAwMDBaMIHS
# MRMwEQYLKwYBBAGCNzwCAQMTAlVTMRkwFwYLKwYBBAGCNzwCAQITCENvbG9yYWRv
# MR0wGwYDVQQPDBRQcml2YXRlIE9yZ2FuaXphdGlvbjEUMBIGA1UEBRMLMjAxMzE2
# MzgzMjcxCzAJBgNVBAYTAlVTMREwDwYDVQQIEwhDb2xvcmFkbzEVMBMGA1UEBxMM
# Q2FzdGxlIFBpbmVzMRkwFwYDVQQKExBQYXRjaCBNeSBQQywgTExDMRkwFwYDVQQD
# ExBQYXRjaCBNeSBQQywgTExDMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEAqfLI08RfiA35IrGRDxgT+wEICIjtGGYfM+DU6M3x9hGQDlL66F1T3xOGfiM8
# 9Cf+mwk+E/A48jVdWLCQqFOKjQn2P8a0qmc0gX4McB4PWMgWNbKTr8/m68+ZqXNn
# B7H+17SDUOP8VxvHOtZ/TqXMGdthnCZ4qqA20sdY/Qku5Zl8tVNhTtmuXa5UYymz
# pjqhF5mh6IKtGG0MGA1R8fa5t3y6KNm38eGiFFQVrs0EDrDYEplFM6rV3+vMoOJw
# aLJImNmtCCH7Ssy0v40UhK1GepfD9vXYRnpcwr7SokFOqT2mXyQRsbJ7FhdXx23X
# k2KTM6tloZZfNw5YppXAqDfToQIDAQABo4IB9TCCAfEwHwYDVR0jBBgwFoAUj+h+
# 8G0yagAFI8dwl2o6kP9r6tQwHQYDVR0OBBYEFDYNk/g9wVl2J0W8JeQiQWDxx1pb
# MDIGA1UdEQQrMCmgJwYIKwYBBQUHCAOgGzAZDBdVUy1DT0xPUkFETy0yMDEzMTYz
# ODMyNzAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwewYDVR0f
# BHQwcjA3oDWgM4YxaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0VWQ29kZVNpZ25p
# bmdTSEEyLWcxLmNybDA3oDWgM4YxaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0VW
# Q29kZVNpZ25pbmdTSEEyLWcxLmNybDBLBgNVHSAERDBCMDcGCWCGSAGG/WwDAjAq
# MCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAcGBWeB
# DAEDMH4GCCsGAQUFBwEBBHIwcDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGln
# aWNlcnQuY29tMEgGCCsGAQUFBzAChjxodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRFVkNvZGVTaWduaW5nQ0EtU0hBMi5jcnQwDAYDVR0TAQH/BAIw
# ADANBgkqhkiG9w0BAQsFAAOCAQEAj7kmoDugOBZVwQ1Y47cdjLLDuzvTD+Ga/5gD
# +KJ3XImOkkiazaQwQnaswl+2p8YvZ9qc+M+ikBnfMKbH3t39CXQBHdbh5ihfssHz
# KXTj2DKhFbO54OcGTSMvvMdE3mUM3lQ6zJWi1iGAjULX+8m6cptRzGvmse+AlLCH
# u5N4uqHEBqlMELXySbp6a9KtEm9pBu+gW2wA2gEF9iNwa7zfCpjrW1ueNuh60Sv7
# oFF09B1u1uRerKxYuC4P5TqO6DYDrpmPiGZz0EhFH9cie6emC/iktMCbHwGq4iP6
# E7eUS/KeoqH0QQwZ/iO2RX2uZvTdRg/nKioKr2CSg+KJ4+rJ3DCCBrwwggWkoAMC
# AQICEAPxtOFfOoLxFJZ4s9fYR1wwDQYJKoZIhvcNAQELBQAwbDELMAkGA1UEBhMC
# VVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0
# LmNvbTErMCkGA1UEAxMiRGlnaUNlcnQgSGlnaCBBc3N1cmFuY2UgRVYgUm9vdCBD
# QTAeFw0xMjA0MTgxMjAwMDBaFw0yNzA0MTgxMjAwMDBaMGwxCzAJBgNVBAYTAlVT
# MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
# b20xKzApBgNVBAMTIkRpZ2lDZXJ0IEVWIENvZGUgU2lnbmluZyBDQSAoU0hBMikw
# ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCnU/oPsrUT8WTPhID8roA1
# 0bbXx6MsrBosrPGErDo1EjqSkbpX5MTJ8y+oSDy31m7clyK6UXlhr0MvDbebtEkx
# rkRYPqShlqeHTyN+w2xlJJBVPqHKI3zFQunEemJFm33eY3TLnmMl+ISamq1FT659
# H8gTy3WbyeHhivgLDJj0yj7QRap6HqVYkzY0visuKzFYZrQyEJ+d8FKh7+g+03by
# QFrc+mo9G0utdrCMXO42uoPqMKhM3vELKlhBiK4AiasD0RaCICJ2615UOBJi4dJw
# JNvtH3DSZAmALeK2nc4f8rsh82zb2LMZe4pQn+/sNgpcmrdK0wigOXn93b89Ogkl
# AgMBAAGjggNYMIIDVDASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIB
# hjATBgNVHSUEDDAKBggrBgEFBQcDAzB/BggrBgEFBQcBAQRzMHEwJAYIKwYBBQUH
# MAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBJBggrBgEFBQcwAoY9aHR0cDov
# L2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0SGlnaEFzc3VyYW5jZUVWUm9v
# dENBLmNydDCBjwYDVR0fBIGHMIGEMECgPqA8hjpodHRwOi8vY3JsMy5kaWdpY2Vy
# dC5jb20vRGlnaUNlcnRIaWdoQXNzdXJhbmNlRVZSb290Q0EuY3JsMECgPqA8hjpo
# dHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRIaWdoQXNzdXJhbmNlRVZS
# b290Q0EuY3JsMIIBxAYDVR0gBIIBuzCCAbcwggGzBglghkgBhv1sAwIwggGkMDoG
# CCsGAQUFBwIBFi5odHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9zc2wtY3BzLXJlcG9z
# aXRvcnkuaHRtMIIBZAYIKwYBBQUHAgIwggFWHoIBUgBBAG4AeQAgAHUAcwBlACAA
# bwBmACAAdABoAGkAcwAgAEMAZQByAHQAaQBmAGkAYwBhAHQAZQAgAGMAbwBuAHMA
# dABpAHQAdQB0AGUAcwAgAGEAYwBjAGUAcAB0AGEAbgBjAGUAIABvAGYAIAB0AGgA
# ZQAgAEQAaQBnAGkAQwBlAHIAdAAgAEMAUAAvAEMAUABTACAAYQBuAGQAIAB0AGgA
# ZQAgAFIAZQBsAHkAaQBuAGcAIABQAGEAcgB0AHkAIABBAGcAcgBlAGUAbQBlAG4A
# dAAgAHcAaABpAGMAaAAgAGwAaQBtAGkAdAAgAGwAaQBhAGIAaQBsAGkAdAB5ACAA
# YQBuAGQAIABhAHIAZQAgAGkAbgBjAG8AcgBwAG8AcgBhAHQAZQBkACAAaABlAHIA
# ZQBpAG4AIABiAHkAIAByAGUAZgBlAHIAZQBuAGMAZQAuMB0GA1UdDgQWBBSP6H7w
# bTJqAAUjx3CXajqQ/2vq1DAfBgNVHSMEGDAWgBSxPsNpA/i/RwHUmCYaCALvY2Qr
# wzANBgkqhkiG9w0BAQsFAAOCAQEAGTNKDIEzN9utNsnkyTq7tRsueqLi9ENCF56/
# TqFN4bHb6YHdnwHy5IjV6f4J/SHB7F2A0vDWwUPC/ncr2/nXkTPObNWyGTvmLtbJ
# k0+IQI7N4fV+8Q/GWVZy6OtqQb0c1UbVfEnKZjgVwb/gkXB3h9zJjTHJDCmiM+2N
# 4ofNiY0/G//V4BqXi3zabfuoxrI6Zmt7AbPN2KY07BIBq5VYpcRTV6hg5ucCEqC5
# I2SiTbt8gSVkIb7P7kIYQ5e7pTcGr03/JqVNYUvsRkG4Zc64eZ4IlguBjIo7j8eZ
# jKMqbphtXmHGlreKuWEtk7jrDgRD1/X+pvBi1JlqpcHB8GSUgDGCBGcwggRjAgEB
# MIGAMGwxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xKzApBgNVBAMTIkRpZ2lDZXJ0IEVWIENvZGUg
# U2lnbmluZyBDQSAoU0hBMikCEAushXLn0haurcj6SjfoprMwDQYJYIZIAWUDBAIB
# BQCggYQwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYK
# KwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG
# 9w0BCQQxIgQgBgPcbZyIWxWN+PW30MtCSX/GQnTWncn+YTAnbLme79EwDQYJKoZI
# hvcNAQEBBQAEggEAgjndldTHPA+sZJwO0IaUnniNSpQLpBYRG7R5Q9oRBs/Rb+U6
# OWx7m2Epq0LPBCiDO5ahixJqK4V0riQDK+ZkqWrIXSrPUiTHeeTLQwAsFZeQ9gN/
# xT7o4lnFX/dwJmrzpMk4jx2s21efJDXF1NQMzJ9ecYHFUHh0Osqc9PH1v2J1D/p3
# vTStqf6ujRRDr7LWVt8wvuhEkyqz0OVF+soZEhADxqepUfjcKTqYp7ow9UA7Zcid
# yTmmz6r2vzT2DBcpOKMUX/aRO1ETECIXN/FWUiMOiOmXmIxdTgcZWx/z2uRadDEq
# nqJ2hCXt6U/3Ud2yS0VOTR5xbab1SwwKajQmxaGCAjAwggIsBgkqhkiG9w0BCQYx
# ggIdMIICGQIBATCBhjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQg
# SW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2Vy
# dCBTSEEyIEFzc3VyZWQgSUQgVGltZXN0YW1waW5nIENBAhANQkrgvjqI/2BAIc4U
# APDdMA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMjEwNjE4MTgzMTA5WjAvBgkqhkiG9w0BCQQxIgQgTrP/
# TgXhE6ztsrcgZTJ+nL0wdEX5ifJH+SyU5wAIwskwDQYJKoZIhvcNAQEBBQAEggEA
# UY+wKuj+pWOzEGFeRYrBy6CCfxhBgqg4fMmfuyI8OgFQLBRON114hXxHM3QOHJCh
# LO0GzCeV7P9mI+x80/3adWIoyqtgfK6OX6ZAOob0ja6UqF9PHhBL0fJ0RlCy7vBI
# kpj8oqB2sV6pgmbo+u1HuNr6LUUIkLN841/y3gwcSpvSolg+s3IN07gY8ubQfnnT
# DyANEWlAX0GV/1WNQnpgnzD2UuM/LFguWOD8WEdHZN29La9L44XIw6mV5E70EjSY
# Svq+ysiTIaTvCjvrLYFrHGaPwmLKN7RG1lm7icduaksohcIiExVfiy62qn5t7YwS
# iL4R6SY+ZRDoDuLrO/2DBw==
# SIG # End signature block
