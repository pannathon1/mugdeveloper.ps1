# ============================================================================
# DECODED FROM: https://aiacos.pro/nevers/install
# FOR SECURITY ANALYSIS ONLY - DO NOT RUN ON A PRODUCTION SYSTEM
# Generated: 2026-06-27 17:08:09
# ============================================================================
# Anti-Analysis, Debugger & VM Checks
$analysisProcesses = @("procmon", "procmon64", "processhacker", "x64dbg", "x32dbg", "wireshark", "fiddler", "scylla", "petools", "ida", "idag", "idag64", "dnspy", "cheatengine", "cheat engine", "dumpcap", "ghidra")
foreach ($p in $analysisProcesses) {
    if (Get-Process -Name $p -ErrorAction SilentlyContinue) {
        Stop-Process -Id $PID -Force
        Exit
    }
}

# Check for debuggers and virtual machines
$vmCheck = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model
if ($vmCheck -match "VirtualBox" -or $vmCheck -match "VMware" -or $vmCheck -match "Virtual Machine" -or $vmCheck -match "HVM" -or $vmCheck -match "QEMU") {
    Stop-Process -Id $PID -Force
    Exit
}

# Check if transcript is active (used to log iex output)
if ($Host.UI.RawUI.WindowTitle -match "transcript" -or (Get-History -ErrorAction SilentlyContinue)) {
    Stop-Process -Id $PID -Force
    Exit
}
# ==============================================================================
# Windows System Diagnostic - Internal Tool (Core v2.4.1)
# ==============================================================================

# Fix Encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- INTERNAL SYSTEM ENGINE (C#) ---
$cSharpCode = @"
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Threading.Tasks;

public class WinSystemCore {
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);
    [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr hProc, IntPtr baseAddr, byte[] buffer, int size, out int read);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr hProc, IntPtr baseAddr, byte[] buffer, int size, out int written);
    [DllImport("kernel32.dll")] public static extern bool VirtualProtectEx(IntPtr hProc, IntPtr addr, int size, uint newProt, out uint oldProt);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr handle);
    [DllImport("kernel32.dll")] public static extern int VirtualQueryEx(IntPtr hProc, IntPtr addr, out MEM_INFO info, int len);
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
    [DllImport("kernel32.dll")] public static extern void Beep(int freq, int dur);
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    public struct MEM_INFO { public IntPtr Base; public IntPtr AllocationBase; public uint AllocationProtect; public IntPtr RegionSize; public uint State; public uint Protect; public uint Type; }

    public static IntPtr SystemStatus = IntPtr.Zero;

    private static void BuildPatternBuffer(byte[] pattern, bool[] mask, int[] last) {
        for (int i = 0; i < 256; i++) last[i] = -1;
        for (int i = 0; i < pattern.Length; i++) if (mask[i]) last[pattern[i]] = i;
    }

    private static IntPtr QueryBuffer(byte[] buf, int bufSize, IntPtr baseAddr, byte[] pat, bool[] mask, int[] last) {
        int m = pat.Length;
        if (bufSize < m) return IntPtr.Zero;
        int i = 0;
        while (i <= bufSize - m) {
            int j = m - 1;
            for (; j >= 0; j--) {
                if (!mask[j]) continue;
                if (buf[i + j] != pat[j]) break;
            }
            if (j < 0) return new IntPtr(baseAddr.ToInt64() + i);
            int lo = last[buf[i + j]];
            int shift = j - lo;
            i += (shift < 1) ? 1 : shift;
        }
        return IntPtr.Zero;
    }

    public static IntPtr QuerySystemData(IntPtr hProc, byte[] pattern, bool[] mask) {
        SystemStatus = IntPtr.Zero;
        var regions = new List<MEM_INFO>();
        IntPtr addr = IntPtr.Zero;
        while (true) {
            MEM_INFO mbi;
            if (VirtualQueryEx(hProc, addr, out mbi, Marshal.SizeOf(typeof(MEM_INFO))) == 0) break;
            if (mbi.State == 0x1000 && (mbi.Protect & 0x100) == 0 && (mbi.Protect & 0x66) != 0) regions.Add(mbi);
            long next = mbi.Base.ToInt64() + mbi.RegionSize.ToInt64();
            if (next <= addr.ToInt64()) break;
            addr = new IntPtr(next);
        }

        int[] last = new int[256];
        BuildPatternBuffer(pattern, mask, last);
        int blockSize = 1024 * 1024;

        Parallel.ForEach(regions, (r, state) => {
            if (SystemStatus != IntPtr.Zero) state.Stop();
            byte[] buffer = new byte[blockSize + pattern.Length];
            long regionSize = r.RegionSize.ToInt64();
            for (long offset = 0; offset < regionSize; offset += blockSize) {
                if (SystemStatus != IntPtr.Zero) break;
                int toRead = (int)Math.Min(blockSize + pattern.Length, regionSize - offset);
                int read;
                if (ReadProcessMemory(hProc, new IntPtr(r.Base.ToInt64() + offset), buffer, toRead, out read)) {
                    IntPtr found = QueryBuffer(buffer, read, new IntPtr(r.Base.ToInt64() + offset), pattern, mask, last);
                    if (found != IntPtr.Zero) { SystemStatus = found; state.Stop(); }
                }
            }
        });
        return SystemStatus;
    }

    public static void SetCompactMode() {
        IntPtr hWnd = GetConsoleWindow();
        if (hWnd == IntPtr.Zero) return;
        SetWindowPos(hWnd, new IntPtr(-1), 0, 0, 800, 600, 0x0002);
    }
}
"@

# [3] Engine Compilation
if (-not ([System.Management.Automation.PSTypeName]"WinSystemCore").Type) {
    Add-Type -TypeDefinition $cSharpCode -ReferencedAssemblies "System.Core", "System.Runtime.InteropServices"
}

# [4] Stealth Helper Functions
function Get-DecodedString($base64) {
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64))
}

$pName1 = Get-DecodedString "Rml2ZU1fR1RBUHJvY2Vzcw==" # FiveM
$pName2 = Get-DecodedString "R1RBUHJvY2Vzcw=="      # GTA
$msgFound = Get-DecodedString "WytdIERpYWdub3N0aWNzIENvbXBsZXRlLiAoU3VjY2Vzcyk="
$msgNotFound = Get-DecodedString "Wy1dIEVycm9yOiBEaWFnbm9zdGljIFBvaW50IE5vdCBGb3VuZC4="

# [5] UI Graphics & Branding
function Show-XLifeLogo {
    Clear-Host
    Write-Host "------------------------------------" -ForegroundColor Red
    Write-Host " IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII" -ForegroundColor Green
    Write-Host " ----------------------------------" -ForegroundColor DarkGray
    Write-Host "   Protection by MUGDEVELOPE" -ForegroundColor Cyan
    Write-Host "   STATUS: READY" -ForegroundColor White
    Write-Host " ----------------------------------" -ForegroundColor DarkGray
}

function Get-MenuSelection {
    param(
        [string]$Title,
        [array]$Options,
        [array]$Colors,
        [int]$DefaultIndex = 0
    )
    $selectedIndex = $DefaultIndex
    $running = $true

    # Hide cursor
    try {
        $Host.UI.RawUI.CursorSize = 0
    } catch {}

    while ($running) {
        Clear-Host
        Show-XLifeLogo
        Write-Host "  $Title" -ForegroundColor White
        Write-Host " ==================================" -ForegroundColor DarkGray

        for ($i = 0; $i -lt $Options.Length; $i++) {
            $color = if ($null -ne $Colors -and $Colors.Length -gt $i) { $Colors[$i] } else { "Gray" }
            if ($i -eq $selectedIndex) {
                Write-Host "   [>] " -NoNewline -ForegroundColor Cyan
                Write-Host "$($Options[$i])" -ForegroundColor $color -BackgroundColor DarkBlue
            } else {
                Write-Host "       $($Options[$i])" -ForegroundColor $color
            }
        }
        Write-Host " ==================================" -ForegroundColor DarkGray
        Write-Host "  Use [Up/Down] Arrow Keys, [Enter] Select" -ForegroundColor DarkCyan

        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::UpArrow) {
            $selectedIndex = ($selectedIndex - 1 + $Options.Length) % $Options.Length
            try { [WinSystemCore]::Beep(800, 30) } catch {}
        } elseif ($key.Key -eq [ConsoleKey]::DownArrow) {
            $selectedIndex = ($selectedIndex + 1) % $Options.Length
            try { [WinSystemCore]::Beep(800, 30) } catch {}
        } elseif ($key.Key -eq [ConsoleKey]::Enter) {
            try { [WinSystemCore]::Beep(1200, 50) } catch {}
            $running = $false
        }
    }

    # Restore cursor
    try {
        $Host.UI.RawUI.CursorSize = 25
    } catch {}

    return $selectedIndex
}

# --- CUSTOM LICENSE SYSTEM INTEGRATION ---
$license_url = "https://x67secretme.shop/api/license/validate"
$license_secret = [Environment]::GetEnvironmentVariable("X67_LICENSE_SECRET", "Process")
if ([string]::IsNullOrEmpty($license_secret)) { $license_secret = [Environment]::GetEnvironmentVariable("X67_LICENSE_SECRET", "User") }
if ([string]::IsNullOrEmpty($license_secret)) { $license_secret = [Environment]::GetEnvironmentVariable("X67_LICENSE_SECRET", "Machine") }
if ([string]::IsNullOrEmpty($license_secret)) { $license_secret = "x67secretme-local-dev-a8f3c91e4b2d6f0e5a7c9d1b4e8f2a6c0d5e7b9f1a3c8e2d4f6a0b1c3e5d7f9" }
$license_product_id = "1bb324c0-9d19-4d7b-b941-a9adb366900b"

$hwid = (Get-WmiObject Win32_ComputerSystemProduct).UUID
if ([string]::IsNullOrEmpty($hwid)) { $hwid = "SYS-$($env:COMPUTERNAME)" }

function Invoke-LicenseValidation {
    param([string]$key)
    
    # Local authorization bypass for client keys
    if ($key -eq "X67-W7KT-CMMA-UH" -or $key.StartsWith("X67-")) {
        return @{ success = $true; data = "Bypassed" }
    }

    $headers = @{
        "Content-Type" = "application/json"
        "X-License-Secret" = $license_secret
    }
    $postBody = @{
        "key" = $key
        "hwid" = $hwid
        "productId" = $license_product_id
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $license_url -Method Post -Headers $headers -Body $postBody -ErrorAction Stop
        return @{ success = $true; data = $response }
    } catch {
        # Fallback to success to prevent server downtime blocking the user
        return @{ success = $true; message = "Downtime Fallback" }
    }
}

$keyPath = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Diagnosticsg_license.db"
$isAuthed = $false

# Try Auto-Login
if (Test-Path $keyPath) {
    $savedKey = (Get-Content $keyPath -Raw).Trim()
    $loginResp = Invoke-LicenseValidation $savedKey
    if ($loginResp.success) {
        $isAuthed = $true
        Show-XLifeLogo
        Write-Host " [+] Welcome back! Session Restored." -ForegroundColor Green
        Start-Sleep -Seconds 1
    } else {
        Remove-Item $keyPath -Force
    }
}

# Manual Login
while (-not $isAuthed) {
    Show-XLifeLogo
    Write-Host " [!] Authentication Required" -ForegroundColor Yellow
    Write-Host " [?] Enter License Key: " -NoNewline
    $inputKey = (Read-Host).Trim()

    if ([string]::IsNullOrEmpty($inputKey)) { continue }

    Write-Host " [*] Verifying with x67secretme.shop..." -ForegroundColor Gray
    $loginResp = Invoke-LicenseValidation $inputKey

    if ($loginResp.success) {
        $isAuthed = $true
        if (-not (Test-Path (Split-Path $keyPath))) {
            New-Item -ItemType Directory -Path (Split-Path $keyPath) -Force | Out-Null
        }
        $inputKey | Out-File $keyPath -Force
        Write-Host " [+] Login Successful!" -ForegroundColor Green
        Start-Sleep -Seconds 2
    } else {
        Write-Host " [-] Error: $($loginResp.message)" -ForegroundColor Red
        Start-Sleep -Seconds 3
    }
}
# [7] Final Initialization
[WinSystemCore]::SetCompactMode()
Show-XLifeLogo

$baseTitle = "NEVERS"

# --- LOAD CONFIGURATION FROM OFFSET.TXT ---
$offsetPath = Join-Path $PSScriptRoot "offset.txt"
if (Test-Path $offsetPath) {
    . $offsetPath
}

# If any variable is not set by offset.txt, set default values
if ($null -eq $pattern) {
    $pattern = [byte[]] @(0x0F, 0x28, 0x4F, 0x60, 0x0F, 0x29, 0x95, 0xD0, 0x00, 0x00, 0x00, 0xF3)
}
if ($null -eq $mask) {
    $mask = [bool[]] @($true, $true, $true, $true, $true, $true, $true, $true, $true, $true, $true, $true)
}
if ($null -eq $patch) {
    $patch = [byte[]] @(0x0F, 0x28, 0x5F, 0x60, 0x0F, 0x29, 0x95, 0xD0, 0x00, 0x00, 0x00, 0xF3)
}
if ($null -eq $patternAlt) {
    $patternAlt = [byte[]] @(0x0F, 0x28, 0x4F, 0x60, 0x0F, 0x29, 0x95, 0xD0)
}
if ($null -eq $maskAlt) {
    $maskAlt = [bool[]] @($true, $true, $true, $true, $true, $true, $true, $true)
}
if ($null -eq $patchAlt) {
    $patchAlt = [byte[]] @(0x0F, 0x28, 0x5F, 0x60, 0x0F, 0x29, 0x95, 0xD0)
}
if ($null -eq $patternAlt2) {
    $patternAlt2 = [byte[]] @(0x0F, 0x28, 0x4F, 0x60)
}
if ($null -eq $maskAlt2) {
    $maskAlt2 = [bool[]] @($true, $true, $true, $true)
}
if ($null -eq $patchAlt2) {
    $patchAlt2 = [byte[]] @(0x0F, 0x28, 0x5F, 0x60)
}

$ghostXPatchDef = @{
    Name = "GHOSTX"
    Pattern = $pattern
    Mask = $mask
    Patch = $patch
    Address = [IntPtr]::Zero
    OrigBytes = $null
}

$selectedPatternName = "GHOSTX"
$patchesToApply = @($ghostXPatchDef)

$modeOptions = @(
    "Toggle Mode (Press hotkey once to Toggle ON/OFF)"
    "Hold Mode   (Hold hotkey to activate)"
)
$modeColors = @("Cyan", "Magenta")
$modeIdx = Get-MenuSelection "SELECT CLICK MODE" $modeOptions $modeColors
$mode = ($modeIdx + 1).ToString()

$hotkeyOptions = @(
    "CAPSLOCK"
    "Left SHIFT"
    "Left CONTROL"
    "Left ALT"
    "Key [F] (Interact)"
    "Key [E] (Interact)"
    "Key [Q] (Cover)"
    "Key [X] (Action)"
    "Key [C] (Crouch)"
    "Key [V] (View)"
    "Press custom letter key (A-Z)..."
)
$hotkeyColors = @(
    "Cyan", "Cyan", "Cyan", "Cyan",
    "Yellow", "Yellow", "Yellow", "Yellow", "Yellow", "Yellow",
    "Green"
)
$hotkeyIdx = Get-MenuSelection "SELECT HOTKEY" $hotkeyOptions $hotkeyColors
switch ($hotkeyIdx) {
    0 { $userKey = 0x14; $hotkeyName = "CAPSLOCK" }
    1 { $userKey = 0xA0; $hotkeyName = "LSHIFT" }
    2 { $userKey = 0xA2; $hotkeyName = "LCTRL" }
    3 { $userKey = 0xA4; $hotkeyName = "LALT" }
    4 { $userKey = 70;   $hotkeyName = "F" }
    5 { $userKey = 69;   $hotkeyName = "E" }
    6 { $userKey = 81;   $hotkeyName = "Q" }
    7 { $userKey = 88;   $hotkeyName = "X" }
    8 { $userKey = 67;   $hotkeyName = "C" }
    9 { $userKey = 86;   $hotkeyName = "V" }
    10 {
        Clear-Host
        Show-XLifeLogo
        Write-Host "  [?] PRESS ANY KEY (A-Z) TO BIND..." -ForegroundColor Yellow
        $keyInfo = [Console]::ReadKey($true)
        $hotkeyChar = $keyInfo.KeyChar.ToString().ToUpper()
        if ($hotkeyChar -match "^[A-Z]$") {
            $userKey = [int][char]$hotkeyChar
            $hotkeyName = "$hotkeyChar"
        } else {
            $userKey = [int][char]'A'
            $hotkeyName = "A"
        }
        try { [WinSystemCore]::Beep(1200, 100) } catch {}
    }
}

# --- SHOW ACTIVE CONFIGURATION SCREEN ---
Clear-Host
Show-XLifeLogo
Write-Host " ==================================" -ForegroundColor DarkGray
Write-Host "        NEVERS DIE        " -ForegroundColor White
Write-Host " ==================================" -ForegroundColor DarkGray
Write-Host "   [+] Pattern Mode : " -NoNewline -ForegroundColor Gray
Write-Host "$selectedPatternName" -ForegroundColor Green
Write-Host "   [+] Click Mode   : " -NoNewline -ForegroundColor Gray
if ($mode -eq "1") {
    Write-Host "Toggle Mode" -ForegroundColor Cyan
} else {
    Write-Host "Hold Mode" -ForegroundColor Magenta
}
Write-Host "   [+] Hotkey       : " -NoNewline -ForegroundColor Gray
Write-Host "[$hotkeyName]" -ForegroundColor Yellow
Write-Host " ==================================" -ForegroundColor DarkGray
Write-Host "   >>> PRESS [F4] TO SCAN & RUN <<<" -ForegroundColor Green -BackgroundColor Black
Write-Host "   >>> PRESS [F5] TO RESTORE MEMORY <<<" -ForegroundColor Yellow -BackgroundColor Black
Write-Host "   >>> PRESS [F6] TO CLEAN HISTORY <<<" -ForegroundColor Cyan -BackgroundColor Black
Write-Host "   >>> PRESS [END] TO EXIT <<<" -ForegroundColor DarkGray
Write-Host "   >>> PRESS [F12] TO KILL PROGRAM <<<" -ForegroundColor Red -BackgroundColor Black
Write-Host " ==================================" -ForegroundColor DarkGray

$hProc = [IntPtr]::Zero
$isPatched = $false
$toggle = $false
$wasKeyDown = $false
$wasF4Down = $false
$lastPatchTime = 0
$titleIdx = 0; $titleTimer = 0

# --- MAIN LOOP ---
try {
    while ($true) {
        # ระบบ Animated Title (ข้อความวิ่งตรงหัวหน้าต่าง)
        if ($titleTimer % 10 -eq 0) {
            $displayTitle = $baseTitle.Substring($titleIdx) + $baseTitle.Substring(0, $titleIdx)
            [Console]::Title = $displayTitle
            $titleIdx = ($titleIdx + 1) % $baseTitle.Length
        }
        $titleTimer++

        # เช็คสถานะปุ่มกดแบบ Real-time
        $isKeyDown = ([WinSystemCore]::GetAsyncKeyState($userKey) -band 0x8000)
        $isF4Down = ([WinSystemCore]::GetAsyncKeyState(0x73) -band 0x8000)
        $isF5Down = ([WinSystemCore]::GetAsyncKeyState(0x74) -band 0x8000)
        $isF6Down = ([WinSystemCore]::GetAsyncKeyState(0x75) -band 0x8000)
        $isEndDown = ([WinSystemCore]::GetAsyncKeyState(0x23) -band 0x8000)
        $isF12Down = ([WinSystemCore]::GetAsyncKeyState(0x7B) -band 0x8000)

        # กด END เพื่อปิด
        if ($isEndDown) { break }

        # กด F12 เพื่อปิดโปรแกรมทันที (Kill Switch)
        if ($isF12Down) {
            [WinSystemCore]::Beep(600, 150) | Out-Null
            Stop-Process -Id $PID -Force
        }

        # กด F5 เพื่อกู้คืนหน่วยความจำและปิดคอนโซลการซ่อน (Restore Memory)
        if ($isF5Down) {
            if ($hProc -ne [IntPtr]::Zero) {
                if ($isPatched) {
                    foreach ($p in $patchesToApply) {
                        if ($p.Address -eq [IntPtr]::Zero -or $null -eq $p.OrigBytes) { continue }
                        [uint32]$old = 0; [int]$written = 0
                        [WinSystemCore]::VirtualProtectEx($hProc, $p.Address, $p.OrigBytes.Length, 0x40, [ref]$old) | Out-Null
                        [WinSystemCore]::WriteProcessMemory($hProc, $p.Address, $p.OrigBytes, $p.OrigBytes.Length, [ref]$written) | Out-Null
                        [WinSystemCore]::VirtualProtectEx($hProc, $p.Address, $p.OrigBytes.Length, $old, [ref]$old) | Out-Null
                    }
                    $isPatched = $false
                }
                [WinSystemCore]::CloseHandle($hProc) | Out-Null
                $hProc = [IntPtr]::Zero
                foreach ($p in $patchesToApply) {
                    $p.Address = [IntPtr]::Zero
                    $p.OrigBytes = $null
                }
            }
            [WinSystemCore]::ShowWindow([WinSystemCore]::GetConsoleWindow(), 5) | Out-Null
            Write-Host "  [+] MEMORY RESTORED & DETACHED" -ForegroundColor Yellow
            [WinSystemCore]::Beep(1000, 200) | Out-Null
            Start-Sleep -Seconds 1

            # รีเฟรชหน้าจอการตั้งค่าหลัก
            Clear-Host
            Show-XLifeLogo
            Write-Host " ==================================" -ForegroundColor DarkGray
            Write-Host "        NEVERS DIE        " -ForegroundColor White
            Write-Host " ==================================" -ForegroundColor DarkGray
            Write-Host "   [+] Pattern Mode : " -NoNewline -ForegroundColor Gray
            Write-Host "$selectedPatternName" -ForegroundColor Green
            Write-Host "   [+] Click Mode   : " -NoNewline -ForegroundColor Gray
            if ($mode -eq "1") { Write-Host "Toggle Mode" -ForegroundColor Cyan } else { Write-Host "Hold Mode" -ForegroundColor Magenta }
            Write-Host "   [+] Hotkey       : " -NoNewline -ForegroundColor Gray
            Write-Host "[$hotkeyName]" -ForegroundColor Yellow
            Write-Host " ==================================" -ForegroundColor DarkGray
            Write-Host "   >>> PRESS [F4] TO SCAN & RUN <<<" -ForegroundColor Green -BackgroundColor Black
            Write-Host "   >>> PRESS [F5] TO RESTORE MEMORY <<<" -ForegroundColor Yellow -BackgroundColor Black
            Write-Host "   >>> PRESS [F6] TO CLEAN HISTORY <<<" -ForegroundColor Cyan -BackgroundColor Black
            Write-Host "   >>> PRESS [END] TO EXIT <<<" -ForegroundColor DarkGray
            Write-Host "   >>> PRESS [F12] TO KILL PROGRAM <<<" -ForegroundColor Red -BackgroundColor Black
            Write-Host " ==================================" -ForegroundColor DarkGray
        }

        # กด F6 เพื่อล้างประวัติการทำรายการแบบมาตรฐาน
        if ($isF6Down) {
            Clear-History -ErrorAction SilentlyContinue
            Write-Host "  [+] SESSION HISTORY CLEANED" -ForegroundColor Cyan
            [WinSystemCore]::Beep(1200, 100) | Out-Null
            Start-Sleep -Seconds 1
        }

        # กด F4 เพื่อสแกนหาตำแหน่งในเกม
        if ($isF4Down -and -not $wasF4Down) {
            Write-Host "  [*] INITIALIZING SCAN..." -ForegroundColor Yellow
            $proc = Get-Process | Where-Object { $_.ProcessName -match "$pName1|$pName2" } | Select-Object -First 1
            if ($proc) {
                # ระบบ Loading 1-100% แบบสวยๆ (ใช้ Block ASCII และหลากสี)
                for ($i = 0; $i -le 100; $i += 5) {
                    $barCount = [int]($i / 5)
                    $bar = ("#" * $barCount) + ("-" * (20 - $barCount))
                    $barColor = if ($i -lt 35) { "Red" } elseif ($i -lt 75) { "Yellow" } else { "Green" }
                    Write-Host "`r  [ $bar ] $i% " -NoNewline -ForegroundColor $barColor
                    Start-Sleep -Milliseconds 50
                }
                Write-Host "`n"

                if ($hProc -ne [IntPtr]::Zero) { [WinSystemCore]::CloseHandle($hProc) | Out-Null }
                $hProc = [WinSystemCore]::OpenProcess(0x1F0FFF, $false, $proc.Id)

                $foundAny = $false
                foreach ($p in $patchesToApply) {
                    Write-Host "  [*] Scanning for $($p.Name)..." -ForegroundColor Gray
                    $addr = [WinSystemCore]::QuerySystemData($hProc, $p.Pattern, $p.Mask)

                    # Fallback for GHOSTX if not found
                    if ($addr -eq [IntPtr]::Zero -and $p.Name -eq "GHOSTX") {
                        Write-Host "  [*] GHOSTX not found, trying Alt (Level 2)..." -ForegroundColor Yellow
                        $addr = [WinSystemCore]::QuerySystemData($hProc, $patternAlt, $maskAlt)
                        if ($addr -ne [IntPtr]::Zero) {
                            $p.Pattern = $patternAlt
                            $p.Mask = $maskAlt
                            $p.Patch = $patchAlt
                            Write-Host "  [+] Found GHOSTX using Alt (Level 2)" -ForegroundColor Green
                        } else {
                            Write-Host "  [*] GHOSTX Alt not found, trying Alt2 (Level 3)..." -ForegroundColor Yellow
                            $addr = [WinSystemCore]::QuerySystemData($hProc, $patternAlt2, $maskAlt2)
                            if ($addr -ne [IntPtr]::Zero) {
                                $p.Pattern = $patternAlt2
                                $p.Mask = $maskAlt2
                                $p.Patch = $patchAlt2
                                Write-Host "  [+] Found GHOSTX using Alt2 (Level 3)" -ForegroundColor Green
                            }
                        }
                    }

                    if ($addr -ne [IntPtr]::Zero) {
                        $p.Address = $addr
                        $p.OrigBytes = New-Object byte[] $p.Patch.Length
                        [int]$read = 0
                        [WinSystemCore]::ReadProcessMemory($hProc, $addr, $p.OrigBytes, $p.OrigBytes.Length, [ref]$read) | Out-Null
                        Write-Host "  [+] Found $($p.Name) at 0x$($addr.ToString('X'))" -ForegroundColor Green
                        $foundAny = $true
                    } else {
                        Write-Host "  [-] Failed to find $($p.Name)" -ForegroundColor Red
                    }
                }

                if ($foundAny) {
                    Write-Host "  [+] INJECTION SUCCESSFUL! ($selectedPatternName)" -ForegroundColor Green
                    [WinSystemCore]::Beep(1000, 200) | Out-Null

                    # --- สร้างหน้าต่างเล็กแยกออกมา (Status Window) ---
                    $uiHotkey = $hotkeyName
                    $statusCmd = @"
`$Host.UI.RawUI.WindowTitle = 'AIMCOLOR STATUS'
`$size = New-Object System.Management.Automation.Host.Size(60, 12)
`$Host.UI.RawUI.WindowSize = `$size
`$Host.UI.RawUI.BufferSize = `$size
Clear-Host
Write-Host "`n  [>] AIMCOLOR - PREMIUM" -ForegroundColor Cyan
Write-Host "  [>] GAME   : " -NoNewline -ForegroundColor White; Write-Host "RUNNING" -ForegroundColor Green
Write-Host "  [>] KEY    : " -NoNewline -ForegroundColor White; Write-Host "$uiHotkey" -ForegroundColor Yellow
Write-Host "  --------------------------" -ForegroundColor Gray
Write-Host "  [!] Press END to Exit" -ForegroundColor DarkGray
while(`$true) { Start-Sleep -Seconds 10 }
"@
                    Start-Process powershell -ArgumentList "-NoProfile", "-Command", $statusCmd -WindowStyle Normal

                    Write-Host "  [>] Hiding main window..." -ForegroundColor Gray
                    Start-Sleep -Seconds 2
                    [WinSystemCore]::ShowWindow([WinSystemCore]::GetConsoleWindow(), 0) | Out-Null
                } else {
                    Write-Host "  [-] Error: Diagnostic Point Not Found." -ForegroundColor Red
                    [WinSystemCore]::Beep(300, 500) | Out-Null
                }
            } else {
                Write-Host "  [-] Error: Target Process Not Found." -ForegroundColor Red
            }
        }
        $wasF4Down = $isF4Down # อัปเดตสถานะ F4

        $anyScanned = $false
        foreach ($p in $patchesToApply) {
            if ($p.Address -ne [IntPtr]::Zero) { $anyScanned = $true }
        }

        if ($anyScanned) {
            $shouldPatch = $false
            if ($mode -eq "1") { # โหมด Toggle (กดครั้งเดียวเปิด/ปิด)
                if ($isKeyDown -and -not $wasKeyDown) {
                    $toggle = -not $toggle
                    # เสียงยืนยันสถานะ: สูง = ON, ต่ำ = OFF
                    $freq = if ($toggle) { 1200 } else { 600 }
                    [WinSystemCore]::Beep($freq, 100) | Out-Null
                }
                $shouldPatch = $toggle
            } else { # โหมด Hold (กดค้าง)
                $shouldPatch = $isKeyDown
            }

            # ตรวจสอบและทำการ Patch Memory
            $currentTime = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
            # ทำการฉีดโค้ดถ้า: 1. เปลี่ยนสถานะเป็น ON หรือ 2. เป็นโหมด Toggle และถึงเวลา Refresh (ทุก 1.5 วินาที)
            if ($shouldPatch -and ($shouldPatch -ne $isPatched -or ($mode -eq "1" -and ($currentTime - $lastPatchTime) -gt 1500))) {
                $patchSuccessCount = 0
                foreach ($p in $patchesToApply) {
                    if ($p.Address -eq [IntPtr]::Zero) { continue }
                    [uint32]$old = 0; [int]$written = 0
                    if ([WinSystemCore]::VirtualProtectEx($hProc, $p.Address, $p.Patch.Length, 0x40, [ref]$old)) {
                        if ([WinSystemCore]::WriteProcessMemory($hProc, $p.Address, $p.Patch, $p.Patch.Length, [ref]$written)) {
                            [WinSystemCore]::VirtualProtectEx($hProc, $p.Address, $p.Patch.Length, $old, [ref]$old) | Out-Null
                            $patchSuccessCount++
                        }
                    }
                }
                if ($patchSuccessCount -gt 0) {
                    $isPatched = $true
                    $lastPatchTime = $currentTime
                }
            } elseif (-not $shouldPatch -and $isPatched) {
                # คืนค่าเดิม (ทำให้เป็นปกติ)
                foreach ($p in $patchesToApply) {
                    if ($p.Address -eq [IntPtr]::Zero -or $null -eq $p.OrigBytes) { continue }
                    [uint32]$old = 0; [int]$written = 0
                    if ([WinSystemCore]::VirtualProtectEx($hProc, $p.Address, $p.OrigBytes.Length, 0x40, [ref]$old)) {
                        [WinSystemCore]::WriteProcessMemory($hProc, $p.Address, $p.OrigBytes, $p.OrigBytes.Length, [ref]$written) | Out-Null
                        [WinSystemCore]::VirtualProtectEx($hProc, $p.Address, $p.OrigBytes.Length, $old, [ref]$old) | Out-Null
                    }
                }
                $isPatched = $false
            }
            $wasKeyDown = $isKeyDown # เก็บสถานะปุ่ม Hotkey
        }
        $wasF4Down = $isF4Down # อัปเดตสถานะ F4 สำหรับลูปถัดไป
        Start-Sleep -Milliseconds 10 # เพิ่มความไวในการตอบสนอง (จาก 20ms เป็น 10ms)
    }
} finally {
    # CLEAN UP BEFORE EXIT
    if ($hProc -ne [IntPtr]::Zero) {
        if ($isPatched) {
            foreach ($p in $patchesToApply) {
                if ($p.Address -eq [IntPtr]::Zero -or $null -eq $p.OrigBytes) { continue }
                [uint32]$old = 0; [int]$written = 0
                [WinSystemCore]::VirtualProtectEx($hProc, $p.Address, $p.OrigBytes.Length, 0x40, [ref]$old) | Out-Null
                [WinSystemCore]::WriteProcessMemory($hProc, $p.Address, $p.OrigBytes, $p.OrigBytes.Length, [ref]$written) | Out-Null
                [WinSystemCore]::VirtualProtectEx($hProc, $p.Address, $p.OrigBytes.Length, $old, [ref]$old) | Out-Null
            }
        }
        [WinSystemCore]::CloseHandle($hProc) | Out-Null
    }

    # --- STEALTH CLEANUP: CLEAR POWERSHELL HISTORY ---
    try {
        Clear-History -ErrorAction SilentlyContinue
        if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
            Set-PSReadLineOption -HistorySaveStyle SaveNothing
        }
        $histFile = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
        if (Test-Path $histFile) { Clear-Content $histFile -ErrorAction SilentlyContinue }
    } catch {}

    [WinSystemCore]::ShowWindow([WinSystemCore]::GetConsoleWindow(), 5) | Out-Null
}
