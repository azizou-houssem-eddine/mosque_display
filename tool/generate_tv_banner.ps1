Add-Type -AssemblyName System.Drawing
$width = 320
$height = 180
$bmp = New-Object System.Drawing.Bitmap $width, $height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Deep Royal Emerald Background (#06231A)
$bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 6, 35, 26))
$g.FillRectangle($bgBrush, 0, 0, $width, $height)

# Gold Border (#D4AF37)
$goldPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 212, 175, 55), 3)
$g.DrawRectangle($goldPen, 2, 2, $width - 5, $height - 5)

# Inner Ambient Radial Glow / Accent (#F2C94C with alpha)
$glowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(40, 242, 201, 76))
$g.FillEllipse($glowBrush, 80, 20, 160, 140)

# Inner Islamic Star / Rosette Motif placeholder
$starPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(180, 242, 201, 76), 2)
$g.DrawEllipse($starPen, 110, 40, 100, 100)
$g.DrawRectangle($starPen, 125, 55, 70, 70)

# Save to Android and Assets destinations
$drawablePath = "d:\programation\mosque\android\app\src\main\res\drawable"
if (!(Test-Path -Path $drawablePath)) { New-Item -ItemType Directory -Path $drawablePath -Force | Out-Null }
$imagesPath = "d:\programation\mosque\assets\images"
if (!(Test-Path -Path $imagesPath)) { New-Item -ItemType Directory -Path $imagesPath -Force | Out-Null }

$bmp.Save("$drawablePath\tv_banner.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Save("$imagesPath\tv_banner.png", [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()

Write-Host "TV Banner generated successfully at:"
Write-Host "  - $drawablePath\tv_banner.png"
Write-Host "  - $imagesPath\tv_banner.png"
Get-Item "$drawablePath\tv_banner.png", "$imagesPath\tv_banner.png" | Select-Object FullName, Length
