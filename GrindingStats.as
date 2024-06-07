enum displays {
    Only_when_Openplanet_menu_is_open,
    Always_except_when_interface_is_hidden,
    Always
}

[Setting name="Enabled" category="UI"]
bool setting_enabled = true;

[Setting name="Lock window location" category="UI"]
bool setting_lock_window_location = false;

[Setting name="Display setting" category="UI"]
displays setting_display = displays::Always_except_when_interface_is_hidden;

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

[Setting name="Custom Grinding Recap" multiline category="Recap" description="Tracks in this list will be included in custom Recap. Enter UID of track per line."]
string setting_custom_recap = "";

[Setting name="Show debug information" category="Debug"]
bool setting_show_debug = false;


Data data;
Recap recap;

bool recap_enabled = false;


void Main()
{
#if DEPENDENCY_NADEOSERVICES
    NadeoServices::AddAudience("NadeoLiveServices");
#endif

    auto old_path = IO::FromDataFolder("Grinding Stats");
    auto new_path = IO::FromStorageFolder("data");//.SubStr(0, IO::FromStorageFolder("").Length - 1); // remove trailing slash
    if (IO::FolderExists(old_path)) {
        IO::Move(old_path, new_path);
    }

    if (setting_recap_show_menu && !recap.started) recap.start();
}
