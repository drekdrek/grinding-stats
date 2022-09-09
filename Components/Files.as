//Files.as
bool are_you_sure_current = false;
bool are_you_sure_all = false;
uint are_you_sure_current_timeout = 0;
uint are_you_sure_all_timeout = 0;
[SettingsTab name="Files"]
void files_render_settings() {
    if (are_you_sure_current && (Time::Now - are_you_sure_current_timeout) > 5000) {
        print(Time::Now - are_you_sure_current_timeout);
        print(are_you_sure_current_timeout + " " + Time::Now);
        are_you_sure_current = false;
    }
    if (are_you_sure_all && (Time::Now - are_you_sure_all_timeout  > 5000)) {
        are_you_sure_all = false;
    }
    if (UI::Button("Reset current map's data")) {
        
        if (file.get_map_id() == "") {
            UI::ShowNotification("Grinding Stats","You are not currently in a map.",5000);
            return;
        }
        if (!are_you_sure_current) {
            UI::ShowNotification("Grinding Stats","Are you sure you want to reset the current map's data?",4000);
            are_you_sure_current = true;
            are_you_sure_current_timeout = Time::Now;
            return;
        } else {
            UI::ShowNotification("Grinding Stats","Reset current map's data",5000);
            file.reset_file();
            are_you_sure_current = false;
            return;
        }
    }
    
    if (UI::Button("Reset all map data")) { 
        if (!are_you_sure_all) {
            UI::ShowNotification("Grinding Stats","Are you sure you want to reset the current map's data?",4000);
            are_you_sure_all = true;
            are_you_sure_all_timeout = Time::Now;
            return;
        } else {
            UI::ShowNotification("Grinding Stats","Reset current map's data",4000);
            file.reset_all();
            are_you_sure_all = false;
            return;
        }
        
    }
    
}

class Files {
    string folder_location = "";
    string map_id = "";
    string json_file = "";
    uint finishes = 0;
    uint resets = 0;
    uint time = 0;
    uint respawns = 0;
    Json::Value json_obj = Json::Parse('{"finishes": 0,"resets": 0,"time": 0,"respawns":0}');
    Files() {}
    Files(const string &in id) {
        if (id == "" || id == "Unassigned") return;
        
        folder_location = IO::FromDataFolder("") + "Grinding Stats";
        


        if (!IO::FolderExists(folder_location)) IO::CreateFolder(folder_location);

        map_id = id;
        json_file = folder_location + '/' + map_id + '.json';
        read_file();
    }

    void move_files_to_new_folder(const string &in new_folder) {
        auto files = IO::IndexFolder(folder_location,true);
        for (uint i = 0; i < files.Length; i++) {
            IO::Move(files[i],new_folder);
        }
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
        print("Read finishes " + finishes + " resets " + resets + " time " + time + " respawns " + respawns + " from " + json_file);
    }
    void write_file() {
        
        if (map_id == "" || map_id == "Unassigned") {
            return;
        }
        json_obj["finishes"] = finishes;
        json_obj["resets"] = resets;
        json_obj["time"] = time;
        json_obj["respawns"] = respawns;
        Json::ToFile(json_file,json_obj);
        print("Wrote finishes " + finishes + " resets " + resets + " time " + time + " respawns " + respawns + " to " + json_file);
    }

    string get_map_id() {
        return map_id;
    }
    string get_folder_location() {
        return folder_location;
    }
    void set_folder_location(const string &in loc) {
        folder_location = loc;
    }
    void set_map_id(const string &in i) {
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
        print(json_file);
        destroy();
        IO::Delete(json_file);
        start(map_id);
    }
    void reset_all() {
        auto files = IO::IndexFolder(folder_location,true);
        for (uint i = 0; i < files.Length; i++) {
            IO::Delete(files[i]);
        }
    }

}
