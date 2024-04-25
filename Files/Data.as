class Data {
    private string folder_location = IO::FromStorageFolder("");
    string mapUid = "";
    string file = "";

    Finishes@ finishes = Finishes(0);
    Resets@ resets = Resets(0);
    Respawns@ respawns = Respawns(0);
    Timer@ timer = Timer(0);
    Files files;

    private bool cloud_save_failed = false;
    Data()  {
        startnew(CoroutineFunc(map_handler));
        if (!IO::FolderExists(folder_location)) IO::CreateFolder(folder_location);
    }


    
    void map_handler() {
        string mapId = "";
        auto app = GetApp();
        while (true) {
#if TMNEXT
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        mapId = (playground is null || playground.Map is null) ? "" : playground.Map.IdName;
#elif MP4
        auto rootmap = app.RootMap;
        mapId = (rootmap is null ) ? "" : rootmap.IdName;
#elif TURBO
        auto challenge = app.Challenge;
        mapId = (challenge is null) ? "" : challenge.IdName;
#endif
        if (mapId != mapUid && app.Editor is null) { 
            //the map has changed and we are not in the editor.
            //the map has changed //we should save and then load the new map's data
            timer.timing = false;
            auto saving = startnew(CoroutineFunc(save));
            while (saving.IsRunning()) yield();
            mapUid = mapId;
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
            
            start();
        }
    }



    void save() {
        if (timer.total < 5000 && finishes.total == 0) {
            timer.total = 0;
            resets.total = 0;
            respawns.total = 0;
            return;
        }

        if (mapUid == "" || mapUid == "Unassigned") return;
        {//saving to file
              files.time = timer.total;
              files.finishes = finishes.total;
              files.resets = resets.total;
              files.respawns = respawns.total;
              files.write_file();
        }
    }
}