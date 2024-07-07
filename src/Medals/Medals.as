namespace Medals {
enum Type {
	Bronze = 0,
	Silver = 1,
	Gold = 2,
#if TMNEXT || MP4
	Author = 3,
#elif TURBO
	Trackmaster = 3,
	S_Bronze = 4,
	S_Silver = 5,
	S_Gold = 6,
	S_Trackmaster = 7,
#endif
#if TMNEXT && DEPENDENCY_CHAMPIONMEDALS
	Champion = 4
#elif MP4 && DEPENDENCY_DUCKMEDALS
	Duck = 4
#elif TURBO && DEPENDENCY_DUCKMEDALS
	Duck = 8
#endif
}

string to_string(Medals::Type type) {
	switch (type) {
	case Medals::Type::Bronze:
		return "Bronze";
	case Medals::Type::Silver:
		return "Silver";
	case Medals::Type::Gold:
		return "Gold";
#if TMNEXT || MP4
	case Medals::Type::Author:
		return "Author";
#elif TURBO
	case Medals::Type::Trackmaster:
		return "Trackmaster";
	case Medals::Type::S_Bronze:
		return "S. Bronze";
	case Medals::Type::S_Silver:
		return "S. Silver";
	case Medals::Type::S_Gold:
		return "S. Gold";
	case Medals::Type::S_Trackmaster:
		return "S. Trackmaster";
#endif
#if TMNEXT && DEPENDENCY_CHAMPIONMEDALS
	case Medals::Type::Champion:
		return "Champion";
#elif MP4 && DEPENDENCY_DUCKMEDALS
	case Medals::Type::Duck:
		return "Duck";
#elif TURBO && DEPENDENCY_DUCKMEDALS
	case Medals::Type::Duck:
		return "Duck";
#endif
	}
	return "";
}
} // namespace Medals

class Medals : BaseComponent {
  private array<BaseMedal @> medals = array<BaseMedal @>();
	bool first_run = true;

	Medals(){};

	Medals(Json::Value @_medals) {
		print("Medals constructor with _medals");
		Json::Value @m = Json::Array();
		if (_medals.Length == 0) {
			// default medals

			m = Json::Parse(
				'[{"medal":0,"achieved":-1},{"medal":1,"achieved":-1},{"medal":2,"achieved":-1},{"medal":3,"achieved":-1},{"medal":4,"achieved":-1},{"medal":5,"achieved":-1},{"medal":6,"achieved":-1},{"medal":7,"achieved":-1},{"medal":8,"achieved":-1}]');
		} else {
			m = _medals;
		}
		build_medals(m);
	}
	BaseMedal @get_highest_medal() {
		// for all medals in the medal array, find the last medal in the array
		// that has been achieved returns null if none have been achieved return
		// the medal

		int candidate = -1;
		for (uint i = 0; i < this.medals.Length; i++) {
			BaseMedal @medal = this.medals[i];
			if (medals[i].achieved) {
				candidate = i;
			}
		}
		if (candidate == -1)
			return null;
		return this.medals[candidate];
	}

	void handler() override {

		while (running) {
			// check once when this function first runs
			if (first_run) {
				first_run = false;
#if TURBO
				// pb was 0 on turbo for some reason, so i wait for a second to
				// make sure that it loads
				sleep(1000);
#endif
				check_medals();
			}
			// check every time the user finishes
			auto app = GetApp();
#if TMNEXT || MP4
			auto map = app.RootMap;
#elif TURBO
			auto map = app.Challenge;
#endif
			if (map is null)
				return;
			auto playground = app.CurrentPlayground;
			auto network = cast<CTrackManiaNetwork>(app.Network);
			if (playground !is null && playground.GameTerminals.Length > 0) {
				auto terminal = playground.GameTerminals[0];
#if TMNEXT
				auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
				auto ui_sequence = terminal.UISequence_Current;
				if (gui_player !is null) {
					if (!handled &&
						ui_sequence ==
							CGamePlaygroundUIConfig::EUISequence::Finish) {
						handled = true;
						check_medals();
					}
					if (handled &&
						ui_sequence !=
							CGamePlaygroundUIConfig::EUISequence::Finish)
						handled = false;
				}
#elif MP4
				auto gui_player = cast<CTrackManiaPlayer>(terminal.GUIPlayer);
				if (gui_player !is null) {
					auto race_state = gui_player.ScriptAPI.RaceState;
					if (!handled &&
						race_state == CTrackManiaPlayer::ERaceState::Finished) {
						handled = true;
						check_medals();
					}
					if (handled &&
						race_state != CTrackManiaPlayer::ERaceState::Finished)
						handled = false;
				}
#elif TURBO
				auto gui_player =
					cast<CTrackManiaPlayer>(terminal.ControlledPlayer);
				if (gui_player !is null) {
					auto race_state = gui_player.RaceState;
					if (!handled &&
						race_state == CTrackManiaPlayer::ERaceState::Finished &&
						!network.PlaygroundClientScriptAPI.IsSpectator) {
						handled = true;
						check_medals();
					}
					if (handled &&
						race_state != CTrackManiaPlayer::ERaceState::Finished)
						handled = false;
				}
#endif
			}
			yield();
		}
	}

	void check_medals() {
		print("Checking medals");
		uint pb = get_pb_time();
		print("PB: " + pb);
		for (uint i = 0; i < medals.Length; i++) {
			medals[i].check_pb(pb);
		}
	}

	uint get_pb_time() {
		auto app = cast<CTrackMania>(GetApp());
		auto network = cast<CTrackManiaNetwork>(app.Network);

#if TMNEXT || MP4
		auto map = app.RootMap;
#elif TURBO
		auto map = app.Challenge;
#endif
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
			uint pb_time = score_mgr.Map_GetRecord_v2(
				user_id, map.MapInfo.MapUid, "PersonalBest", "", "TimeAttack",
				"");
			return pb_time;
		}
#elif MP4
		if (network.TmRaceRules !is null &&
			network.TmRaceRules.ScoreMgr !is null) {
			auto score_mgr = network.TmRaceRules.ScoreMgr;
			uint pb_time = score_mgr.Map_GetRecord_v2(
				data_mgr.MenuUserId, map.MapInfo.MapUid, "PersonalBest", "",
				"TimeAttack", "");
			return pb_time;
		} else {
			int score = -1;
			// when playing on a server, TmRaceRules.ScoreMgr is unfortunately
			// inaccessible
			if (app.CurrentProfile !is null &&
				app.CurrentProfile.AccountSettings !is null) {
				// this is using *saved replays* to load the PB; if the replay
				// has been deleted (or never saved), it won't appear
				for (uint i = 0; i < app.ReplayRecordInfos.Length; i++) {
					if (app.ReplayRecordInfos[i] !is null &&
						app.ReplayRecordInfos[i].MapUid == map.MapInfo.MapUid &&
						app.ReplayRecordInfos[i].PlayerLogin ==
							app.CurrentProfile.AccountSettings.OnlineLogin) {
						auto record = app.ReplayRecordInfos[i];
						if (score < 0 || record.BestTime < uint(score)) {
							score = int(record.BestTime);
						}
					}
					// to prevent lag spikes when updating medals, scan at most
					// 256 per tick
					if (i & 0xff == 0xff) {
						yield();
						// since we're yielding, it's possible for a race
						// condition to occur, and things to get yanked out from
						// under our feet; look for this case and bail if it
						// happens
						if (app.CurrentProfile is null ||
							app.CurrentProfile.AccountSettings is null ||
							app.ReplayRecordInfos.Length <= i) {
							warn("Game state changed while scanning records. "
								 "Retrying in "
								 "500ms...");
							break;
						}
					}
				}
			}

			/* this is session-best, check this as well */
			if (app.CurrentPlayground !is null &&
				app.CurrentPlayground.GameTerminals.Length > 0 &&
				cast<CTrackManiaPlayer>(app.CurrentPlayground.GameTerminals[0]
											.GUIPlayer) !is null &&
				cast<CTrackManiaPlayer>(
					app.CurrentPlayground.GameTerminals[0].GUIPlayer)
					.Score !is null) {
				int sessScore =
					int(cast<CTrackManiaPlayer>(
							app.CurrentPlayground.GameTerminals[0].GUIPlayer)
							.Score.BestTime);
				if (sessScore > 0 && (score < 0 || sessScore < score)) {
					score = sessScore;
				}
			}
			return score;
		}

#elif TURBO
		if (network.TmRaceRules !is null) {
			auto dataMgr = network.TmRaceRules.DataMgr;
			// dataMgr.RetrieveRecords(map.MapInfo, dataMgr.MenuUserId);
			dataMgr.RetrieveRecordsNoMedals(map.MapInfo.MapUid,
											dataMgr.MenuUserId);
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
		print("returning 0");
		return 0;
	}

	void build_medals(Json::Value @m) {
		auto app = cast<CTrackMania>(GetApp());

#if TMNEXT || MP4
		auto map = app.RootMap;
#elif TURBO
		auto map = app.Challenge;
#endif
		if (map is null)
			return;

		for (uint i = 0; i < m.Length; i++) {
			int medal = m[i].Get("medal");
			switch (Medals::Type(medal)) {
			case Medals::Type::Bronze:
				this.medals.InsertLast(
					BaseMedal(medal, map.TMObjective_BronzeTime));
				break;
			case Medals::Type::Silver:
				this.medals.InsertLast(
					BaseMedal(medal, map.TMObjective_SilverTime));
				break;
			case Medals::Type::Gold:
				this.medals.InsertLast(
					BaseMedal(medal, map.TMObjective_GoldTime));
				break;
#if TMNEXT || MP4
			case Medals::Type::Author:
				this.medals.InsertLast(
					BaseMedal(medal, map.TMObjective_AuthorTime));
				break;
#elif TURBO
				// TODO: add turbo stuff
			case Medals::Type::Trackmaster:
				this.medals.InsertLast(
					BaseMedal(medal, map.TMObjective_AuthorTime));
				break;
			case Medals::Type::S_Bronze: {
				uint stm =
					TurboSTM::GetSuperTime(Text::ParseUInt64(map.MapInfo.Name))
						.m_time;
				int delta = map.TMObjective_AuthorTime - stm;
				this.medals.InsertLast(BaseMedal(medal, stm + (delta + 1) / 2));
				break;
			}
			case Medals::Type::S_Silver: {
				uint stm =
					TurboSTM::GetSuperTime(Text::ParseUInt64(map.MapInfo.Name))
						.m_time;
				int delta = map.TMObjective_AuthorTime - stm;
				this.medals.InsertLast(BaseMedal(medal, stm + (delta + 1) / 4));
				break;
			}
			case Medals::Type::S_Gold: {
				uint stm =
					TurboSTM::GetSuperTime(Text::ParseUInt64(map.MapInfo.Name))
						.m_time;
				int delta = map.TMObjective_AuthorTime - stm;
				this.medals.InsertLast(BaseMedal(medal, stm + (delta + 1) / 8));
				break;
			}
			case Medals::Type::S_Trackmaster:
				this.medals.InsertLast(BaseMedal(
					medal,
					TurboSTM::GetSuperTime(Text::ParseUInt64(map.MapInfo.Name))
						.m_time));
				break;
#endif
#if TMNEXT && DEPENDENCY_CHAMPIONMEDALS
			case Medals::Type::Champion:
				this.medals.InsertLast(
					BaseMedal(medal, ChampionMedals::GetCMTime()));
				break;
#elif MP4 && DEPENDENCY_DUCKMEDALS
			case Medals::Type::Duck:
				this.medals.InsertLast(
					BaseMedal(medal, DuckMedals::GetDuckTime()));
				break;
#elif TURBO && DEPENDENCY_DUCKMEDALS
			case Medals::Type::Duck:
				this.medals.InsertLast(
					BaseMedal(medal, DuckMedals::GetDuckTime()));
				break;
#endif
			default:
				// skip medals that are not implemented
				break;
			}
		}
	}

	void debug_render_medals() {
		if (this.medals.Length == 0)
			return;

		// print("debug_render_medals, medals.Length: " + this.medals.Length);
		UI::SetNextWindowPos(200, 200,
							 false ? UI::Cond::Always : UI::Cond::FirstUseEver);
		int window_flags =
			UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse |
			UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
		if (!UI::IsOverlayShown())
			window_flags |= UI::WindowFlags::NoInputs;
		UI::Begin("Grinding Stats Debug", window_flags);
		UI::BeginGroup();
		UI::BeginTable("table", 4, UI::TableFlags::SizingFixedFit);
		UI::TableNextColumn();
		UI::Text("\\$f00DEBUG");
		UI::TableNextRow();
		UI::TableNextColumn();
		UI::Text("\\$ddd" + "Medal");
		UI::TableNextColumn();
		UI::Text("\\$bbb" + "Target Time");
		UI::TableNextColumn();
		UI::Text("\\$ddd" + "Achieved Time");
		UI::TableNextColumn();
		UI::Text("\\$bbb" + "Achieved");
		for (uint i = 0; i < this.medals.Length; i++) {
			UI::TableNextColumn();
			// print(Medals::to_string(Medals::Type(i)));
			UI::Text("\\$ddd" + Medals::to_string(Medals::Type(i)));
			UI::TableNextColumn();
			// print(medals[i].target);
			if (medals[i].target != 0) {
				UI::Text("\\$bbb" +
						 Recap::time_to_string(medals[i].target, true));
			} else {
				UI::Text("\\$bbb" + "No medal time set");
			}

			UI::TableNextColumn();
			if (medals[i].achieved_time != 0) {
				UI::Text("\\$ddd" +
						 Recap::time_to_string(medals[i].achieved_time, true));
			} else {
				UI::Text("\\$ddd" + "No medal time set");
			}

			UI::TableNextColumn();
			if (medals[i].achieved) {
				UI::Text("\\$0f0" + "Yes");
			} else {
				UI::Text("\\$f00" + "No");
			}
		}
		UI::EndTable();

		UI::Separator();
		UI::BeginTable("table2", 3, UI::TableFlags::SizingFixedFit);
		BaseMedal @highest_medal = this.get_highest_medal();
		if (highest_medal !is null) {
			UI::TableNextRow();
			UI::TableNextColumn();
			UI::Text("\\$ddd" + "Highest Medal");
			UI::TableNextColumn();
			UI::Text("\\$ddd" + Medals::to_string(highest_medal.type));
			UI::TableNextColumn();
			if (highest_medal.achieved_time != 0)
				UI::Text("\\$ddd" + Recap::time_to_string(
										highest_medal.achieved_time, true));
			else
				UI::Text("\\$ddd" + "No medal time set");
		}
		UI::EndTable();
		UI::EndGroup();
		UI::End();
	}
}