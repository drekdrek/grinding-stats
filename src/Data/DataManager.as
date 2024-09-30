class DataManager {

	Cloud @cloudData = Cloud();
	Files @localData = Files();

	DataManager() { startnew(CoroutineFunc(map_handler)); }

  private void map_handler() {
		string mapId = "";
		auto app = GetApp();
		while (true) {
#if TMNEXT
			auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
			mapId = (playground is null || playground.Map is null)
						? ""
						: playground.Map.IdName;
#elif MP4
			auto rootmap = app.RootMap;
			mapId = (rootmap is null) ? "" : rootmap.IdName;
#elif TURBO
			auto challenge = app.Challenge;
			mapId = (challenge is null) ? "" : challenge.IdName;
#endif
			if (mapId != localData.mapUid && app.Editor is null) {
				print("saving and loading data");
				// the map has changed and we are not in the editor.
				auto saving = startnew(CoroutineFunc(save));
				while (saving.IsRunning())
					yield();

				localData = Files(mapId);
				cloudData = Cloud(mapId);
				startnew(CoroutineFunc(load));
			}
			yield();
		}
	}

  private void save() {
		// stop the timers
		localData.timerComponent.stop();
		cloudData.timerComponent.stop();

		localData.save();
		cloudData.save();
	}
  private void load() {
		localData.load();
		// if (setting_data_source == data_source::Cloud) { // not implemented yet
		// 	cloudData.load();
		// 	DataConflict::handle_conflict(localData, cloudData);
		// }
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