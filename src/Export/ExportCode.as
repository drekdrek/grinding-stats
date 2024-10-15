namespace GrindingStats {

uint64 GetTotalTime() {
	if (data.localData !is null && data.localData.timerComponent !is null) {
		return data.localData.timerComponent.total;
	}
	return 0;
}

uint64 GetSessionTime() {
	if (data.localData !is null && data.localData.timerComponent !is null) {
		return data.localData.timerComponent.session;
	}
	return 0;
}

uint64 GetTotalFinishes() {
	if (data.localData !is null && data.localData.finishesComponent !is null) {
		return data.localData.finishesComponent.total;
	}
	return 0;
}

uint64 GetSessionFinishes() {
	if (data.localData !is null && data.localData.finishesComponent !is null) {
		return data.localData.finishesComponent.session;
	}
	return 0;
}

uint64 GetTotalResets() {
	if (data.localData !is null && data.localData.resetsComponent !is null) {
		return data.localData.resetsComponent.total;
	}
	return 0;
}

uint64 GetSessionResets() {
	if (data.localData !is null && data.localData.resetsComponent !is null) {
		return data.localData.resetsComponent.session;
	}
	return 0;
}

uint64 GetTotalRespawns() {
	if (data.localData !is null && data.localData.respawnsComponent !is null) {
		return data.localData.respawnsComponent.total;
	}
	return 0;
}

uint64 GetSessionRespawns() {
	if (data.localData !is null && data.localData.respawnsComponent !is null) {
		return data.localData.respawnsComponent.session;
	}
	return 0;
}

uint64 GetCurrentRespawns() {
	if (data.localData !is null && data.localData.respawnsComponent !is null) {
		return data.localData.respawnsComponent.current;
	}
	return 0;
}

} // namespace GrindingStats