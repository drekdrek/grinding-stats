//Grinding Stats.as
enum display_setting {
    Only_when_Openplanet_menu_is_open,
    Always_except_when_interface_is_hidden,
    Always
}

[Setting name="Enabled" category="UI"]
bool setting_enabled = true;

[Setting name="Lock window location" category="UI"]
bool setting_lock_window_location = false;

[Setting name="Display setting" category="UI"]
display_setting setting_display = display_setting::Always_except_when_interface_is_hidden;

[Setting name="Show Duplicates" category="UI" description="will show both total and session time, finishes and resets if they are the same "]
bool setting_show_duplicates = false;

[Setting name="Show map name/author" category="UI"]
bool setting_show_map_name = true;

[Setting name="Show map name/author with color codes" category="UI"]
bool setting_show_map_name_color = true;

[Setting name="Show thousands" category="UI"]
bool setting_show_thousands = false;

[Setting name="Show Hour if 0" category="UI"]
bool setting_show_hour_if_0 = false;

[Setting name="Show Total time" category="Stats"]
bool setting_show_total_time = true;

[Setting name="Show Session time" category="Stats"]
bool setting_show_session_time = true;

[Setting name="Show Session finishes" category="Stats"]
bool setting_show_finishes_session = true;
[Setting name="Show Total finishes" category="Stats"]
bool setting_show_finishes_total = true;

[Setting name="Show Session resets" category="Stats"]
bool setting_show_resets_session = true;
[Setting name="Show Total resets" category="Stats"]
bool setting_show_resets_total = true;

[Setting name="Idle Detection Speed" category="Idle" description="The speed where the car will be considered idle after a set time. (this is not the speed that the car is going but the internal value of the speed)"]
uint setting_idle_speed = 2;
[Setting name="Idle Detection Delay" category="Idle" description="The amount of time before Idling will begin."]
uint setting_idle_time = 5;

[Setting name="Show Current Run's respawns" category="Stats"]
bool setting_show_respawns_current = false;
[Setting name="Show Session respawns" category="Stats"]
bool setting_show_respawns_session = false;
[Setting name="Show Total respawns" category="Stats"]
bool setting_show_respawns_total = false;

[Setting name="Show debug information" category="Debug"]
bool setting_show_debug = false;


Timer@ time = Timer();

Respawns@ respawns = Respawns();
Finishes@ finishes = Finishes();
Resets@ resets = Resets();

Files file;


bool running = true;
bool timing = true;

void Main() {
    startnew(map_handler);
}

void map_handler() {

    string map_id = "";
    auto app = GetApp();
    while (true) {
#if TMNEXT
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        map_id = (playground is null || playground.Map is null) ? "" : playground.Map.IdName;
#elif MP4
        auto rootmap = app.RootMap;
        map_id = (rootmap is null ) ? "" : rootmap.IdName;
#elif TURBO
        auto challenge = app.Challenge;
        map_id = (challenge is null) ? "" : challenge.IdName;
#endif

        if (app.Editor !is null) {
            destroy();
        } else if (map_id != file.get_map_id()) {
            
            destroy();
            start(map_id);
            
        }
    yield();
    }
}


void destroy() {
OnDestroyed();
            finishes.destroy();
            resets.destroy();
#if TMNEXT
            respawns.destroy();
#endif
            time.destroy();
}
void start(const string &in map_id) {
            file = Files(map_id);
            @time = Timer(file.get_time());
            @finishes = Finishes(file.get_finishes());
            @resets = Resets(file.get_resets());
#if TMNEXT
            @respawns = Respawns(file.get_respawns());
#endif
            timing = false;
            startnew(timer_handler);
            finishes.start();
            resets.start();
#if TMNEXT
            respawns.start();
#endif
}

void OnDestroyed() {

    file.set_time(time.get_total_time());
    file.set_finishes(finishes.get_total_finishes());
    file.set_resets(resets.get_total_resets());
    file.set_respawns(respawns.get_total_respawns());
    file.write_file();

}
