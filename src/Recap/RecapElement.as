class RecapElement {
    RecapMedals medal;
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

    RecapElement(const string &in id, uint64 time, uint64 finishes, uint64 resets, uint64 respawns, int64 updated_at, Json::Value@ medals) {
#if MP4 
        titlepack = "";
#elif TURBO
        environment = "";
#endif
        this.map_id = id;
        this.name = map_id;

        this.stripped_name = Text::StripFormatCodes(name);
        this.medal = RecapMedals(medals);
        this.time = time;
        this.time_string = Recap::time_to_string(this.time);
        this.finishes = finishes;
        this.resets = resets;
        this.respawns = respawns;
        this.updated_at = updated_at;
    }
    


	void get_name_from_api() {
		if (map_id == "Unassigned")
			return;
		if (name != map_id)
			return;

#if TMNEXT
		CTrackMania @app = cast<CTrackMania>(GetApp());
		MwId mwId = app.ManiaPlanetScriptAPI.MasterServer_MSUsers[0].Id;
		CGameDataFileManagerScript @DataFileMgr = app.MenuManager.MenuCustom_CurrentManiaApp.DataFileMgr;
		name = map_id;
		auto req = DataFileMgr.Map_NadeoServices_GetFromUid(mwId, this.map_id);
		while (req.IsProcessing)
			yield();
		if (req.HasFailed || req.IsCanceled || !req.HasSucceeded) {
			if (req.ErrorCode != "C-AK-03-01") {
				throw("req failed or canceled. mapId=" + map_id + " errorType=" + req.ErrorType + "; errorCode=" + req.ErrorCode + "; errorDescription=" + req.ErrorDescription);
			}
		}
		CNadeoServicesMap @map = req.Map;
		if (Text::StripFormatCodes(map.Name) == "")
			return;
		name = format_string(map.Name);

#elif MP4
		auto req = Net::HttpRequest();
		req.Method = Net::HttpMethod::Get;
		req.Url = 'https://tm.mania.exchange/api/maps?fields=GbxMapName,TitlePack&count=1&uid=' + this.map_id;
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
				environment = get_environment_name(infos[i].NameForUi);
			}
		}
#endif

		this.stripped_name = Text::StripFormatCodes(name).Replace('\\','');
		for (int i = 0; i < this.stripped_name.Length; i++) {
			if (this.stripped_name.StartsWith(" "))
				this.stripped_name = this.stripped_name.SubStr(2);
			else
				break;
		}
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
