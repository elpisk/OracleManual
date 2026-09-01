<#
  RAC1 / RAC2 의 vmx 에 사설 NIC 와 공유 SCSI 디스크를 설정한다.
  두 VM 이 모두 정지한 상태에서 실행한다. 기존 값은 덮어쓰고 없는 항목은 추가한다.

  사용법: powershell -ExecutionPolicy Bypass -File 03_patch_vmx.ps1
#>
param(
    [string]$Dest    = "D:\RAC",
    [string]$Shared  = "D:\RAC\SHARED",
    [string[]]$Names = @("RAC1", "RAC2"),
    [string]$MemMB   = "9216",     # cluvfy 의 PRVF-7530 을 피하려면 8192 로는 부족하다
    [string]$Vcpus   = "4"
)

# 디스크 이름과 SCSI 타깃 — 7 은 컨트롤러 예약이므로 건너뛴다
$disks   = @("crs1","crs2","crs3","data1","data2","data3","fra1","fra2")
$targets = @(0,1,2,3,4,5,6,8)

function Get-BaseSettings([string]$name) {
    $h = [ordered]@{
        'displayName'          = "`"$name`""
        'memsize'              = "`"$MemMB`""
        'numvcpus'             = "`"$Vcpus`""
        'cpuid.coresPerSocket' = "`"$Vcpus`""
        # 사설 인터커넥트 (VMnet1 호스트 전용)
        'ethernet1.present'        = '"TRUE"'
        'ethernet1.connectionType' = '"custom"'
        'ethernet1.vnet'           = '"VMnet1"'
        'ethernet1.virtualDev'     = '"e1000e"'
        'ethernet1.addressType'    = '"generated"'
        # 공유 SCSI 컨트롤러 — 이 세 줄이 없으면 클러스터가 서지 않는다
        'scsi1.present'        = '"TRUE"'
        'scsi1.virtualDev'     = '"lsilogic"'
        'scsi1.sharedBus'      = '"virtual"'
        'scsi1.pciSlotNumber'  = '"37"'
        'disk.locking'         = '"false"'
        'disk.EnableUUID'      = '"TRUE"'
    }
    for ($i = 0; $i -lt $disks.Count; $i++) {
        $p = "scsi1:" + $targets[$i]
        $h["$p.present"]    = '"TRUE"'
        $h["$p.fileName"]   = '"' + (Join-Path $Shared ($disks[$i] + ".vmdk")) + '"'
        $h["$p.mode"]       = '"independent-persistent"'   # 스냅샷 대상에서 제외
        $h["$p.deviceType"] = '"disk"'
        $h["$p.redo"]       = '""'
    }
    return $h
}

foreach ($n in $Names) {
    $vmx = Join-Path $Dest "$n\$n.vmx"
    if (-not (Test-Path $vmx)) { Write-Host "!! 없음: $vmx"; continue }

    $want  = Get-BaseSettings $n
    $lines = Get-Content $vmx
    $out   = New-Object System.Collections.Generic.List[string]
    $seen  = New-Object System.Collections.Generic.HashSet[string]

    foreach ($ln in $lines) {
        if ($ln -match '^\s*([\w:\.]+)\s*=\s*(.*)$' -and $want.Contains($Matches[1])) {
            $k = $Matches[1]
            $out.Add("$k = " + $want[$k]) | Out-Null
            [void]$seen.Add($k)
        } else {
            $out.Add($ln) | Out-Null
        }
    }
    $added = 0
    $tail = $want.Keys | Where-Object { -not $seen.Contains($_) }
    if ($tail) {
        $out.Add("") | Out-Null
        $out.Add("# --- RAC 구성 (03_patch_vmx.ps1 자동 추가) ---") | Out-Null
        foreach ($k in $tail) { $out.Add("$k = " + $want[$k]) | Out-Null; $added++ }
    }
    Set-Content -Path $vmx -Value $out -Encoding UTF8
    Write-Host ("{0,-6} 설정 완료 — 수정 {1} / 추가 {2}" -f $n, $seen.Count, $added)
}

Write-Host "`n두 VM 을 기동한 뒤 node/10_os_setup.sh 로 넘어간다."
