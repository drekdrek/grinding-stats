namespace GrindingStats {

import string TimeToString(uint64 time) from "Recap";
import string TimeToString(uint64 time, bool thousands) from "Recap";

import uint64 GetTotalTime() from "GrindingStats";
import uint64 GetSessionTime() from "GrindingStats";

import uint64 GetTotalFinishes() from "GrindingStats";
import uint64 GetSessionFinishes() from "GrindingStats";

import uint64 GetTotalResets() from "GrindingStats";
import uint64 GetSessionResets() from "GrindingStats";

import uint64 GetTotalRespawns() from "GrindingStats";
import uint64 GetSessionRespawns() from "GrindingStats";
import uint64 GetCurrentRespawns() from "GrindingStats";

} // namespace GrindingStats