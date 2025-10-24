# PowerShell script to compress JSON files with gzip
param(
    [string]$InputFile,
    [string]$OutputFile
)

try {
    # Read the file content
    $content = Get-Content $InputFile -Raw -Encoding UTF8
    
    # Convert to byte array
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    
    # Create memory streams
    $inputStream = New-Object System.IO.MemoryStream(,$bytes)
    $outputStream = New-Object System.IO.MemoryStream
    
    # Create gzip stream
    $gzipStream = New-Object System.IO.Compression.GZipStream($outputStream, [System.IO.Compression.CompressionMode]::Compress)
    
    # Copy and compress
    $inputStream.CopyTo($gzipStream)
    
    # Close streams
    $gzipStream.Close()
    $inputStream.Close()
    
    # Write compressed data to file
    [System.IO.File]::WriteAllBytes($OutputFile, $outputStream.ToArray())
    $outputStream.Close()
    
    Write-Host "Compressed: $InputFile -> $OutputFile"
    
    # Calculate compression ratio
    $originalSize = (Get-Item $InputFile).Length
    $compressedSize = (Get-Item $OutputFile).Length
    $compressionRatio = [math]::Round((($originalSize - $compressedSize) / $originalSize) * 100, 2)
    
    Write-Host "Compression ratio: $compressionRatio% ($([math]::Round($originalSize/1MB, 2)) MB -> $([math]::Round($compressedSize/1MB, 2)) MB)"
    
} catch {
    Write-Error "Error compressing $InputFile : $($_.Exception.Message)"
    exit 1
}
