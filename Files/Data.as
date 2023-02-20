class Data {
    private string folder_location = IO::FromDataFolder("") + "Grinding Stats";
    string mapUid = "";
    string file = "";
// #if TMNEXT
//     private string platform = "next";
// #elif MP4
//     private string platform = "mp4";
// #elif TURBO
//     private string platform = "turbo";
// #endif
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
        // if (_mapUid == "" || _mapUid == "Unassigned") return;
        // mapUid = _mapUid;
        // 
        // 
        // startnew(CoroutineFunc(load));
    }

    //detects a map change and will cause the save/load methods to fire
    //will change the finishes/resets/respawns/timer to change over when finished

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
        // //first try loading totals from the cloud, then if that fails fallback to the file.
        // bool cloud_loaded = false;
        // {//loading from the cloud

        //     string tmUserId = GetApp().LocalPlayerInfo.WebServicesUserId;

        //     Net::HttpRequest@ req = Net::HttpRequest();
        //     req.Method = Net::HttpMethod::Get;
        //     req.Url = "https://api-grinding-stats-tm.herokuapp.com/api/sessions/recap?filters[tmUserId]="+tmUserId+"&filters[tmMapUid]="+mapUid+"&filters[platform]="+platform;
        //     print(req.Url);
        //     req.Headers['Authorization'] = 'Bearer 2994d866398e12fba3ddd4d4d0c0cad639c056914644d8428b89ac1893fd9738340309889a30b36b432c73285c58b864b090a6aa05c71e3072b090dd4e189dcb32d08b0267c8e3811827cac87ceeaeebb5588759e0e1a6261748868e49f72686caba07afba46c1e2309574296d64693db310de6d3e5e221ec1652933301769af';
        //     req.Headers['Content-Type'] = 'application/json';
        //     req.Start();
        //     while(!req.Finished()) yield();
        //     Json::Value d = Json::Parse(req.String());
        //     print(Json::Write(d));
        //     // if (req.ResponseCode() == 200 && d.Get('data') != Json::Array()) {
        //     //         finishes = Finishes(d.Get('data')[0].Get('totalFinished'));
        //     //         resets = Resets(d.Get('data')[0].Get('totalResets'));
        //     //         respawns = Respawns(d.Get('data')[0].Get('totalRespawns'));
        //     //         timer = Timer(d.Get('data')[0].Get('totalDuration'));
        //     //         loaded = true;
        //     //         start();
        //     //         return;
                
        //     // }
        //     string err_message = d.Get('error').Get('message');
        //     print("Error loading from the cloud: " + err_message + ", falling back to file");
        // }
        {
            files = Files(mapUid);
            while (files.time == 0) yield();
            
            finishes = Finishes(files.finishes);
            resets = Resets(files.resets);
            timer = Timer(files.time);
            respawns = Respawns(files.respawns);
            // if (IO::FileExists(file)) {
            //     print(file);
            //     auto content = Json::FromFile(file);
            //     uint value_types;
            //     if (content.Get('map_id') is null && content.Get('respawns') !is null) {
            //         value_types =
            //         content.Get('finishes').GetType() |
            //          content.Get('resets').GetType() |
            //           content.Get('time').GetType() |
            //            content.Get('respawns').GetType();
            //     } else {
            //         Finishes(content.Get('finishes'));
            //         Resets(content.Get('resets'));
            //         Timer(content.Get('time'));
            //         Respawns(0);
            //         return;
            //     }

            //     if (content.GetType() != Json::Type::Null) {
            //         if (value_types == 1) {
            //             Finishes(Text::ParseUInt64(content.Get("finishes")));
            //             Resets(Text::ParseUInt64(content.Get('resets')));
            //             Timer(Text::ParseUInt64(content.Get('time')));
            //             Respawns(Text::ParseUInt64(content.Get('respawns')));
            //         }
            //         else if (value_types == 2) {
            //             Finishes(content.Get('finishes'));
            //             Resets(content.Get('resets'));
            //             Timer(content.Get('time'));
            //             Respawns(content.Get('respawns'));
            //         } 
            //         else {
            //             UI::ShowNotification("Grinding Stats","Unable to parse the map's saved data from file.",    UI::HSV(1.0f,1.0f,1.0f),15000);
            //         }
            //     }
            // } else {
            //     Finishes(0);
            //         Resets(0);
            //         Timer(0);
            //         Respawns(0);
            // }
            // print("Read finishes " + finishes.total + " resets " + resets.total + " time " + timer.total + " respawns " + respawns.total + " to " + file);
            start();
        }
    }



    void save() {
        if (mapUid == "" || mapUid == "Unassigned") return;
        // //save to both the cloud and the file
        // string tmUserId = GetApp().LocalPlayerInfo.WebServicesUserId;
        // {//saving to cloud

        //     auto token = Auth::GetToken();
        //     while (!token.Finished()) yield();
        //     Json::Value body = Json::Object();
        //     body['data'] = Json::Object();
        //     Json::Value@ d = body['data'];

        //     d['tmMapUid'] = mapUid;
        //     d['openPlanetUserToken'] = token.Token();
        //     d['duration'] = timer.session;
        //     d['finishes'] = finishes.session;
        //     d['platform'] = platform;
        //     d['resets'] = resets.session;
        //     d['respawns'] = respawns.session;
        //     if (d['openPlanetUserToken'] == "") return;

        //     Net::HttpRequest@ req = Net::HttpRequest();
        //     print(Json::Write(body));
        //     req.Method = Net::HttpMethod::Post;
        //     req.Url = 'https://api-grinding-stats-tm.herokuapp.com/api/sessions';
        //     req.Headers['Authorization'] = 'Bearer 2994d866398e12fba3ddd4d4d0c0cad639c056914644d8428b89ac1893fd9738340309889a30b36b432c73285c58b864b090a6aa05c71e3072b090dd4e189dcb32d08b0267c8e3811827cac87ceeaeebb5588759e0e1a6261748868e49f72686caba07afba46c1e2309574296d64693db310de6d3e5e221ec1652933301769af';
        //     req.Headers['Content-Type'] = 'application/json';
        //     req.Body = Json::Write(body);
        //     req.Start();
        //     while(!req.Finished()) yield();
        //     print(req.String());

        //     if (req.Error() != "") {
        //         //the cloud save failed it's second request so we give up D: // also so it wont resave the file locally
        //         if (cloud_save_failed) return;
        //         print("Error saving from the cloud: " + req.Error() + ", retrying...");
        //         cloud_save_failed = true;
        //     }
             
             
        // }
        {//saving to file
              files.time = timer.total;
              files.finishes = finishes.total;
              files.resets = resets.total;
              files.respawns = respawns.total;
              files.write_file();
        }
    }
}