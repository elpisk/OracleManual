<#
  기준 스냅샷을 뜬다. 반드시 아래 순서로 정지한 뒤 실행한다.
    1) srvctl stop database -d racdb -o immediate
    2) 양쪽 노드에서 crsctl stop crs   (root)
    3) 양쪽 노드에서 shutdown -h now
  이 스크립트는 3) 이후, 전원이 완전히 꺼진 상태에서 실행한다.

  주의 — 공유 디스크(scsi1:*)는 independent-persistent 이므로 스냅샷에 포함되지
         않는다. OCR·보팅 파일·ASM 디스크그룹·데이터베이스는 되돌아가지 않는다.
         그것까지 되돌리려면 -BackupShared 를 함께 준다(96GB 복사, 시간이 걸린다).

  사용법:
    powershell -ExecutionPolicy Bypass -File 90_snapshot.ps1 -Name rac-base
    powershell -ExecutionPolicy Bypass -File 90_snapshot.ps1 -Name rac-base -BackupShared
#>
param(
    [string]$Name   = "rac-base",
    [string]$Dest   = "D:\RAC",
    [string]$Shared = "D:\RAC\SHARED",
    [switch]$BackupShared,
    [string]$Vmrun  = "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"
)

$running = & $Vmrun list
foreach ($n in @("RAC1","RAC2")) {
    $vmx = Join-Path $Dest "$n\$n.vmx"
    if ($running -match [regex]::Escape($vmx)) {
        throw "$n 이 아직 실행 중이다. 먼저 정지한 뒤 다시 실행한다."
    }
}

if ($BackupShared) {
    $bk = "$Shared" + "_" + $Name
    Write-Host "공유 디스크 백업 중 (96GB, 수십 분) -> $bk"
    robocopy $Shared $bk /E /NFL /NDL /NJH /NJS | Out-Null
    Write-Host "  완료"
}

foreach ($n in @("RAC1","RAC2")) {
    $vmx = Join-Path $Dest "$n\$n.vmx"
    Write-Host "$n 스냅샷 $Name 생성 중..."
    & $Vmrun snapshot $vmx $Name
    & $Vmrun listSnapshots $vmx
}

Write-Host "`n재기동:"
foreach ($n in @("RAC1","RAC2")) {
    Write-Host ("  & `"{0}`" start `"{1}`"" -f $Vmrun, (Join-Path $Dest "$n\$n.vmx"))
}
