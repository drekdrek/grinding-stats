class DataManager {

	// Cloud @cloudData = Cloud();
	Files @localData = Files();

	bool auto_save_running = false;
	string mapId = "";

	DataManager() {
		startnew(CoroutineFunc(map_handler));
	}

	private void map_handler() {
		auto app = GetApp();
		while (true) {
			yield();
			if (app.Editor !is null)
				continue;
#if TMNEXT
			auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
			string mapId_now = (playground is null || playground.Map is null) ? "" : playground.Map.IdName;
#elif MP4
			auto rootmap = app.RootMap;
			string mapId_now = (rootmap is null) ? "" : rootmap.IdName;
#elif TURBO
			auto challenge = app.Challenge;
			string mapId_now = (challenge is null) ? "" : challenge.IdName;
#endif
			if (mapId_now == this.mapId)
				continue;

			// Map has changed.
			if (this.mapId != "" && this.mapId != "Unassigned") {
				print("Saving data & stopping coroutines for map \"" + this.mapId + "\"");
				auto_save_running = false;
				localData.stop_components();
				localData.save();
				// cloudData.stop();
				// cloudData.save();
			}

			this.mapId = mapId_now;
			localData = Files(this.mapId);

			if (this.mapId != "" && this.mapId != "Unassigned") {
				print("Loading data & starting coroutines for map \"" + this.mapId + "\"");
				localData.load();
				localData.start_components();
				startnew(CoroutineFunc(auto_save));
				// cloudData = Cloud(mapId);
				// if (setting_data_source == data_source::Cloud) { // not implemented yet
				//     cloudData.load();
				//     DataConflict::handle_conflict(localData, cloudData);
				// }
			}
		}
	}

  private void auto_save() {
		if (this.mapId == "" || this.mapId == "Unassigned")
			return;
		auto_save_running = true;
		uint64 start_time = Time::Now;
		while (auto_save_running) {
			if (Time::Now - start_time > setting_autosave_interval * 1000) {
				localData.save();
				start_time = Time::Now;
			}
			// so it can be stopped
			sleep(1000);
		}
	}

	Timer @get_timer() { return localData.timerComponent; }
	Finishes @get_finishes() { return localData.finishesComponent; }
	Resets @get_resets() { return localData.resetsComponent; }
	Respawns @get_respawns() { return localData.respawnsComponent; }

  private void set_timer(Timer @_) {}
  private void set_finishes(Finishes @_) {}
  private void set_resets(Resets @_) {}
  private void set_respawns(Respawns @_) {}
}