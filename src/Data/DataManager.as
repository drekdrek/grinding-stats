class DataManager {

	SQLite::Database@ db = SQLite::Database(IO::FromStorageFolder("data.db"));
	// Cloud @cloudData = Cloud();
	// Files @localData = Files();
	SQLite @localData = SQLite(db);
	
	
	bool auto_save_running = false;
	string mapId = "";

	DataManager() {
		startnew(CoroutineFunc(map_handler));
	}

	private void map_handler() {
		auto app = GetApp();
		while (true) {
			if (app.Editor !is null) {
				yield();
				continue;
			}
			string mapId_now = "";
#if TMNEXT
			auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
			if (playground !is null && playground.Map !is null)
				mapId_now = playground.Map.IdName;
#elif MP4
			auto rootmap = app.RootMap;
			if (rootmap !is null)
				mapId_now = rootmap.IdName;
#elif TURBO
			auto challenge = app.Challenge;
			if (challenge !is null)
				mapId_now = challenge.IdName;
#endif
			if (mapId_now == this.mapId) {
				yield();
				continue;
			}

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
			localData = SQLite(db, this.mapId);
			// cloudData = Cloud(mapId);

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
			yield();
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