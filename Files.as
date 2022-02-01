//Files.as
class Files {
    string map_id = "";
    string json_file = "";
    uint finishes = 0;
    uint resets = 0;
    uint time = 0;
    uint respawns = 0;
    Json::Value json_obj = Json::Parse('{"finishes": 0,"resets": 0,"time": 0,"respawns":0}');
    Files() {}
    
    Files(string id) {
        if (id == "") return; // if the map id is empty, something's gone wrong but we will just return and not do anything
        string folder = IO::FromDataFolder("") + "Grinding Stats";
        if (!IO::FolderExists(folder)) IO::CreateFolder(folder); // if the folder does not exist create the folder
        
        map_id = id;
        json_file = folder + "/" + map_id + ".json";
        read_file();

    }

    void read_file() {
        if (IO::FileExists(json_file)) {
            IO::File file_obj(json_file);
            file_obj.Open(IO::FileMode::Read);
            auto content = file_obj.ReadToEnd();
            file_obj.Close();

            if (content == "" || content == "null") {json_obj = Json::Parse('{"finishes": 0,"resets": 0,"time": 0,"respawns": 0}');} // if the file is empty or null set the 'json_obj' to an empty json object
            else {
                json_obj = Json::FromFile(json_file);
                }
        }
        finishes = json_obj.HasKey("finishes") ? json_obj["finishes"] : 0;
        resets = json_obj.HasKey("resets") ? json_obj["resets"] : 0;
        time = json_obj.HasKey("time") ? json_obj["time"] : 0;
        respawns = json_obj.HasKey("respawns") ? json_obj["respawns"] : 0;
    }
    void write_file() {
        json_obj["finishes"] = finishes;
        json_obj["resets"] = resets;
        json_obj["time"] = time;
        json_obj["respawns"] = respawns;
        Json::ToFile(json_file,json_obj);
    }

    string get_map_id() {
        return map_id;
    }
    void set_map_id(string i) {
        map_id = i;
    }
    void set_finishes(uint f) {
        finishes = f;
    }
    void set_resets(uint r) {
        resets = r;
    }
    void set_time(uint t) {
        time = t;   
    }
    uint get_time() {
        return time;
    }
    uint get_finishes() {
        return finishes;
    }
    uint get_resets() {
        return resets;
    }
    uint get_respawns() {
        return respawns;
    }
    void set_respawns(uint r) {
        respawns = r;
    }
    void reset_file() {
        finishes = 0;
        resets = 0;
        time = 0;
        respawns = 0;
        write_file();
    }
    void reset_all() {
        auto files = IO::IndexFolder(IO::FromDataFolder("") + "Grinding Stats",true);

        for (uint i = 0; i < files.Length; i++) {
            IO::Delete(files[i]);
        }
    }
}