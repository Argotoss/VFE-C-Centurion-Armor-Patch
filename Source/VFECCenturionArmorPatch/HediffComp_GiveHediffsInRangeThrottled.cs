using System;
using System.Collections.Generic;
using RimWorld;
using Verse;

namespace VFECCenturionArmorPatch
{
    public class HediffCompProperties_GiveHediffsInRangeThrottled : HediffCompProperties
    {
        public float range;
        public TargetingParameters targetingParameters;
        public HediffDef hediff;
        public float initialSeverity = 1f;
        public bool onlyPawnsInSameFaction;
        public int intervalTicks = 300;
        public int buffDurationTicks = 360;

        public HediffCompProperties_GiveHediffsInRangeThrottled()
        {
            compClass = typeof(HediffComp_GiveHediffsInRangeThrottled);
        }
    }

    public class HediffComp_GiveHediffsInRangeThrottled : HediffComp
    {
        private bool didInitialScan;

        public HediffCompProperties_GiveHediffsInRangeThrottled Props =>
            (HediffCompProperties_GiveHediffsInRangeThrottled)props;

        public override void CompPostTick(ref float severityAdjustment)
        {
            Pawn source = parent?.pawn;
            if (!CanApplyFrom(source))
            {
                return;
            }

            int intervalTicks = Math.Max(1, Props.intervalTicks);
            if (didInitialScan && !source.IsHashIntervalTick(intervalTicks))
            {
                return;
            }

            didInitialScan = true;
            ApplyBuffs(source, intervalTicks);
        }

        public override void CompExposeData()
        {
            base.CompExposeData();
            Scribe_Values.Look(ref didInitialScan, "didInitialScan");
        }

        private static bool CanApplyFrom(Pawn source)
        {
            return source != null
                && source.Awake()
                && source.health != null
                && !source.health.InPainShock
                && source.Spawned
                && source.Map != null;
        }

        private void ApplyBuffs(Pawn source, int intervalTicks)
        {
            if (Props.hediff == null)
            {
                Log.ErrorOnce("VFE-C Centurion Armor Patch: throttled aura has no target hediff configured.", 913401001);
                return;
            }

            IReadOnlyList<Pawn> pawns = PawnsToScan(source);
            if (pawns == null)
            {
                return;
            }

            for (int i = 0; i < pawns.Count; i++)
            {
                Pawn target = pawns[i];
                if (!CanAffect(source, target))
                {
                    continue;
                }

                Hediff hediff = target.health.hediffSet.GetFirstHediffOfDef(Props.hediff, false);
                if (hediff == null)
                {
                    hediff = target.health.AddHediff(Props.hediff, target.health.hediffSet.GetBrain());
                    hediff.Severity = Props.initialSeverity;
                }

                HediffComp_Disappears disappears = hediff.TryGetComp<HediffComp_Disappears>();
                if (disappears == null)
                {
                    Log.ErrorOnce("VFE-C Centurion Armor Patch: target buff needs HediffComp_Disappears so the throttled aura can refresh it.", 913401002);
                    continue;
                }

                disappears.ticksToDisappear = Math.Max(intervalTicks + 1, Props.buffDurationTicks);
            }
        }

        private IReadOnlyList<Pawn> PawnsToScan(Pawn source)
        {
            if (Props.onlyPawnsInSameFaction && source.Faction != null)
            {
                return source.Map.mapPawns.SpawnedPawnsInFaction(source.Faction);
            }

            return source.Map.mapPawns.AllPawnsSpawned;
        }

        private bool CanAffect(Pawn source, Pawn target)
        {
            if (target == null
                || target == source
                || target.Dead
                || target.health == null
                || target.RaceProps == null
                || !target.RaceProps.Humanlike
                || target.Position.DistanceTo(source.Position) > Props.range)
            {
                return false;
            }

            return Props.targetingParameters == null
                || Props.targetingParameters.CanTarget((TargetInfo)target, null);
        }
    }
}
