[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$fontsDir = "d:\programation\mosque\assets\fonts"
if (!(Test-Path $fontsDir)) {
    New-Item -ItemType Directory -Path $fontsDir -Force | Out-Null
}

Write-Host "Downloading Amiri-Regular.ttf..."
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/google/fonts/main/ofl/amiri/Amiri-Regular.ttf" -OutFile "$fontsDir\Amiri-Regular.ttf"

Write-Host "Downloading Amiri-Bold.ttf..."
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/google/fonts/main/ofl/amiri/Amiri-Bold.ttf" -OutFile "$fontsDir\Amiri-Bold.ttf"

Write-Host "Downloading Cairo-Regular.ttf..."
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/google/fonts/main/ofl/cairo/Cairo%5Bslnt%2Cwght%5D.ttf" -OutFile "$fontsDir\Cairo-Regular.ttf"

Copy-Item "$fontsDir\Cairo-Regular.ttf" "$fontsDir\Cairo-SemiBold.ttf" -Force
Copy-Item "$fontsDir\Cairo-Regular.ttf" "$fontsDir\Cairo-Bold.ttf" -Force

Write-Host "Verifying downloaded fonts:"
Get-ChildItem $fontsDir | Select-Object Name, Length
