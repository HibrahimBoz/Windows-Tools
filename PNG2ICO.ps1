# Save this script as ConvertTo-Ico.ps1

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Function to open a file dialog and select a PNG file
function Select-PngFile {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "PNG Files (*.png)|*.png"
    $openFileDialog.Multiselect = $false
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $openFileDialog.FileName
    }
    return $null
}

# Select the PNG file
$inputFile = Select-PngFile
if ($null -eq $inputFile) {
    Write-Host "No file selected. Exiting."
    exit
}

# Determine the output file path
$outputFile = [System.IO.Path]::ChangeExtension($inputFile, ".ico")

# Load the image
$image = [System.Drawing.Image]::FromFile($inputFile)

# Create an icon with multiple sizes
$sizes = @(16, 32, 48, 64, 128, 256)
$iconStream = New-Object System.IO.MemoryStream
$iconWriter = New-Object System.IO.BinaryWriter($iconStream)

# Write icon header
$iconWriter.Write([byte]0) # Reserved, always 0
$iconWriter.Write([byte]0) # Reserved, always 0
$iconWriter.Write([UInt16]1) # Image type, 1 = icon
$iconWriter.Write([UInt16]($sizes.Length)) # Number of images

# Image directory entries
$entries = @()
foreach ($size in $sizes) {
    $bitmap = New-Object System.Drawing.Bitmap($image, [System.Drawing.Size]::new($size, $size))
    $bitmapStream = New-Object System.IO.MemoryStream
    $bitmap.Save($bitmapStream, [System.Drawing.Imaging.ImageFormat]::Png)
    $bitmapBytes = $bitmapStream.ToArray()
    $bitmapStream.Close()
    
    $entry = @{
        Width = [byte]$size
        Height = [byte]$size
        ColorCount = 0
        Reserved = 0
        Planes = [UInt16]1
        BitCount = [UInt16]32
        BytesInRes = [UInt32]$bitmapBytes.Length
        ImageOffset = [UInt32]0 # Will be set later
        BitmapBytes = $bitmapBytes
    }
    $entries += $entry
}

# Calculate image offsets and write entries
$offset = 6 + ($entries.Count * 16)
foreach ($entry in $entries) {
    $iconWriter.Write([byte]$entry.Width)
    $iconWriter.Write([byte]$entry.Height)
    $iconWriter.Write([byte]$entry.ColorCount)
    $iconWriter.Write([byte]$entry.Reserved)
    $iconWriter.Write([UInt16]$entry.Planes)
    $iconWriter.Write([UInt16]$entry.BitCount)
    $iconWriter.Write([UInt32]$entry.BytesInRes)
    $iconWriter.Write([UInt32]$offset)
    $offset += $entry.BytesInRes
}

# Write image data
foreach ($entry in $entries) {
    $iconWriter.Write($entry.BitmapBytes)
}

$iconWriter.Flush()
$iconBytes = $iconStream.ToArray()
$iconStream.Close()

# Save to output file
$fileStream = [System.IO.File]::Open($outputFile, [System.IO.FileMode]::Create)
$fileStream.Write($iconBytes, 0, $iconBytes.Length)
$fileStream.Close()

Write-Host "PNG file successfully converted to ICO format: $outputFile"
