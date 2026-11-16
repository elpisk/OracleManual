# ol7a 에 실습용 10GB 디스크 4개(sdb~sde)와 두 번째 NIC(ens33), 직렬 콘솔 파이프를 붙인다.
# VM 이 꺼진 상태에서 한 번만 실행한다. 스냅샷을 뜨기 전에 한다(스냅샷 뒤에 디스크를 붙이면 되돌릴 때 사라진다).
#
#   powershell -ExecutionPolicy Bypass -File add-lab-disks.ps1 -Vmx D:\OL7LAB\ol7a\ol7a.vmx
#
# 실측 랩의 결과: scsi0:1~4 = ol7a_d1~d4.vmdk (lsilogic), ethernet1 = nat/e1000,
# serial0 = \\.\pipe\ol7a_com. 리눅스에서 HCTL 2:0:1:0~2:0:4:0, ens33 으로 보인다.
param(
    [Parameter(Mandatory = $true)][string]$Vmx,
    [int]$Count = 4,
    [string]$SizeGB = "10",
    [string]$Prefix = "",
    [switch]$NoNic,
    [switch]$NoSerial
)
$ErrorActionPreference = "Stop"
$vw = "C:\Program Files (x86)\VMware\VMware Workstation"
$vdm = Join-Path $vw "vmware-vdiskmanager.exe"
$vmrun = Join-Path $vw "vmrun.exe"

if (-not (Test-Path $Vmx)) { throw "vmx 없음: $Vmx" }
$running = & $vmrun -T ws list
if ($running -match [regex]::Escape($Vmx)) { throw "VM 이 켜져 있다. 끈 뒤 다시 실행" }

$dir = Split-Path $Vmx
$name = [IO.Path]::GetFileNameWithoutExtension($Vmx)
if (-not $Prefix) { $Prefix = $name + "_d" }

Copy-Item $Vmx "$Vmx.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"
$lines = [Collections.Generic.List[string]](Get-Content $Vmx)

function Has([string]$key) { return ($lines | Where-Object { $_ -match ('^' + [regex]::Escape($key) + '\s*=') }).Count -gt 0 }

for ($i = 1; $i -le $Count; $i++) {
    $file = "$Prefix$i.vmdk"
    $path = Join-Path $dir $file
    if (Has "scsi0:$i.fileName") { Write-Host "scsi0:$i 이미 있음 - 건너뜀"; continue }
    if (-not (Test-Path $path)) {
        # -t 0 : 파일 하나로 커지는(growable) 디스크. 처음에는 수 MB 다.
        & $vdm -c -s "${SizeGB}GB" -a lsilogic -t 0 $path | Out-Host
    }
    $lines.Add("scsi0:$i.present = `"TRUE`"")
    $lines.Add("scsi0:$i.fileName = `"$file`"")
    Write-Host "scsi0:$i = $file"
}

if (-not $NoNic -and -not (Has "ethernet1.present")) {
    $lines.Add('ethernet1.present = "TRUE"')
    $lines.Add('ethernet1.connectionType = "nat"')
    $lines.Add('ethernet1.virtualDev = "e1000"')
    $lines.Add('ethernet1.addressType = "generated"')
    Write-Host "ethernet1 추가 (13장 본딩용)"
}

if (-not $NoSerial -and -not (Has "serial0.present")) {
    # 직렬 콘솔을 이름 있는 파이프로 내보낸다. 부팅 장애 실습(3·9·20장)에서 GRUB 메뉴와
    # emergency 셸을 텍스트로 받는 데 쓴다. 게스트 쪽 설정은 vm/prepare-base.sh.
    $lines.Add('serial0.present = "TRUE"')
    $lines.Add('serial0.fileType = "pipe"')
    $lines.Add("serial0.fileName = `"\\.\pipe\${name}_com`"")
    $lines.Add('serial0.pipe.endPoint = "server"')
    $lines.Add('serial0.tryNoRxLoss = "TRUE"')
    $lines.Add('serial0.yieldOnMsrRead = "TRUE"')
    $lines.Add('serial0.startConnected = "TRUE"')
    Write-Host "serial0 = \\.\pipe\${name}_com"
}

Set-Content -Path $Vmx -Value $lines -Encoding ASCII
Select-String -Path $Vmx -Pattern '^(scsi0:\d\.fileName|ethernet\d\.(connectionType|virtualDev)|serial0\.fileName)' | ForEach-Object { $_.Line }
