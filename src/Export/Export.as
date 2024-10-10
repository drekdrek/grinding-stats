namespace GrindingStats {

import string time_to_string(uint64 time) from "Recap";
import string time_to_string(uint64 time, bool thousands) from "Recap";

uint64 get_total_time() {
	return data.localData.timerComponent.total;
}
uint64 get_session_time() {
	return data.localData.timerComponent.session;
}

uint64 get_total_finishes() {
	return data.localData.finishesComponent.total;
}
uint64 get_session_finishes() {
	return data.localData.finishesComponent.session;
}

uint64 get_total_resets() {
	return data.localData.resetsComponent.total;
}
uint64 get_session_resets() {
	return data.localData.resetsComponent.session;
}

uint64 get_total_respawns() {
	return data.localData.respawnsComponent.total;
}
uint64 get_session_respawns() {
	return data.localData.respawnsComponent.session;
}
uint64 get_current_respawns() {
	return data.localData.respawnsComponent.current;
}

} // namespace GrindingStats