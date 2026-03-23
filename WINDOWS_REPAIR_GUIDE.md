# The Ultimate Windows Repair Sequence
## Mastering the CMD Triage

**Created:** 2026-03-17  
**Script:** `lab/windows_repair_sequence.bat`  
**Author:** IT Technician's Essential Toolkit

---

## 🎯 Philosophy

> **Efficiency is about having the right tools for the job.**
>
> These built-in Windows utilities are often more powerful than expensive third-party software.
>
> **A clean install is the ABSOLUTE LAST RESORT.** Before you wipe a drive, execute this powerful 5-step triage sequence.

---

## 📋 The 5-Step Sequence

```
┌─────────────────────────────────────────────────────────────────────────┐
│  STEP 1: sfc /scannow          → Initial Scan & Diagnosis              │
│  STEP 2: DISM /RestoreHealth   → Full Health Repair (Windows Update)   │
│  STEP 3: DISM /CheckHealth     → Fast Health Check (verification)      │
│  STEP 4: sfc /scannow          → Final Check (Gold Standard)           │
│  STEP 5: shutdown /r /t 0      → System Reboot                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Step-by-Step Breakdown

### Step 1: SFC Initial Scan & Diagnosis

**Command:** `sfc /scannow`

**Purpose:** First line of defense to identify the extent of system damage.

**What it does:**
- Scans all protected system files
- Replaces corrupted files with cached copy
- Reports integrity violations

**Expected Results:**
| Code | Meaning |
|------|---------|
| 0 | No integrity violations found |
| 1 | Protected files repaired successfully |
| 2 | Some corrupted files could not be repaired |
| Other | SFC encountered an error |

**Time:** 5-15 minutes

---

### Step 2: DISM Full Health Repair

**Command:** `DISM /Online /Cleanup-Image /RestoreHealth`

**Purpose:** The "heavy lifter" — fixes what SFC cannot.

**What it does:**
- Connects directly to Windows Update
- Downloads fresh, healthy replacement files
- Fixes the local Windows image
- Repairs the component store that SFC uses

**When to use:** ALWAYS run this if SFC Step 1 reports errors (code 2 or higher).

**Time:** 10-30 minutes (depending on corruption level)

---

### Step 3: DISM Fast Health Check

**Command:** `DISM /Online /Cleanup-Image /CheckHealth`

**Purpose:** Instantaneous diagnostic to verify repair success.

**What it does:**
- Checks if Windows image is flagged as corrupt
- Quick status check (no deep scan)
- Confirms DISM Step 2 was successful

**Time:** <1 minute

---

### Step 4: SFC Final Check (GOLD STANDARD) ⭐

**Command:** `sfc /scannow`

**Purpose:** **CRITICAL STEP THAT MANY TECHS SKIP!**

**What it does:**
- Now that DISM has repaired the base image, SFC validates ALL installed system files
- Ensures files match the NEW, healthy source
- Confirms complete repair

> **This is what separates a quick fix from a PROFESSIONAL REPAIR.**

**Time:** 5-15 minutes

---

### Step 5: System Reboot

**Command:** `shutdown /r /t 0`

**Purpose:** Finalize all repairs.

**What it does:**
- Restarts system immediately
- Clears system memory
- Ensures repairs take FULL effect

**Time:** <1 minute (plus boot time)

---

## 🚀 Usage

### Run the Script

1. **Download** `windows_repair_sequence.bat`
2. **Right-click** → "Run as Administrator" (REQUIRED)
3. **Select option:**
   - `[1]` Full 5-Step Sequence (RECOMMENDED)
   - `[2-6]` Individual steps
   - `[7]` View repair log
   - `[8]` Exit

### Manual Execution

If running commands manually:

```batch
:: Step 1
sfc /scannow

:: Step 2
DISM /Online /Cleanup-Image /RestoreHealth

:: Step 3
DISM /Online /Cleanup-Image /CheckHealth

:: Step 4 (DO NOT SKIP)
sfc /scannow

:: Step 5
shutdown /r /t 0
```

---

## 📊 Decision Tree

```
System Issues Detected
        │
        ▼
┌───────────────────┐
│ Step 1: SFC Scan  │
└─────────┬─────────┘
          │
    ┌─────┴─────┐
    │           │
  OK (0)    Errors (2+)
    │           │
    │           ▼
    │   ┌───────────────────┐
    │   │ Step 2: DISM      │
    │   │ RestoreHealth     │
    │   └─────────┬─────────┘
    │             │
    │             ▼
    │   ┌───────────────────┐
    │   │ Step 3: DISM      │
    │   │ CheckHealth       │
    │   └─────────┬─────────┘
    │             │
    │             ▼
    │   ┌───────────────────┐
    │   │ Step 4: SFC       │ ← GOLD STANDARD
    │   │ Final Check       │
    │   └─────────┬─────────┘
    │             │
    └──────┬──────┘
           │
           ▼
    ┌───────────────────┐
    │ Step 5: Reboot    │
    └─────────┬─────────┘
              │
              ▼
        Repairs Applied
```

---

## 🛠️ Troubleshooting

### SFC Won't Run

**Error:** "Windows Resource Protection could not start"

**Fix:**
```batch
:: Boot into Safe Mode, then run:
sfc /scannow

:: Or use Windows Recovery Environment
```

### DISM Fails with Error 0x800f081f

**Meaning:** Windows Update source unavailable

**Fix:**
```batch
:: Use Windows installation media as source
DISM /Online /Cleanup-Image /RestoreHealth /Source:wim:X:\sources\install.wim:1 /LimitAccess
```
(Replace X: with your installation media drive letter)

### SFC Step 4 Still Shows Errors

**Meaning:** Corruption too severe for automatic repair

**Options:**
1. Run full sequence 2-3 more times
2. Use Windows installation media for source files
3. Consider in-place upgrade (preserves data)
4. Clean install (LAST RESORT)

---

## 📝 Log Files

**Location:** Same directory as script  
**Format:** `windows_repair_YYYYMMDD_HHMM.log`

**Contains:**
- Each step executed
- Error codes
- Results
- Timestamps

**View logs:**
- Option [7] in script menu
- Or open `.log` file in text editor

---

## ⚠️ Important Notes

### Administrator Rights REQUIRED

This script MUST be run as Administrator. Without elevated privileges:
- SFC cannot access protected files
- DISM cannot modify system image
- Repairs will fail silently

### Internet Connection Required

DISM Step 2 connects to Windows Update. Ensure:
- Active internet connection
- Windows Update service running
- No firewall blocking Windows Update

### Don't Interrupt the Process

Once started:
- Let each step complete fully
- Don't close the window
- Don't force restart mid-sequence

Interrupted repairs can cause MORE corruption.

### Step 4 is NOT Optional

Many technicians skip the final SFC check. **This is a mistake.**

**Why Step 4 matters:**
- DISM repairs the SOURCE (component store)
- SFC validates the INSTALLED files
- Without Step 4, you don't know if installed files match the repaired source

---

## 🎓 Professional Tips

### When to Use This Sequence

| Scenario | Use Sequence? |
|----------|---------------|
| Random BSOD errors | ✅ Yes |
| Windows Update failures | ✅ Yes |
| Missing/corrupt system files | ✅ Yes |
| Application crashes (system DLLs) | ✅ Yes |
| After malware removal | ✅ Yes |
| Before clean install | ✅ Yes (try this first!) |
| Hardware failure suspected | ❌ No (diagnose hardware first) |

### Expected Success Rate

| Issue Type | Success Rate |
|------------|--------------|
| Minor file corruption | 95%+ |
| Windows Update issues | 85%+ |
| BSOD (software cause) | 75%+ |
| Severe corruption | 50-70% |
| Hardware-related | 0% (not a software fix) |

### Time Investment

| Step | Typical Time |
|------|--------------|
| Step 1 (SFC Initial) | 5-15 min |
| Step 2 (DISM Restore) | 10-30 min |
| Step 3 (DISM Check) | <1 min |
| Step 4 (SFC Final) | 5-15 min |
| Step 5 (Reboot) | 1-3 min |
| **Total** | **20-60 min** |

**ROI:** 20-60 minutes vs. hours for clean install + data migration.

---

## 📚 Related Tools

### Built-In Windows Utilities

| Tool | Purpose |
|------|---------|
| `sfc` | System file repair |
| `DISM` | Image repair (component store) |
| `chkdsk` | Disk error checking |
| `bootrec` | Boot configuration repair |
| `bcdedit` | Boot configuration editor |

### Third-Party Alternatives (Not Recommended)

| Tool | Why Built-In is Better |
|------|------------------------|
| Various "PC repair" suites | SFC/DISM are Microsoft-official, free, no bloat |
| Registry cleaners | Often cause more problems than they fix |
| "Driver updaters" | Windows Update handles drivers better |

---

## 🏆 The Professional Difference

> **What separates a quick fix from a professional repair?**
>
> **Mastering this flow, including the critical 'final check' that many techs skip.**

**Amateur approach:**
1. Run SFC once
2. See errors
3. "Windows is broken, reinstall"

**Professional approach:**
1. SFC initial scan (diagnose)
2. DISM RestoreHealth (repair source)
3. DISM CheckHealth (verify repair)
4. SFC final check (validate installed files) ← **THE PRO MOVE**
5. Reboot (finalize)
6. Document results

---

## 📞 Support

**Script Issues:**
- Ensure running as Administrator
- Check Windows Update service is running
- Verify internet connection

**Persistent System Issues:**
- Run sequence 2-3 times
- Try Windows installation media as DISM source
- Consider hardware diagnostics (RAM, disk)
- In-place upgrade before clean install

---

**Remember:** A clean install is the ABSOLUTE LAST RESORT. This sequence has saved countless systems from unnecessary wipes.

☘️ **Quality over speed. Professional repairs take time.**
