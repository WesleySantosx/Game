param(
    [Parameter(Mandatory = $true)]
    [string]$GodotPath
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $projectRoot 'builds/windows'
$packPath = Join-Path $outputDirectory 'ResgateDoSerjo.pck'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

# Sem templates instalados, o executável local da Godot carrega o pacote PCK.
# O jogo abre diretamente e não exige instalar a Godot na máquina de destino.
$exportProcess = Start-Process -FilePath $GodotPath -ArgumentList @(
    '--headless', '--editor', '--path', ('"' + $projectRoot + '"'),
    '--export-pack', '"Windows Desktop"', ('"' + $packPath + '"')
) -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput (Join-Path $projectRoot 'builds/export.log') -RedirectStandardError (Join-Path $projectRoot 'builds/export-errors.log')
$exportErrors = Get-Content -LiteralPath (Join-Path $projectRoot 'builds/export-errors.log') -Raw -ErrorAction SilentlyContinue
if ($exportProcess.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $packPath) -or $exportErrors -match '(?m)^(SCRIPT ERROR:|ERROR:)') {
    throw 'Falha ao gerar o PCK. Confira builds/export-errors.log.'
}
Copy-Item -LiteralPath $GodotPath -Destination (Join-Path $outputDirectory 'ResgateDoSerjo.exe') -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses/Godot-LICENSE.txt') -Destination $outputDirectory -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'licenses/Godot-COPYRIGHT.txt') -Destination $outputDirectory -Force

@'
@echo off
cd /d "%~dp0"
start "" "%~dp0ResgateDoSerjo.exe" --main-pack "%~dp0ResgateDoSerjo.pck"
'@ | Set-Content -LiteralPath (Join-Path $outputDirectory 'JOGAR.cmd') -Encoding ascii

@'
RESGATE DO SERJO - WINDOWS 64 BITS

Extraia a pasta inteira e abra JOGAR.cmd.
Mantenha o executavel, o PCK e o launcher juntos.
Nao precisa instalar Godot para jogar este pacote portatil.

WASD: mover | Shift: correr | Mouse: olhar | F: lanterna
E: libertar Serjo com 7 bolas | Esc: pausar | R: reiniciar
F11: alternar tela cheia.

5 minutos e 3 vidas. Josias tira uma vida e espalha todas as bolas.
Na sexta bola o Ruan aparece: ele rouba duas bolas e leva voce
para perto do Josias, que fica atordoado por alguns segundos.

O pacote usa o executavel local da Godot para carregar o jogo.
Licencas da engine e de bibliotecas acompanham esta pasta.
'@ | Set-Content -LiteralPath (Join-Path $outputDirectory 'LEIA_ME.txt') -Encoding utf8

Compress-Archive -LiteralPath $outputDirectory -DestinationPath (Join-Path $projectRoot 'builds/ResgateDoSerjo-Windows.zip') -Force
Write-Output 'Pronto: builds/ResgateDoSerjo-Windows.zip'
