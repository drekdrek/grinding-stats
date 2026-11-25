class RecapElement {
	BaseMedal medal;
	string map_id;
	string name;
	string stripped_name;
	string time_string;
	uint64 time;
	uint64 finishes;
	uint64 resets;
	uint64 respawns;
	int64 updated_at;
#if MP4
	string titlepack;
#elif TURBO
	string environment;
#endif

	RecapElement() {}

	RecapElement(const string &in id, uint64 time, uint64 finishes, uint64 resets, uint64 respawns, int64 updated_at, BaseMedal @highest_medal, const string &in name, const string &in titlepack) {
#if MP4
		titlepack = titlepack;
#elif TURBO
		environment = titlepack;
#endif
		this.map_id = id;
		this.name = name;
		this.stripped_name = Text::StripFormatCodes(name).Replace('\\','');

		this.medal = highest_medal;
		this.time = time;
		this.time_string = Recap::time_to_string(this.time);
		this.finishes = finishes;
		this.resets = resets;
		this.respawns = respawns;
		this.updated_at = updated_at;
	}


}