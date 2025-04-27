class Files : AbstractData {
  private string folder_location = IO::FromStorageFolder("data");
  protected string file_location = folder_location;

	Files() {}

	Files(const string &in id) {
		super(id);
		if (id == "" || id == "Unassigned")
			return;
		if (!IO::FolderExists(folder_location))
			IO::CreateFolder(folder_location);

		file_location = folder_location + "/" + id + ".json";
	}

	void load() override {

		Json::Value personalbests_json = Json::Array();
		if (IO::FileExists(file_location)) {
			auto content = Json::FromFile(file_location);
			try {
				finishes = Text::ParseUInt64(content.Get("finishes", "0"));
				resets = Text::ParseUInt64(content.Get('resets', "0"));
				time = Text::ParseUInt64(content.Get('time', "0"));
				respawns = Text::ParseUInt64(content.Get('respawns', "0"));
				medals_string = content.Get('medals', "");
				personalbests_json = content.Get('personal_bests', Json::Array());
			} catch {
				debug_print("Failed to parse file, attempting to read old format");
				finishes = content.Get("finishes", "0");
				resets = content.Get('resets', "0");
				time = content.Get('time', "0");
				respawns = content.Get('respawns', "0");
				medals_string = content.Get('medals', "");
				personalbests_json = content.Get('personal_bests', Json::Array());
			}
		}
		if (medals_string == "" || medals_string == "[]")
			medals_string = '[{"medal":0,"achieved":false,"achieved_time":"          0"},{"medal":1,"achieved":false,"achieved_time":"          0"},{"medal":2,"achieved":false,"achieved_time":"          0"},{"medal":3,"achieved":false,"achieved_time":"          0"},{"medal":4,"achieved":false,"achieved_time":"          0"},{"medal":5,"achieved":false,"achieved_time":"          0"},{"medal":6,"achieved":false,"achieved_time":"          0"},{"medal":7,"achieved":false,"achieved_time":"          0"},{"medal":8,"achieved":false,"achieved_time":"          0"}]';
		debug_print("Read finishes " + finishes + " resets " + resets + " time " + time +
					" respawns " + respawns + "\nmedals " + medals_string + "\nfrom " + file_location);
		create_components();
		personalBestsComponent = PersonalBests(personalbests_json);
		@personalBestsComponent.grindstats = this;
	}

	void create_components() {
		finishesComponent = Finishes(finishes);
		resetsComponent = Resets(resets);
		timerComponent = Timer(time);
		respawnsComponent = Respawns(respawns);
		medalsComponent = Medals(medals_string);
	}

	void save() override {
		if (timerComponent.total < 5000 && finishesComponent.total == 0) {
			timerComponent.total = 0;
			resetsComponent.total = 0;
			respawnsComponent.total = 0;
			return;
		}

		if (mapUid == "" || mapUid == "Unassigned")
			return;
		auto content = Json::Object();
		finishes = finishesComponent.total;
		resets = resetsComponent.total;
		time = timerComponent.total;
		respawns = respawnsComponent.total;
		string medals_string = medalsComponent.export_medals_string();

		content["finishes"] = Text::Format("%6d", finishes);
		content["resets"] = Text::Format("%6d", resets);
		content["time"] = Text::Format("%11d", time);
		content["respawns"] = Text::Format("%6d", respawns);
		content["medals"] = medals_string;
		content["personal_bests"] = personalBestsComponent.toJson();

		Json::ToFile(file_location, content);

		debug_print("Wrote finishes " + finishes + " resets " + resets + " time " + time +
					" respawns " + respawns + "\nmedals " + medals_string + "\nto " + file_location);
	}
}