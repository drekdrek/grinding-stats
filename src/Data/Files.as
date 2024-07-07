class Files : AbstractData {
  private string folder_location = IO::FromStorageFolder("data");
  protected string file_location = folder_location;

	Files() {}

	Files(const string &in id) {
		super(id);
		if (id == "" || id == "Unassigned")
			return;
		file_location = folder_location + "/" + id + ".json";
	}

	void load() override {
		if (IO::FileExists(file_location)) {
			auto content = Json::FromFile(file_location);
			finishes = Text::ParseUInt64(content.Get("finishes", "0"));
			resets = Text::ParseUInt64(content.Get('resets', "0"));
			time = Text::ParseUInt64(content.Get('time', "0"));
			respawns = Text::ParseUInt64(content.Get('respawns', "0"));
			medals = content.Get('medals', Json::Array());
		}
		debug_print("Read finishes " + finishes + " resets " + resets +
					" time " + time + " respawns " + respawns + " from " +
					file_location);
		finishesComponent = Finishes(finishes);
		resetsComponent = Resets(resets);
		timerComponent = Timer(time);
		respawnsComponent = Respawns(respawns);
		medalsComponent = Medals(medals);
	}

	void save() override {
		if (mapUid == "" || mapUid == "Unassigned")
			return;
		auto content = Json::Object();
		content["finishes"] = Text::Format("%6d", finishes);
		content["resets"] = Text::Format("%6d", resets);
		content["time"] = Text::Format("%11d", time);
		content["respawns"] = Text::Format("%6d", respawns);

		Json::ToFile(file_location, content);

		debug_print("Wrote finishes " + finishes + " resets " + resets +
					" time " + time + " respawns " + respawns + " to " +
					file_location);
	}
}