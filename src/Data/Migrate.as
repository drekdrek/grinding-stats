class Migrate {
	bool needed = false;
	bool running = false;
	uint64 total = 1;
	uint64 current = 0;
	array<string> old;
	uint64 per_chunk = 0;
	uint chunk_size = 250;

	Migrate() {
		string old_path = IO::FromStorageFolder("data");
		needed = IO::FolderExists(old_path);
		if (needed) {
		old = IO::IndexFolder(old_path, true);
		total = old.Length;
		}
	}

	void start() {
		running = true;
		migrateToSQLite();
		needed = false;
		running = false;
	}

	void UI() {

		UI::Begin("Grinding Stats SQLite Migration", UI::WindowFlags::NoCollapse |
					   UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking);
			auto windowWidth = UI::GetWindowSize();
			string text = "You have "+ total + " tracks in Grinding Stats\n" +
						  "This will take an estimated "+ this.initialEstimatedTime() +"\n" +
						  "~10-15 seconds per 1000 tracks\n\n" +
						  "You can play a track while is this working,\n"+
						  " however performance may be impacted";
			vec2 textWidth = UI::MeasureString(text);
			UI::SetCursorPos(vec2(windowWidth.x / 2 - textWidth.x / 2, 25));
			UI::Text(text);
			UI::SetCursorPos(vec2(windowWidth.x / 2 - 100, windowWidth.y / 2 + 15));

			UI::BeginDisabled(this.running || !this.needed);
			if (UI::Button("Migrate", vec2(200, 50))) {
				if (current < total) {
				startnew(CoroutineFunc(this.start));
				}
			}
			UI::EndDisabled();
			// UI::SetCursorPos(vec2( windowWidth.x/1.75, windowWidth.y / 2 + 65));
			float progress = current/float(total);
			UI::ProgressBar(progress, vec2(300,20), current + "/" + total + " (" + Text::Format("%.2f",progress* 100) + "%)");
			if (current != 0) {
			UI::Text("Estimated Time Remaining: " + this.estimatedTimeRemaining());
			}
		UI::End();
	}

private string initialEstimatedTime() {
	// for every 1000 items it takes 10-15 seconds
	return Time::Format(uint(this.total * 12.5), false);
}
private string estimatedTimeRemaining() {
	if (this.current > this.chunk_size) {
	// based on how long it has taken to do the last chunk of items
	uint64 remaining = this.total - this.current;
	float hundred_left = remaining / float(this.chunk_size);
	return Time::Format(uint64(hundred_left * this.per_chunk), false);
	} else 
	return Time::Format(uint((this.total - this.current) * 12.5), false);
}


void migrateToSQLite() {
	print("starting");
	uint64 finishes = 0;
	uint64 resets = 0;
	uint64 time = 0;
	uint64 respawns = 0;
	string medals_string = "";
	uint i;
	
	if (needed) {
		UI::ShowNotification("Grinding Stats", "Found old data folder, attempting to ingest into SQLite.", UI::HSV(0.10f, 1.0f, 1.0f), 2500);
		string grind_insert = """
		INSERT INTO grinds (map_id, time, finishes, resets, respawns, updated_at)
		VALUES (?,?,?,?,?,?) 
		ON CONFLICT(map_id)
		DO UPDATE SET time=excluded.time, finishes=excluded.finishes, resets=excluded.resets, respawns=excluded.respawns, updated_at=excluded.updated_at;
		""";
		uint64 per_chunk_start = Time::Now;
		for (i = 0; i< total; i++, current++) {
		// for (i = 0; i < 0; i++, current++) {
		if (current != 0 && current % this.chunk_size == 0) {
			uint64 now = Time::Now;
			this.per_chunk = now - per_chunk_start;
			per_chunk_start = now; 

		}
			SQLite::Statement@ grinds = data.db.Prepare(grind_insert);
			const string[] @parts = old[i].Split("/");
			const string map_id = parts[parts.Length - 1].Split(".")[0];  
			Json::Value@ content = Json::FromFile(old[i]);
			try {
				finishes = Text::ParseUInt64(content.Get("finishes", "0"));
				resets = Text::ParseUInt64(content.Get('resets', "0"));
				time = Text::ParseUInt64(content.Get('time', "0"));
				respawns = Text::ParseUInt64(content.Get('respawns', "0"));
				medals_string = content.Get('medals', "");
			} catch {
				finishes = content.Get("finishes", 0);
				resets = content.Get('resets', 0);
				time = content.Get('time', 0);
				respawns = content.Get('respawns', 0);
				medals_string = content.Get('medals', "");
			}

			grinds.Bind(1, map_id);
			grinds.Bind(2, time);
			grinds.Bind(3, finishes);
			grinds.Bind(4, resets);
			grinds.Bind(5, respawns);
			grinds.Bind(6, IO::FileModifiedTime(old[i]));
			grinds.Execute();

			if (medals_string != "" && medals_string != "[]") {
			Migrate::insert_medals(map_id, medals_string);
			}
			sleep(5);
		}
	}
	print("finished");

}

void insert_medals(const string &in map_id, const string &in medals_string) {
	Json::Value@ medals = Json::Parse(medals_string);

	string medals_insert = """
	INSERT INTO medals (map_id, medal_id, achieved, achieved_time)
		VALUES (?,?,?,?) ON CONFLICT (map_id, medal_id) DO UPDATE SET achieved=excluded.achieved, achieved_time=excluded.achieved_time;
	""";

	for (uint i = 0; i < medals.Length; i++) {
		Json::Value@ medal = medals[i];
		if (!bool(medal.Get("achieved"))) break;
		
		SQLite::Statement@ insert = data.db.Prepare(medals_insert);
		insert.Bind(1, map_id);
		insert.Bind(2, int(medal.Get("medal")));
		insert.Bind(3, bool(medal.Get("achieved")) ? 1: 0);
		{
			auto achieved_time = medal.Get("achieved_time");
			try {
				insert.Bind(4, uint64(achieved_time));
			} catch {
				insert.Bind(4, uint64(Text::ParseUInt64(achieved_time)));
			}
		}
		insert.Execute();
	}
}


void migrateOldData() {
	auto old_path = IO::FromDataFolder("Grinding Stats");
	if (IO::FolderExists(old_path)) {
		UI::ShowNotification("Grinding Stats", "Found old data folder, attempting to merge data together.", UI::HSV(0.10f, 1.0f, 1.0f), 2500);
		auto new_path = IO::FromStorageFolder("data");
		if (IO::FolderExists(new_path)) {
			UI::ShowNotification("Grinding Stats", "Data migration failed.\nAttempting to merge data together.", UI::HSV(0.10f, 1.0f, 1.0f), 7500);
			warn("The new data folder already exists.\tOld path: " + old_path + "\tnew path: " + new_path);
			await(startnew(CoroutineFunc(mergeData)));
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


}