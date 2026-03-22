$errs = $null
$tokens = $null
[void][System.Management.Automation.Language.Parser]::ParseFile('d:\procket\IMCHAT\scripts\e2e_verify.ps1', [ref]$tokens, [ref]$errs)
Write-Host "Parse errors: $($errs.Count)"
foreach ($e in $errs) { Write-Host "  Line $($e.Extent.StartLineNumber) Col $($e.Extent.StartColumnNumber): $($e.Message)" }
