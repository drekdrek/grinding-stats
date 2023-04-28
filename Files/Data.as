class Data {
    string mapUid = "";
    string file = "";
    MapData@ map_data = MapData();

    Finishes@ finishes = Finishes(0);
    Resets@ resets = Resets(0);
    Respawns@ respawns = Respawns(0);
    Timer@ timer = Timer(0);
    Medals@ medals = Medals(0, 0, 0, 0);
    Files files;

    private bool cloud_save_failed = false;

    Data()  {
        startnew(CoroutineFunc(map_handler));
    }
    
    void map_handler() {
        auto app = GetApp();
        while (true) {
#if TMNEXT
            auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
            auto map = playground !is null ? playground.Map : null;
            string mapId = (map is null) ? "" : map.IdName;
#elif MP4
            auto rootmap = app.RootMap;
            string mapId = (rootmap is null ) ? "" : rootmap.IdName;
#elif TURBO
            auto challenge = app.Challenge;
            string mapId = (challenge is null) ? "" : challenge.IdName;
#endif
            if (mapId != mapUid && app.Editor is null) { 
                //the map has changed and we are not in the editor.
                //the map has changed //we should save and then load the new map's data
                timer.timing = false;
                auto saving = startnew(CoroutineFunc(save));
                while (saving.IsRunning()) yield();
                mapUid = mapId;
                map_data = MapData(mapId);
                file = folder_location + "/" + mapUid + '.json';

                startnew(CoroutineFunc(load));

            }
            yield();
        }
    }

    ~Data() {
        save();
    }

    void start() {
        timer.start();
        finishes.start();
        resets.start();
        respawns.start();
        medals.start();
    }


    void load() {
        if (mapUid == "" || mapUid == "Unassigned") return;

        {
            files = Files(mapUid);
            while (!files.loaded) yield();
            finishes = Finishes(files.finishes);
            resets = Resets(files.resets);
            timer = Timer(files.time);
            respawns = Respawns(files.respawns);
            medals = Medals(
                files.time_to_bronze.time,
                files.time_to_silver.time,
                files.time_to_gold.time,
                files.time_to_author.time
            );
            
            start();
        }
    }



    void save() {
        if (mapUid == "" || mapUid == "Unassigned") return;
        {//saving to file
              files.time = timer.total;
              files.finishes = finishes.total;
              files.resets = resets.total;
              files.respawns = respawns.total;
              files.time_to_bronze.set_time_from_medal(medals.bronze);
              files.time_to_silver.set_time_from_medal(medals.silver);
              files.time_to_gold.set_time_from_medal(medals.gold);
              files.time_to_author.set_time_from_medal(medals.author);
              files.write_file();
        }
    }
}
