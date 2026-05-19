# VFE Classical - Centurion Armor Performance Patch

RimWorld 1.6 patch mod for Vanilla Factions Expanded - Classical.

The original Centurion Armor aura uses `HediffCompProperties_GiveHediffsInRange`, which scans eligible pawns every tick and refreshes `VFEC_CenturionArmorBuff` with a 5-tick timeout. This patch keeps the buff but replaces that comp with a throttled implementation that scans every 300 ticks.

The patch also removes the buff's `HediffCompProperties_Link`, avoiding the per-tick visual tether maintenance on buffed pawns.

## Build

```powershell
powershell -ExecutionPolicy Bypass -File .\Scripts\Build.ps1
```

The build script compiles `1.6\Assemblies\VFECCenturionArmorPatch.dll` against the local RimWorld 1.6 managed assemblies.
