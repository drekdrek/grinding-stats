
DataManager data;
Recap recap;

void Main() {
#if TURBO
	startnew(CoroutineFunc(TurboSTM::LoadSuperTimes));
#endif
#if DEPENDENCY_NADEOSERVICES
	NadeoServices::AddAudience("NadeoLiveServices");
#endif
	if (setting_recap_show_menu && !recap.started) {
		recap.start();
	}

	migrateOldData();
	startnew(CoroutineFunc(migrateToSQLite));
}

void migrateToSQLite() {
	print("starting");
	uint64 finishes = 0;
	uint64 resets = 0;
	uint64 time = 0;
	uint64 respawns = 0;
	string medals_string = "";

	
	auto old_path = IO::FromStorageFolder("data");
	if (IO::FolderExists(old_path)) {
		UI::ShowNotification("Grinding Stats", "Found old data folder, attempting to ingest into SQLite.", UI::HSV(0.10f, 1.0f, 1.0f), 2500);
		auto old = IO::IndexFolder(old_path, true);
		int BATCH_AMOUNT = 50;
		uint batches = uint(Math::Ceil(old.Length / float(BATCH_AMOUNT)));
		for (uint i = 0, idx = 0; i < batches; i++) {
			uint amt = Math::Min(BATCH_AMOUNT, Math::Max(0, old.Length - (i * BATCH_AMOUNT)));
			string grinds_insert = """
			INSERT INTO grinds (map_id, time, finishes, resets, respawns, updated_at)
			VALUES
			""";
			for (uint a = 0; a < amt - 1; a++) {
				grinds_insert = grinds_insert + "(?,?,?,?,?,?),\n";
			}
			grinds_insert = grinds_insert +
			"""(?,?,?,?,?,?)
			ON CONFLICT(map_id)
			DO UPDATE SET time=excluded.time, finishes=excluded.finishes, resets=excluded.resets, respawns=excluded.respawns, updated_at=excluded.updated_at;
			""";
			auto grinds_query = data.db.Prepare(grinds_insert);
			for (uint j = 0; j < amt; j++, idx = i * BATCH_AMOUNT + j ) {
				
			
				const string[] @parts = old[idx].Split("/");
				const string map_id = parts[parts.Length - 1].Split(".")[0];
				Json::Value@ content = Json::FromFile(old[idx]);
				// print(map_id); 
				
				try {
					finishes = Text::ParseUInt64(content.Get("finishes", "0"));
					resets = Text::ParseUInt64(content.Get('resets', "0"));
					time = Text::ParseUInt64(content.Get('time', "0"));
					respawns = Text::ParseUInt64(content.Get('respawns', "0"));
					medals_string = content.Get('medals', "");
				} catch {
					finishes = content.Get("finishes", "0");
					resets = content.Get('resets', "0");
					time = content.Get('time', "0");
					respawns = content.Get('respawns', "0");
					medals_string = content.Get('medals', "");
				}
				grinds_query.Bind(j * 6+1, map_id);
				grinds_query.Bind(j * 6+2, time);
				grinds_query.Bind(j * 6+3, finishes);
				grinds_query.Bind(j * 6+4, resets);
				grinds_query.Bind(j * 6+5, respawns);
				grinds_query.Bind(j * 6+6, IO::FileModifiedTime(old[idx]));

				if (medals_string == "" || medals_string == "[]")
				medals_string = '{"map_id": "' + map_id + '","medals":[{"medal": 0,"achieved": false,"achieved_time": 0},{"medal": 1,"achieved": false,"achieved_time": 0},{"medal": 2,"achieved": false,"achieved_time": 0},{"medal": 3,"achieved": false,"achieved_time": 0},{"medal": 4,"achieved": false,"achieved_time": 0},{"medal": 5,"achieved": false,"achieved_time": 0},{"medal": 6,"achieved": false,"achieved_time": 0},{"medal": 7,"achieved": false,"achieved_time": 0},{"medal": 8,"achieved": false,"achieved_time": 0}]}';
					

				startnew(CoroutineFuncUserdata(insert_medals),Json::Parse(medals_string));
			}
			// print(grinds_query.GetQueryExpanded());
			grinds_query.Execute();
			print(i + "/" + batches + " (" + i/float(batches) +"%)");
				
			sleep(250);
		}
	}
	print("finished");

}

void insert_medals(ref@ medals_ref) {
				
				Json::Value@ medals = cast<Json::Value@>(medals_ref);
				string medals_insert = """
			INSERT INTO medals (map_id, medal_id, achieved, achieved_time)
				VALUES
			""";
			for (uint a = 0; a < medals["medals"].Length - 1; a++) {
				medals_insert = medals_insert + "(?,?,?,?),\n";
			}
			medals_insert = medals_insert +
			"""(?,?,?,?)
			ON CONFLICT(map_id, medal_id)
				DO UPDATE SET achieved=excluded.achieved, achieved_time=excluded.achieved_time;
			""";
				string map_id = medals["map_id"];
				medals = medals["medals"];
				auto medals_query = data.db.Prepare(medals_insert);
				for (uint i = 0; i < medals.Length; i++) {
					medals_query.Bind(i*4 + 1,map_id);
					medals_query.Bind(i*4 + 2, int(medals[i].Get("medal")));
					medals_query.Bind(i*4 + 3, bool(medals[i].Get("achieved")) ? 1 : 0);
					medals_query.Bind(i*4 + 4, uint64(medals[i].Get("achieved_time")));
				}
				medals_query.Execute();
}


void migrateOldData() {
	auto old_path = IO::FromDataFolder("Grinding Stats");
	if (IO::FolderExists(old_path)) {
		UI::ShowNotification("Grinding Stats", "Found old data folder, attempting to merge data together.", UI::HSV(0.10f, 1.0f, 1.0f), 2500);
		auto new_path = IO::FromStorageFolder("data");
		if (IO::FolderExists(new_path)) {
			UI::ShowNotification("Grinding Stats", "Data migration failed.\nAttempting to merge data together.", UI::HSV(0.10f, 1.0f, 1.0f), 7500);
			warn("The new data folder already exists.\tOld path: " + old_path + "\tnew path: " + new_path);
			Meta::PluginCoroutine @merge = startnew(CoroutineFunc(mergeData));
			while (merge.IsRunning())
				yield();
		}
		IO::Move(old_path, new_path);
		if (IO::IndexFolder(old_path, true).Length == 0) {
			IO::DeleteFolder(old_path);
		}
	}
}

void mergeData() {
	auto old_path = IO::FromDataFolder("Grinding Stats");
	auto new_path = IO::FromStorageFolder("data");

	auto old = IO::IndexFolder(old_path, true);
	auto new = IO::IndexFolder(new_path, true);
	for (uint i = 0; i < old.Length; i++) {
		const string[] @parts = old[i].Split("/");
		const string base_name = parts[parts.Length - 1];
		print("moving " + old[i] + " to " + new_path + "/" + base_name);
		IO::Move(old[i], new_path + "/" + base_name);

		yield();
	}

	if (IO::IndexFolder(old_path, true).Length == 0) {
		IO::DeleteFolder(old_path);
		UI::ShowNotification("Grinding Stats", "Completed Data Transfer", UI::HSV(0.35f, 1.0f, 1.0f), 10000);
	} else {
		UI::ShowNotification("Grinding Stats", "There was a conflict with file names, please manually merge the data folders", UI::HSV(1.0f, 1.0f, 1.0f), 10000);
	}
}
