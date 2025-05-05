#if TMNEXT

class PersonalBestData {
	uint64 achieved_time;
	uint64 time_played;
	uint64 finishes;
	uint64 resets;
	uint64 respawns;
	bool witnessed; // False marks PBs that couldn't be recorded live.

	PersonalBestData() {}

	PersonalBestData(uint64 _achieved_time,
					 uint64 _time_played,
					 uint64 _finishes,
					 uint64 _resets,
					 uint64 _respawns,
					 bool _witnessed) {
		achieved_time = _achieved_time;
		time_played = _time_played;
		finishes = _finishes;
		resets = _resets;
		respawns = _respawns;
		witnessed = _witnessed;
	}

	PersonalBestData(Json::Value pb_object) {
		if (pb_object.GetType() != Json::Type::Object)
			throw("Expected Json::Type::Object, received enum type " + pb_object.GetType());
		achieved_time = Text::ParseUInt64(pb_object["achieved_time"]);
		time_played = Text::ParseUInt64(pb_object["time_played"]);
		finishes = Text::ParseUInt64(pb_object["finishes"]);
		resets = Text::ParseUInt64(pb_object["resets"]);
		respawns = Text::ParseUInt64(pb_object["respawns"]);
		witnessed = pb_object["witnessed"];
	}

	Json::Value toJson() {
		Json::Value json = Json::Object();
		json['achieved_time'] = Text::Format("%d", achieved_time);
		json['time_played'] = Text::Format("%d", time_played);
		json['finishes'] = Text::Format("%d", finishes);
		json['resets'] = Text::Format("%d", resets);
		json['respawns'] = Text::Format("%d", respawns);
		json['witnessed'] = witnessed;
		return json;
	}
}

class PersonalBests : BaseComponent {
	protected array<PersonalBestData@> personalbests; // With current PB at index 0 (if any).

	PersonalBests() {}

	PersonalBests(Json::Value pbs_array) {
		if (pbs_array.GetType() != Json::Type::Array)
			throw("Expected Json::Type::Array, received enum type " + pbs_array.GetType());
		for(uint i = 0 ; i < pbs_array.Length ; i++)
			personalbests.InsertLast(PersonalBestData(pbs_array[i]));
		debug_print("Loaded PB history: " + toString());
	}

	~PersonalBests() { running = false; }

	void handler() override {
		while (this.running) {
			if (GetApp().RootMap is null)
				break;
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
				debug_print("Reseting handling flag.");
				handled = false;
			}
			return;
		}
		if (handled)
			return;
		handled = true;

		// New finish, check if it's a new PB.
		// TODO: 2025-04-27 Can other grindstats coroutines be seriously out of sync ?
		debug_print("Handling new finish.");
		uint pb_time = get_pb_time();
		if (pb_time == uint(-1))
			return;
		debug_print("Present PB = " + pb_time +
			" ; vs previously known PB = " +
			(personalbests.Length == 0 ? "None" : Text::Format("%d", personalbests[0].achieved_time)));
		if (personalbests.Length == 0 || pb_time < personalbests[0].achieved_time) {
			record_personalbest(pb_time, true);
			debug_print("New PB! Current PBs: " + toString());
		}
#endif
	}

	void record_personalbest(uint64 pb_time, bool witnessed) {
		const AbstractData @grindstats = data.localData;
		personalbests.InsertAt(0, PersonalBestData(
			pb_time,
			grindstats.timerComponent.total,
			grindstats.finishesComponent.total,
			grindstats.resetsComponent.total,
			grindstats.respawnsComponent.total,
			witnessed
		));
	}

	// If the user has a PB on the map that the GrindingStats JSON didn't know about, record it.
	void record_unwitnessed_pb_if_any() {
		uint pb_time = get_pb_time();
		if (pb_time == 0 or pb_time == uint(-1))
			return;
		if (personalbests.Length == 0 or pb_time < personalbests[0].achieved_time) {
			record_personalbest(pb_time, false);
			debug_print("Recorded new unwitnessed PB ; current PBs: " + toString());
		}
	}

	Json::Value toJson() {
		Json::Value@ json = Json::Array();
		for (uint i = 0; i < personalbests.Length; i++)
			json.Add(personalbests[i].toJson());
		return json;
	}

	string toString() override {
		return Json::Write(toJson());
	}

	void debug_print(const string &in s) {
		// print("PersonalBests: " + s);
	}

	uint get_pb_time() {
		auto app = cast<CTrackMania>(GetApp());
		auto network = cast<CTrackManiaNetwork>(app.Network);

#if TMNEXT || MP4
		auto map = app.RootMap;
#elif TURBO
		auto map = app.Challenge;
#endif
		if (map is null)
			return 0;

#if TMNEXT
		if (network.ClientManiaAppPlayground !is null) {
			auto user_mgr = network.ClientManiaAppPlayground.UserMgr;
			MwId user_id;
			if (user_mgr.Users.Length > 0) {
				user_id = user_mgr.Users[0].Id;
			} else {
				user_id.Value = uint(-1);
			}

			auto score_mgr = app.Network.ClientManiaAppPlayground.ScoreMgr;
			uint pb_time = score_mgr.Map_GetRecord_v2(user_id, map.MapInfo.MapUid, "PersonalBest", "", "TimeAttack", "");
			return pb_time;
		}
#elif MP4
		if (network.TmRaceRules !is null && network.TmRaceRules.ScoreMgr !is null) {
			auto score_mgr = network.TmRaceRules.ScoreMgr;
			uint pb_time = score_mgr.Map_GetRecord(network.PlayerInfo.Id, map.MapInfo.MapUid, "");
			return pb_time;
		} else {
			int score = -1;
			if (app.CurrentProfile !is null && app.CurrentProfile.AccountSettings !is null) {
				for (uint i = 0; i < app.ReplayRecordInfos.Length; i++) {
					if (app.ReplayRecordInfos[i] !is null && app.ReplayRecordInfos[i].MapUid == map.MapInfo.MapUid && app.ReplayRecordInfos[i].PlayerLogin == app.CurrentProfile.AccountSettings.OnlineLogin) {
						auto record = app.ReplayRecordInfos[i];
						if (score < 0 || record.BestTime < uint(score)) {
							score = int(record.BestTime);
						}
					}
					if (i & 0xff == 0xff) {
						yield();
						if (app.CurrentProfile is null || app.CurrentProfile.AccountSettings is null || app.ReplayRecordInfos.Length <= i) {
							warn("Game state changed while scanning records. Retrying in 500ms...");
							break;
						}
					}
				}
			}
			if (app.CurrentPlayground !is null && app.CurrentPlayground.GameTerminals.Length > 0 &&
				cast<CTrackManiaPlayer>(app.CurrentPlayground.GameTerminals[0].GUIPlayer) !is null &&
				cast<CTrackManiaPlayer>(app.CurrentPlayground.GameTerminals[0].GUIPlayer).Score !is null) {
				int sessScore = int(cast<CTrackManiaPlayer>(app.CurrentPlayground.GameTerminals[0].GUIPlayer).Score.BestTime);
				if (sessScore > 0 && (score < 0 || sessScore < score)) {
					score = sessScore;
				}
			}
			return score;
		}

#elif TURBO
		if (network.TmRaceRules !is null) {
			auto dataMgr = network.TmRaceRules.DataMgr;
			dataMgr.RetrieveRecordsNoMedals(map.MapInfo.MapUid, dataMgr.MenuUserId);
			yield();
			while (!dataMgr.Ready)
				yield();
			for (uint i = 0; i < dataMgr.Records.Length; i++) {
				if (dataMgr.Records[i].GhostName == "Solo_BestGhost") {
					return dataMgr.Records[i].Time;
				}
			}
		}
#endif
		return 0;
	}
}

#endif