#if TMNEXT

class PersonalBestData {
	uint64 achieved_time;
	uint64 time_played;
	uint64 finishes;
	uint64 resets;
	uint64 respawns;

	PersonalBestData() {}

	PersonalBestData(
			uint64 _achieved_time,
			uint64 _time_played,
			uint64 _finishes,
			uint64 _resets,
			uint64 _respawns
			) {
		achieved_time = _achieved_time;
		time_played = _time_played;
		finishes = _finishes;
		resets = _resets;
		respawns = _respawns;
	}

	PersonalBestData(Json::Value pb_object) {
		if ( pb_object.GetType() != Json::Type::Object )
			throw("Expected Json::Type::Object, received type #" + pb_object.GetType());
		achieved_time = uint64(double(pb_object["achieved_time"]));
		time_played = uint64(double(pb_object["time_played"]));
		finishes = uint64(double(pb_object["finishes"]));
		resets = uint64(double(pb_object["resets"]));
		respawns = uint64(double(pb_object["respawns"]));
	}

	Json::Value toJson() {
		Json::Value json = Json::Object();
		json['achieved_time'] = achieved_time;
		json['time_played'] = time_played;
		json['finishes'] = finishes;
		json['resets'] = resets;
		json['respawns'] = respawns;
		return json;
	}
}

class PersonalBests : BaseComponent {
	protected array<PersonalBestData@> personalbests; // With current PB at index 0 (if any).
	const AbstractData @grindstats;

	PersonalBests() {}

	PersonalBests(Json::Value pbs_array) {
		if ( pbs_array.GetType() != Json::Type::Array )
			throw("Expected Json::Type::Array, received type #" + pbs_array.GetType());
		for(uint i = 0 ; i < pbs_array.Length ; i++ )
			personalbests.InsertLast(PersonalBestData(pbs_array[i]));
		print("Loaded " + personalbests.Length + " PBs: " + toString());
	}

	~PersonalBests() { running = false; }

	void handler() override {
		while (this.running) {
			check_for_finish();
			yield();
		}
	}

	void check_for_finish() {
#if TMNEXT
		auto app = GetApp();
		if (app.RootMap is null)
			return;
		auto playground = app.CurrentPlayground;
		if (playground is null || playground.GameTerminals.Length == 0)
			return;
		auto terminal = playground.GameTerminals[0];
		auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
		if(gui_player is null)
			return;
		auto ui_sequence = terminal.UISequence_Current;
		if (ui_sequence != CGamePlaygroundUIConfig::EUISequence::Finish) {
			if(handled) {
				print("PersonalBests : reseting handling flag.");
				handled = false;
			}
			return;
		}
		if (handled)
			return;
		handled = true;

		// New finish, handle it.
		print("PersonalBests : handling new finish.");
		auto network = cast<CTrackManiaNetwork>(app.Network);
		if (network.ClientManiaAppPlayground is null)
			return;
		auto score_mgr = network.ClientManiaAppPlayground.ScoreMgr;
		auto user_mgr = network.ClientManiaAppPlayground.UserMgr;
		if (user_mgr.Users.Length == 0)
			return;
		MwId user_id = user_mgr.Users[0].Id;
		string mapuid = app.RootMap.MapInfo.MapUid;
		uint pb_time = score_mgr.Map_GetRecord_v2(user_id, mapuid, "PersonalBest", "", "TimeAttack", "");
		if (pb_time == uint(-1))
			return;
		print("Present PB = " + pb_time + " ; " +
			"previously known PB = " + (personalbests.Length == 0 ? "None" : Text::Format("%d", personalbests[0].achieved_time)));
		if (personalbests.Length == 0 || pb_time < personalbests[0].achieved_time) {
			// New PB, record it.
			// TODO: 2025-04-27 Can other coroutines be seriously out of sync ?
			print("PersonalBests : new personal best.");
			personalbests.InsertAt(0, PersonalBestData(
				pb_time,
				grindstats.timerComponent.total,
				grindstats.finishesComponent.total,
				grindstats.resetsComponent.total,
				grindstats.respawnsComponent.total
			));
		}
#endif
	}

	Json::Value toJson() {
		Json::Value@ json = Json::Array();
		for ( uint i = 0; i < personalbests.Length; i++ )
			json.Add(personalbests[i].toJson());
		return json;
	}

	string toString() override {
		return Json::Write(toJson());
	}
}

#endif