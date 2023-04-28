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

[Setting name="Show fractions of second" category="UI"]
bool setting_show_fractions_of_second = true;
[Setting name="Show thousands" category="UI" description="If show fractions of second is enabled, toggles showing of the thousandth digit"]
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

#if TMNEXT
[Setting name="Show Current Run's respawns" category="Stats"]
bool setting_show_respawns_current = false;
[Setting name="Show Session respawns" category="Stats"]
bool setting_show_respawns_session = false;
[Setting name="Show Total respawns" category="Stats"]
bool setting_show_respawns_total = false;

[Setting name="Show Time To Achieve Bronze Medal" category="Medals"]
bool setting_show_time_to_bronze = false;
[Setting name="Show Time To Achieve Silver Medal" category="Medals"]
bool setting_show_time_to_silver = false;
[Setting name="Show Time To Achieve Gold Medal" category="Medals"]
bool setting_show_time_to_gold = true;
[Setting name="Show Time To Achieve Author Medal" category="Medals"]
bool setting_show_time_to_author = true;

#else

bool setting_show_respawns_current = false;
bool setting_show_respawns_session = false;
bool setting_show_respawns_total = false;
bool setting_show_time_to_bronze = false;
bool setting_show_time_to_silver = false;
bool setting_show_time_to_gold = false;
bool setting_show_time_to_author = false;
#endif

[Setting name="Idle Detection Speed" category="Idle" description="The speed where the car will be considered idle after a set time. (this is not the speed that the car is going but the internal value of the speed)"]
uint setting_idle_speed = 2;
[Setting name="Idle Detection Delay" category="Idle" description="The amount of time before Idling will begin."]
uint setting_idle_time = 5;

[Setting name="Show debug information" category="Debug"]
bool setting_show_debug = false;
