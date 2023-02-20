class Data {
    private string folder_location = IO::FromDataFolder("") + "Grinding Stats";
    string mapUid = "";
    string file = "";

    Finishes@ finishes = Finishes(0);
    Resets@ resets = Resets(0);
    Respawns@ respawns = Respawns(0);
    Timer@ timer = Timer(0);
    Files files;

    private bool cloud_save_failed = false;
    private bool timing = false;
    Data()  {
        startnew(CoroutineFunc(map_handler));
        if (!IO::FolderExists(folder_location)) IO::CreateFolder(folder_location);

    }

    void timer_handler() {
    bool handled = true;
    timing = true;
    while(timing) {
        if (!timer.isRunning() && !handled) {
            handled = true;
            timer.stop();
        } else if (timer.isRunning() && handled) {
            handled = false;
            timer.start();
        }
        yield();
    }
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
            timing = false;
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
        print('start');
        startnew(CoroutineFunc(timer_handler));
        finishes.start();
        resets.start();
        respawns.start();
    }


    void load() {
        if (mapUid == "" || mapUid == "Unassigned") return;
        
        {
            files = Files(mapUid);
            while (files.time == 0) yield();
            
            finishes = Finishes(files.finishes);
            resets = Resets(files.resets);
            timer = Timer(files.time);
            respawns = Respawns(files.respawns);
            
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
              files.write_file();
        }
    }
}