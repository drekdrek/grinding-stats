class RecapSQLite {
	RecapSQLite() {}

	RecapSQLite(SQLite::Database @db) {
	}

	array<RecapElement @> get_recap_elements() {
		array<RecapElement @> ret = array<RecapElement @>();
		auto query = data.db.Prepare("""
          SELECT
            maps.*,
            MAX(medals.type) as highest_medal,
            medals.achieved_time,
            MAX(medals.type) is not null as has_acheived_medal
        FROM
            maps
        LEFT JOIN medals ON
            maps.map_id = medals.map_id
        GROUP BY maps.map_id
        """);
		// query.Execute();
		while (query.NextRow()) {
			string map_id = query.GetColumnString("map_id");
			if (map_id != "") {

				uint64 finishes = uint64(query.GetColumnInt64("finishes"));
				uint64 resets = uint64(query.GetColumnInt64("resets"));
				uint64 time = uint64(query.GetColumnInt64("time"));
				uint64 respawns = uint64(query.GetColumnInt64("respawns"));
				int64 updated_at = query.GetColumnInt64("updated_at");
				string name = query.GetColumnString("name");
				string titlepack = query.GetColumnString("titlepack");

				recap.log.InsertLast("Loaded " + map_id);

				bool need_to_req = name == "";
				if (need_to_req) {
					recap.log.InsertLast("fetching name for " + map_id);
					array<string> resp = get_name_and_titlepack_from_api(map_id);
					name = resp[0];
					titlepack = resp[1];
					set_name_and_titlepack(map_id, name, titlepack);
					recap.log.InsertLast("got " + name + "\\$g\\$z for " + map_id);
				}

				// highest medal
				bool has_medal = query.GetColumnInt("has_acheived_medal") == 1;
				BaseMedal highest_medal = BaseMedal();
				if (has_medal) {
					Medals::Type type = Medals::Type(query.GetColumnInt("highest_medal"));
					uint64 medal_time = uint64(query.GetColumnInt64("achieved_time"));
					highest_medal = BaseMedal(type, true, medal_time);
				}

				ret.InsertLast(RecapElement(map_id, time, finishes, resets, respawns, updated_at, highest_medal, name, titlepack));
				if (need_to_req) {
					sleep(10);
				}
				while (recap.log.Length > 5) {
					recap.log.RemoveAt(0);
				}
			}
		}
		return ret;
	}
	void set_name_and_titlepack(const string &in map_id, const string &in name, const string &in titlepack) {
		auto query = data.db.Prepare("""
          INSERT INTO maps (map_id, name, titlepack)
            VALUES (?,?,?)
            ON CONFLICT(map_id)
            DO UPDATE SET name=excluded.name, titlepack=excluded.titlepack;
        """);
        query.Bind(1, map_id);
        query.Bind(2, name);
        query.Bind(3, titlepack);
        print("updated name and titlepack for " + map_id + " (" + name + ", " + titlepack + ")");
        query.Execute();
	}
	array<string> get_name_and_titlepack_from_api(const string &in map_id) {
		if (map_id == "Unassigned")
			return {"", ""};
		string name;
		string titlepack;

#if TMNEXT
		CTrackMania @app = cast<CTrackMania>(GetApp());
		MwId mwId = app.ManiaPlanetScriptAPI.MasterServer_MSUsers[0].Id;
		CGameDataFileManagerScript @DataFileMgr = app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr;
		name = map_id;
		auto req = DataFileMgr.Map_NadeoServices_GetFromUid(mwId, map_id);
		while (req.IsProcessing)
			yield();
		if (req.HasFailed || req.IsCanceled || !req.HasSucceeded) {
			if (req.ErrorCode != "C-AK-03-01") {
				throw("req failed or canceled. mapId=" + map_id + " errorType=" + req.ErrorType + "; errorCode=" + req.ErrorCode + "; errorDescription=" + req.ErrorDescription);
			}
		}
		CNadeoServicesMap @map = req.Map;
		name = format_string(map.Name);

#elif MP4
		auto req = Net::HttpRequest();
		req.Method = Net::HttpMethod::Get;
		req.Url = 'https://tm.mania.exchange/api/maps?fields=GbxMapName,TitlePack&count=1&uid=' + map_id;
		req.Start();
		while (!req.Finished())
			yield();
		Json::Value @res = req.Json();
		if (req.ResponseCode() == 200 && res["Results"].Length > 0) {
			Json::Value @map = res["Results"][0];
			name = format_string(map['GbxMapName']);
			titlepack = string(map['TitlePack']);
		}

#elif TURBO
		auto app = GetApp();
		MwFastBuffer<CGameCtnChallengeInfo @> infos = app.ChallengeInfos;
		for (uint i = 0; i < infos.Length; i++) {
			if (map_id == infos[i].MapUid) {
				string color = "";
				uint series = uint(Math::Floor((Text::ParseUInt64(infos[i].NameForUi) - 1) / 40));
				if (setting_recap_show_colors) {
					switch (series) {
					case 0:
						color = "\\$FFF";
						break;
					case 1:
						color = "\\$6F6";
						break;
					case 2:
						color = "\\$36C";
						break;
					case 3:
						color = "\\$C33";
						break;
					case 4:
						color = "\\$666";
						break;
					}
				}
				name = color + infos[i].NameForUi;
				titlepack = get_environment_name(infos[i].NameForUi);
			}
		}
#endif
		return {name, titlepack};
	}

#if TURBO
	string get_environment_name(const string &in mapName) {
		int num;

		if (!Text::TryParseInt(mapName, num))
			return "";

		int numMod40 = num % 40;

		if (numMod40 >= 1 && numMod40 <= 10)
			return "Canyon";
		else if (numMod40 >= 11 && numMod40 <= 20)
			return "Valley";
		else if (numMod40 >= 21 && numMod40 <= 30)
			return "Lagoon";
		else if (numMod40 >= 31 && numMod40 <= 40 || numMod40 == 0)
			return "Stadium";

		return "";
	}
#endif
}