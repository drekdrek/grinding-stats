class DataManager {

	SQLite::Database@ db = SQLite::Database(IO::FromStorageFolder("data.db"));
	// Cloud @cloudData = Cloud();
	Files @localData = Files();

	bool auto_save_running = false;
	string mapId = "";

	DataManager() { startnew(CoroutineFunc(map_handler)); }

  private void map_handler() {
		auto app = GetApp();
		while (true) {
#if TMNEXT
			auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
			this.mapId = (playground is null || playground.Map is null) ? "" : playground.Map.IdName;
#elif MP4
			auto rootmap = app.RootMap;
			this.mapId = (rootmap is null) ? "" : rootmap.IdName;
#elif TURBO
			auto challenge = app.Challenge;
			this.mapId = (challenge is null) ? "" : challenge.IdName;
#endif
			if (this.mapId != localData.mapUid && app.Editor is null) {
				print("saving and loading data");
				// the map has changed and we are not in the editor.
				auto_save_running = false;
				auto saving = startnew(CoroutineFunc(save));
				while (saving.IsRunning())
					yield();

				localData = Files(this.mapId);
				// cloudData = Cloud(mapId);
				startnew(CoroutineFunc(load));

				startnew(CoroutineFunc(auto_save));
			}
			yield();
		}
	}

  private void save() {
		// stop the timers
		localData.timerComponent.stop();
		// cloudData.timerComponent.stop();

		localData.save();
		// cloudData.save();
	}

  private void load() {
		localData.load();
		// if (setting_data_source == data_source::Cloud) { // not implemented yet
		//     cloudData.load();
		//     DataConflict::handle_conflict(localData, cloudData);
		// }
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