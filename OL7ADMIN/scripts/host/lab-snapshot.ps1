# 실습 VM 스냅샷 목록 보기·되돌리기·만들기 (vmrun 래퍼).
# 스냅샷은 전원을 끈 상태에서만 뜬다. suspend 는 쓰지 않는다(PRD 4.2).
#
#   .\lab-snapshot.ps1 list   ol7a
#   .\lab-snapshot.ps1 revert ol7a ol7-base      # 끄고 되돌린 뒤 켠다
#   .\lab-snapshot.ps1 take   ol7a storage-clean # 꺼져 있을 때만
#
# 과정에서 쓰는 스냅샷
#   ol7a : os-installed (설치 직후) / ol7-base (기준) / storage-clean (= ol7-base, 추가 디스크 비어 있음)
#          / pre-break (= ol7-base, 부팅 장애 실습 시작점)
#   ol7b : ol7b-base
param(
    [Parameter(Mandatory = $true)][ValidateSet("list", "revert", "take")][string]$Action,
    [Parameter(Mandatory = $true)][string]$Vm,
    [string]$Snapshot,
    [string]$Root = "D:\OL7LAB"
)
$ErrorActionPreference = "Stop"
$vmrun = "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe"
$vmx = Join-Path $Root "$Vm\$Vm.vmx"
if (-not (Test-Path $vmx)) { throw "vmx 없음: $vmx" }

function IsRunning { return ((& $vmrun -T ws list) -match [regex]::Escape($vmx)) }

switch ($Action) {
    "list" { & $vmrun -T ws listSnapshots $vmx }
    "revert" {
        if (-not $Snapshot) { throw "스냅샷 이름이 필요하다" }
        # 되돌리기 직전 D: 여유를 본다. 델타 디스크가 커지면 VM 이 디스크 부족 질문에서 멈춘다.
        $free = (Get-PSDrive ($Root.Substring(0, 1))).Free / 1GB
        if ($free -lt 15) { throw ("{0} 여유 {1:N1}GB - 15GB 미만이면 되돌리지 않는다" -f $Root.Substring(0, 2), $free) }
        if (IsRunning) { & $vmrun -T ws stop $vmx hard | Out-Null }
        & $vmrun -T ws revertToSnapshot $vmx $Snapshot
        & $vmrun -T ws start $vmx nogui
        Write-Host "$Vm -> $Snapshot, 기동 요청함. SSH 가 열릴 때까지 30~60초"
    }
    "take" {
        if (-not $Snapshot) { throw "스냅샷 이름이 필요하다" }
        if (IsRunning) { throw "VM 이 켜져 있다. 게스트에서 poweroff 한 뒤 다시 실행" }
        & $vmrun -T ws snapshot $vmx $Snapshot
        & $vmrun -T ws listSnapshots $vmx
    }
}
