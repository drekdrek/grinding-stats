abstract class AbstractData {
	string mapUid = "";
	bool loaded = false;
  protected uint64 time = 0;
  protected uint64 finishes = 0;
  protected uint64 resets = 0;
  protected uint64 respawns = 0;
  protected Json::Value medals = Json::Array();

	Finishes @finishesComponent = Finishes(0);
	Resets @resetsComponent = Resets(0);
	Respawns @respawnsComponent = Respawns(0);
	Timer @timerComponent = Timer(0);
	Medals @medalsComponent = Medals();

	AbstractData() {}

	AbstractData(const string &in id) {
		mapUid = id;
		start();
	}

	void save() {}

	void load() {}

	void start() {
		timerComponent.start();
		finishesComponent.start();
		resetsComponent.start();
		respawnsComponent.start();
		medalsComponent.start();
	}

	void overwrite(AbstractData @other) {
		time = other.time;
		finishes = other.finishes;
		resets = other.resets;
		respawns = other.respawns;
		medals = other.medals;
		load();
	}

	~AbstractData() {
		if (mapUid == "" || mapUid == "Unassigned")
			return;

		// if the data is exactly the same as the loaded data, then we don't
		// need to save it
		if (time == timerComponent.total &&
			finishes == finishesComponent.total &&
			resets == resetsComponent.total &&
			respawns == respawnsComponent.total)
			return;

		save();
	}

	void debug_print(const string &in text) { print(text); }

	uint64 get_time() { return time; }
	uint64 get_finishes() { return finishes; }
	uint64 get_resets() { return resets; }
	uint64 get_respawns() { return respawns; }
	Json::Value get_medals() {
		// return medals.get_medals();
		return Json::Array();
	}

	void set_time(uint64 _time) { time = _time; }
	void set_finishes(uint64 _finishes) { finishes = _finishes; }
	void set_resets(uint64 _resets) { resets = _resets; }
	void set_respawns(uint64 _respawns) { respawns = _respawns; }
	void set_medals(Json::Value _medals) { medals = _medals; }
}