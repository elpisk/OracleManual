<#
  기준 이미지에서 RAC1 / RAC2 를 링크드 클론으로 만든다.
  전체 복제는 82GB 를 그대로 복사하지만 링크드 클론은 몇 초에 끝난다.

  주의 — 링크드 클론은 원본 vmdk 를 참조한다. 원본을 지우거나 옮기면
         클론이 모두 기동하지 못한다. 원본은 반드시 보존한다.

  사용법:
    powershell -ExecutionPolicy Bypass -File 02_clone_vms.ps1
    powershell -ExecutionPolicy Bypass -File 02_clone_vms.ps1 -Base "D:\OEL7V9\OEL7V9.vmx"
#>
param(
    [string]$Base     = "D:\OEL7V9\OEL7V9.vmx",
    [string]$Snapshot = "base-for-rac",
    [string]$Dest     = "D:\RAC",
    [string]$Vmrun    = "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"
)

if (-not (Test-Path $Vmrun)) { throw "vmrun 을 찾지 못했다: $Vmrun" }
if (-not (Test-Path $Base))  { throw "기준 이미지를 찾지 못했다: $Base" }

# 기준 스냅샷이 없으면 만든다. 링크드 클론은 스냅샷을 지정해야 한다.
$snaps = & $Vmrun listSnapshots $Base
if ($snaps -notmatch [regex]::Escape($Snapshot)) {
    Write-Host "기준 스냅샷 $Snapshot 생성 중..."
    & $Vmrun snapshot $Base $Snapshot
} else {
    Write-Host "기준 스냅샷 $Snapshot 확인됨"
}

foreach ($n in @("RAC1", "RAC2")) {
    $vmx = Join-Path $Dest "$n\$n.vmx"
    if (Test-Path $vmx) { Write-Host "$n 이미 있음 (건너뜀): $vmx"; continue }
    New-Item -ItemType Directory -Force (Split-Path $vmx) | Out-Null
    Write-Host "$n 링크드 클론 생성 중..."
    # -cloneName 을 함께 주면 "The snapshot already exists" 오류가 난다. 쓰지 않는다.
    & $Vmrun clone $Base $vmx linked "-snapshot=$Snapshot"
    if (Test-Path $vmx) { Write-Host "  완료: $vmx" } else { Write-Host "  실패" }
}

Write-Host "`n다음 단계: 03_patch_vmx.ps1"
