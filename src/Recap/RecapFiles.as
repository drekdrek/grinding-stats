class RecapFiles : Files {

	RecapFiles() {}

	RecapFiles(const string &in id) {
		super(id);
		load();
	}

	void debug_print(const string &in text) override {} // don't need to print
	void save() override {}								// don't need to save the files

	void load() override {
		if (IO::FileExists(file_location)) {
			auto content = Json::FromFile(file_location);
			try {
				finishes = Text::ParseUInt64(content.Get("finishes", "0"));
				resets = Text::ParseUInt64(content.Get('resets', "0"));
				time = Text::ParseUInt64(content.Get('time', "0"));
				respawns = Text::ParseUInt64(content.Get('respawns', "0"));
				medals_string = content.Get('medals', "");
			} catch {
				debug_print("Failed to parse file, attempting to read old format");
				finishes = content.Get("finishes", "0");
				resets = content.Get('resets', "0");
				time = content.Get('time', "0");
				respawns = content.Get('respawns', "0");
				medals_string = content.Get('medals', "");
			}
		}
		if (medals_string == "" || medals_string == "[]")
			medals_string = '[{"medal":0,"achieved":false,"achieved_time":"          0"},{"medal":1,"achieved":false,"achieved_time":"          0"},{"medal":2,"achieved":false,"achieved_time":"          0"},{"medal":3,"achieved":false,"achieved_time":"          0"},{"medal":4,"achieved":false,"achieved_time":"          0"},{"medal":5,"achieved":false,"achieved_time":"          0"},{"medal":6,"achieved":false,"achieved_time":"          0"},{"medal":7,"achieved":false,"achieved_time":"          0"},{"medal":8,"achieved":false,"achieved_time":"          0"}]';
		debug_print("Read finishes " + finishes + " resets " + resets + " time " + time + " respawns " + respawns + "\nmedals " + medals_string + "\nfrom " + file_location);
	}

	void start() override {} // don't need to start the handlers

	int64 get_modified_time() { return IO::FileModifiedTime(file_location); }
}