<#
  ASM 실습용 test 디스크 6개(4GB) 생성과 vmx 연결 — 설치 가이드 v2 부록 E.
  설치를 모두 마친 뒤(가이드 10장 이후), 두 VM 이 모두 정지한 상태에서 한 번 실행한다.
  이미 있는 vmdk 는 건너뛰고, vmx 의 같은 키는 덮어쓴다(재실행 안전).

  사용법:  powershell -ExecutionPolicy Bypass -File 04_add_test_disks.ps1
#>
param(
    [string]$Dest    = "D:\RAC",
    [string]$Shared  = "D:\RAC\SHARED",
    [string[]]$Names = @("RAC1", "RAC2"),
    [string]$Vdm     = "C:\Program Files (x86)\VMware\VMware Workstation\vmware-vdiskmanager.exe",
    [string]$Vmrun   = "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"
)

# 디스크 이름과 SCSI 타깃 — 0~6, 8 은 crs·data·fra 가 쓰고 7 은 컨트롤러 예약이다
$disks   = @("test1","test2","test3","test4","test5","test6")
$targets = @(9,10,11,12,13,14)

if (-not (Test-Path $Vdm)) { throw "vmware-vdiskmanager 를 찾지 못했다: $Vdm" }
$running = & $Vmrun list
foreach ($n in $Names) {
    $vmx = Join-Path $Dest "$n\$n.vmx"
    if (-not (Test-Path $vmx)) { throw "없음: $vmx" }
    if ($running -match [regex]::Escape($vmx)) { throw "$n 이 실행 중이다. 두 VM 을 모두 정지한 뒤 다시 실행한다." }
}

Write-Host "=== [1] vmdk 생성 ==="
foreach ($d in $disks) {
    $path = Join-Path $Shared ($d + ".vmdk")
    if (Test-Path $path) { Write-Host ("{0,-6} 이미 있음 (건너뜀)" -f $d); continue }
    $s = Get-Date
    & $Vdm -c -s 4GB -a lsilogic -t 2 $path | Out-Null
    $ok = if (Test-Path $path) { "생성" } else { "실패" }
    Write-Host ("{0,-6} 4GB  {1}  {2:N1}초" -f $d, $ok, ((Get-Date)-$s).TotalSeconds)
}

Write-Host "`n=== [2] vmx 연결 ==="
$want = [ordered]@{}
for ($i = 0; $i -lt $disks.Count; $i++) {
    $p = "scsi1:" + $targets[$i]
    $want["$p.present"]    = '"TRUE"'
    $want["$p.fileName"]   = '"' + (Join-Path $Shared ($disks[$i] + ".vmdk")) + '"'
    $want["$p.mode"]       = '"independent-persistent"'
    $want["$p.deviceType"] = '"disk"'
    $want["$p.redo"]       = '""'
}
foreach ($n in $Names) {
    $vmx   = Join-Path $Dest "$n\$n.vmx"
    $lines = Get-Content $vmx
    if (-not ($lines -match '^\s*scsi1\.sharedBus\s*=\s*"virtual"')) {
        throw "$n 에 공유 SCSI 버스(scsi1.sharedBus)가 없다. 03_patch_vmx.ps1 부터 적용한다."
    }
    $out  = New-Object System.Collections.Generic.List[string]
    $seen = New-Object System.Collections.Generic.HashSet[string]
    foreach ($ln in $lines) {
        if ($ln -match '^\s*([\w:\.]+)\s*=\s*(.*)$' -and $want.Contains($Matches[1])) {
            $k = $Matches[1]; $out.Add("$k = " + $want[$k]) | Out-Null; [void]$seen.Add($k)
        } else { $out.Add($ln) | Out-Null }
    }
    $tail = $want.Keys | Where-Object { -not $seen.Contains($_) }
    if ($tail) {
        $out.Add("") | Out-Null
        $out.Add("# --- ASM 실습용 test 디스크 (04_add_test_disks.ps1 자동 추가) ---") | Out-Null
        foreach ($k in $tail) { $out.Add("$k = " + $want[$k]) | Out-Null }
    }
    Set-Content -Path $vmx -Value $out -Encoding UTF8
    Write-Host ("{0,-6} 연결 완료 — 수정 {1} / 추가 {2}" -f $n, $seen.Count, @($tail).Count)
}

Write-Host "`n두 VM 을 기동한 뒤 rac1 에서 node/15_udev_testdisks.sh 를 실행한다."
