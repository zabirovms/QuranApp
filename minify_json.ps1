# PowerShell script to minify JSON files
param(
    [string]$InputFile,
    [string]$OutputFile
)

try {
    # Read the JSON file
    $jsonContent = Get-Content $InputFile -Raw -Encoding UTF8
    
    # Parse and minify JSON (remove all whitespace except within strings)
    $jsonObject = $jsonContent | ConvertFrom-Json
    $minifiedJson = $jsonObject | ConvertTo-Json -Compress -Depth 100
    
    # Write minified JSON to output file
    $minifiedJson | Out-File -FilePath $OutputFile -Encoding UTF8 -NoNewline
    
    Write-Host "Minified: $InputFile -> $OutputFile"
    
    # Calculate size reduction
    $originalSize = (Get-Item $InputFile).Length
    $minifiedSize = (Get-Item $OutputFile).Length
    $reduction = [math]::Round((($originalSize - $minifiedSize) / $originalSize) * 100, 2)
    
    Write-Host "Size reduction: $reduction% ($([math]::Round($originalSize/1MB, 2)) MB -> $([math]::Round($minifiedSize/1MB, 2)) MB)"
    
} catch {
    Write-Error "Error minifying $InputFile : $($_.Exception.Message)"
    exit 1
}
