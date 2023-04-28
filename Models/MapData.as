class MapData {
    string mapUid = '';
    MapTimes@ map_times = MapTimes();
    
    MapData() {}

    MapData(string _mapUid) {
        mapUid = _mapUid;
#if TMNEXT
        if (_mapUid != '') {
            load_medal_times();
            startnew(CoroutineFunc(load_personal_best));
        }
#endif
    }

    private void load_medal_times() {
        auto app = GetApp();
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        auto map = playground !is null ? playground.Map : null;

        if (map !is null) {
            map_times.bronze = map.TMObjective_BronzeTime;
            map_times.silver = map.TMObjective_SilverTime;
            map_times.gold = map.TMObjective_GoldTime;
            map_times.author = map.TMObjective_AuthorTime;
        }
    }

    private void load_personal_best() {
        auto app = cast<CTrackMania>(GetApp());
        auto network = cast<CTrackManiaNetwork>(app.Network);
        auto scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;

        auto userMgr = network.ClientManiaAppPlayground.UserMgr;
        auto userId = userMgr.Users.Length > 0 ? userMgr.Users[0].Id : uint(-1);

        uint local_pb = scoreMgr.Map_GetRecord_v2(userId, mapUid, "PersonalBest", "", "TimeAttack", "");

        if (local_pb > 0) {
            map_times.personal_best = local_pb;
            startnew(CoroutineFunc(data.medals.lock_earlier_medals));
            load_online_pb();
        }
    }

    private void load_online_pb() {
#if DEPENDENCY_NADEOSERVICES
        auto info = FetchEndpoint(NadeoServices::BaseURL() + "/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/surround/0/0?onlyWorld=true");
        if (info.GetType() == Json::Type::Null) {
            return;
        }
        auto tops = info["tops"];
        if (tops.GetType() != Json::Type::Array) {
            return;
        }
        auto top = tops[0]["top"];
        if (top.Length == 0) {
            return;
        }
        uint score = top[0]["score"];
        if (score == 0) {
            return;
        }
        map_times.personal_best = (
            map_times.personal_best > 0 && map_times.personal_best < score
                ? map_times.personal_best
                : score
        );
        startnew(CoroutineFunc(data.medals.lock_earlier_medals));
#endif
    }
}
