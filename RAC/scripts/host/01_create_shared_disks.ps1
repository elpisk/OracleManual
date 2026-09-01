<#
  공유 ASM 디스크 8개 생성 — 합계 96GB, preallocated(-t 2).
  두 VM 이 모두 정지한 상태에서 한 번만 실행한다.
  이미 있는 파일은 건너뛴다(재실행 안전).

  사용법:  powershell -ExecutionPolicy Bypass -File 01_create_shared_disks.ps1
#>
param(
    [string]$Shared = "D:\RAC\SHARED",
    [string]$Vdm    = "C:\Program Files (x86)\VMware\VMware Workstation\vmware-vdiskmanager.exe"
)

if (-not (Test-Path $Vdm)) { throw "vmware-vdiskmanager 를 찾지 못했다: $Vdm" }
if (-not (Test-Path $Shared)) { New-Item -ItemType Directory -Force $Shared | Out-Null }

# 이름, 크기(GB), 용도
$disks = @(
    @{n='crs1';  gb=4 },  @{n='crs2';  gb=4 },  @{n='crs3';  gb=4 },
    @{n='data1'; gb=20},  @{n='data2'; gb=20},  @{n='data3'; gb=20},
    @{n='fra1';  gb=12},  @{n='fra2';  gb=12}
)

$t0 = Get-Date
foreach ($d in $disks) {
    $path = Join-Path $Shared ($d.n + ".vmdk")
    if (Test-Path $path) { Write-Host ("{0,-8} 이미 있음 (건너뜀)" -f $d.n); continue }
    $s = Get-Date
    & $Vdm -c -s ("{0}GB" -f $d.gb) -a lsilogic -t 2 $path | Out-Null
    $ok = if (Test-Path $path) { "생성" } else { "실패" }
    Write-Host ("{0,-8} {1,2}GB  {2}  {3:N1}초" -f $d.n, $d.gb, $ok, ((Get-Date)-$s).TotalSeconds)
}

Write-Host "`n=== 결과 ==="
$tot = 0
Get-ChildItem $Shared -Filter *.vmdk | Sort-Object Name | ForEach-Object {
    $tot += $_.Length
    Write-Host ("  {0,-24} {1,8:N1} GB" -f $_.Name, ($_.Length/1GB))
}
Write-Host ("합계 {0:N1} GB / 소요 {1:N1}분" -f ($tot/1GB), ((Get-Date)-$t0).TotalMinutes)
Write-Host "`n다음 단계: 03_patch_vmx.ps1 로 두 VM 의 vmx 에 연결한다."
