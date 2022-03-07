// thanks to Loupphok for allowing me to use their account for testing MP4 stuff.
// thanks to dequubi for doing most of the annoying work of porting to TURBO

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

[Setting name="Show Duplicates" category="UI" description="will show both total and session time if they are the same and the finishes, resets, ect."]
bool setting_show_duplicates = false;

[Setting name="Show map name/author" category="UI"]
bool setting_show_map_name = true;

[Setting name="Show thousands" category="UI"]
bool setting_show_thousands = false;


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
[Setting name="Show Session respawns" category="Stats"]
bool setting_show_respawns_session = false;
[Setting name="Show Total respawns" category="Stats"]
bool setting_show_respawns_total = false;
#endif

uint finishes = 0;
uint resets = 0;
uint respawns = 0;
uint64 start_time = 0;
uint64 time = 0;
uint64 disabled_time = 0;
uint64 total_disabled_time = 0;
uint64 disabled_start_time = 0;
string map_id = "";
vec2 anchor = vec2(0,500);


Files file;

bool handled_timer = false;
bool handled_reset = false ;
bool handled_finish = false;
bool handled_respawn = false;
bool handled_pb = false;
bool handled_disabled_time = false;
bool handled_file = false;
bool loaded = false;

bool handled_save = true;
void file_handler() {
    bool startup = true;

    while (true) {
        if (setting_enabled) {
#if TMNEXT
            CGameCtnApp@ app = GetApp();
            auto loadProgress = GetApp().LoadProgress;
            auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
            map_id = (playground is null || playground.Map is null) ? "" : playground.Map.IdName;
            auto rootmap = app.RootMap;
            if (rootmap !is null && playground !is null && playground.GameTerminals.Length > 0) {
                auto terminal = playground.GameTerminals[0];
                auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
                if (gui_player !is null) {
                    auto script = gui_player.ScriptAPI;
                    auto post = script.Post;
                    if (startup || handled_save && post == CSmScriptPlayer::EPost::Char) {
                        startup = false;
                        handled_save = false;
                        file = Files(map_id);
                        loaded = false;
                    }
                }
            }
#elif MP4
            auto app = GetApp();
            auto playground = app.CurrentPlayground;
            auto rootmap = app.RootMap;
            map_id = (rootmap is null ) ? "" : rootmap.IdName;
            if (rootmap !is null && playground !is null && playground.GameTerminals.Length > 0){
                auto terminal = playground.GameTerminals[0];
                auto gui_player = cast<CTrackManiaPlayer>(terminal.GUIPlayer);
                if (gui_player !is null) {
                    auto script = gui_player.ScriptAPI;
                    auto race_state = script.RaceState;
                    if (startup || handled_save && race_state == CTrackManiaPlayer::ERaceState::BeforeStart) {
                        startup = false;
                        handled_save = false;
                        file = Files(map_id);
                        loaded = false;
                    }
                }
            }
#elif TURBO
            // basically copy & paste of the MP4 code, the only change is
            // RootMap becomes Challenge, and RaceState can be accessed
            // directly through gui_player (which is also called ControlledPlayer)
            auto app = GetApp();
            auto playground = app.CurrentPlayground;
            auto rootmap = app.Challenge;
            map_id = (rootmap is null ) ? "" : rootmap.IdName;
            if (rootmap !is null && playground !is null && playground.GameTerminals.Length > 0){
                auto terminal = playground.GameTerminals[0];
                auto gui_player = cast<CTrackManiaPlayer>(terminal.ControlledPlayer);
                if (gui_player !is null) {
                    auto race_state = gui_player.RaceState;
                    if (startup || handled_save && race_state == CTrackManiaPlayer::ERaceState::BeforeStart) {
                        startup = false;
                        handled_save = false;
                        file = Files(map_id);
                        loaded = false;
                    }
                }
            }
#endif
        if (!handled_save && playground is null && !loaded){
                handled_save = true;
                loaded = true;
                if (file !is null) {
                    save_time();
                }
            }
        }
        yield();
    }
}

void Main() {
    bool startup = true;
    uint temp_respawns = 0;
    startnew(file_handler);
    while(true) {
        auto app = GetApp();
        auto playground = app.CurrentPlayground;
        auto network = cast<CTrackManiaNetwork>(app.Network);
#if TMNEXT||MP4
        auto map = app.RootMap;
#elif TURBO
        auto map = app.Challenge;
#endif

        if (startup) {
            start_time = network.PlaygroundClientScriptAPI is null ? 0 : network.PlaygroundClientScriptAPI.GameTime;
            startup = false;
        }
        if (!setting_enabled && !handled_disabled_time) {
            handled_disabled_time = true;

            disabled_start_time = network.PlaygroundClientScriptAPI.GameTime;

            disabled_time = 0;
        }
        if (setting_enabled) {
            if (handled_disabled_time) {
                handled_disabled_time = false;
                disabled_time = network.PlaygroundClientScriptAPI.GameTime;
                total_disabled_time = total_disabled_time + (disabled_time - disabled_start_time);
            }
            if (map is null) {
                handled_timer = false;
                handled_reset = false;
                handled_finish = false;
                handled_respawn = false;

                resets = 0;
                finishes = 0;
                respawns = 0;
                total_disabled_time = 0;
            }
            if (map !is null) {
                if (playground !is null && playground.GameTerminals.Length > 0) {
#if TMNEXT
                        auto terminal = playground.GameTerminals[0];
                        auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
                        auto ui_sequence = terminal.UISequence_Current;
                        if (gui_player !is null) {
                            auto script = gui_player.ScriptAPI;
                            auto post = script.Post;
                            if (!handled_timer && post == CSmScriptPlayer::EPost::Char) {
                                start_time = network.PlaygroundClientScriptAPI.GameTime;
                                handled_timer = true;
                                resets--;
                            }
                            if (!handled_reset && post == CSmScriptPlayer::EPost::Char) {

                                handled_reset = true;
                                resets++;
                                file.set_resets(file.get_resets() + 1);
                            }
                            if (!handled_finish && ui_sequence == CGamePlaygroundUIConfig::EUISequence::Finish) {
                                handled_finish = true;
                                finishes++;
                                file.set_finishes(file.get_finishes() + 1);
                            }

                            if (script.Score.NbRespawnsRequested != temp_respawns && post != CSmScriptPlayer::EPost::Char) {
                                temp_respawns = script.Score.NbRespawnsRequested;
                                respawns++;
                                file.set_respawns(file.get_respawns() + 1);
                            }

                            if (handled_reset && post != CSmScriptPlayer::EPost::Char) {
                                handled_reset = false;
                            }
                            if (handled_finish && ui_sequence != CGamePlaygroundUIConfig::EUISequence::Finish) {
                                handled_finish = false;
                            }
                        }
#elif MP4
                        auto terminal = playground.GameTerminals[0];
                        auto gui_player = cast<CTrackManiaPlayer>(terminal.GUIPlayer);

                        if (gui_player !is null) {
                            auto script = gui_player.ScriptAPI;
                            auto race_state = script.RaceState;

                            

                            if (!handled_timer && race_state == CTrackManiaPlayer::ERaceState::BeforeStart) {
                                start_time = network.PlaygroundClientScriptAPI.GameTime;
                                handled_timer = true;
                                if (finishes == 1) {
                                    finishes--;
                                }
                                resets--;
                            }
                            if (!handled_reset && race_state == CTrackManiaPlayer::ERaceState::BeforeStart) {
                                handled_reset = true;
                                resets++;
                                file.set_resets(file.get_resets() + 1);
                            }
                            if (!handled_finish && race_state == CTrackManiaPlayer::ERaceState::Finished) {
                                handled_finish = true;
                                finishes++;
                                file.set_finishes(file.get_finishes() + 1);
                            }
                            if (handled_reset && race_state != CTrackManiaPlayer::ERaceState::BeforeStart) {
                                handled_reset = false;
                            }
                            if (handled_finish && race_state != CTrackManiaPlayer::ERaceState::Finished) {
                                handled_finish = false;
                            }
                        }
#elif TURBO
                        auto terminal = playground.GameTerminals[0];
                        auto gui_player = cast<CTrackManiaPlayer>(terminal.ControlledPlayer);
                        auto ui_sequence = cast<CGamePlaygroundUIConfig>(network.PlaygroundClientScriptAPI.UI);


                        if (gui_player !is null) {
                            auto race_state = gui_player.RaceState;

                            if (!handled_timer && race_state == CTrackManiaPlayer::ERaceState::BeforeStart) {
                                start_time = network.PlaygroundClientScriptAPI.GameTime;
                                handled_timer = true;
                                if (finishes == 1) {
                                    finishes--;
                                }
                                resets--;
                                
                            }
                            if (!handled_reset && race_state == CTrackManiaPlayer::ERaceState::BeforeStart && ui_sequence.UISequence == CGamePlaygroundUIConfig::EUISequence::Playing) {
                                handled_reset = true;
                                resets++;
                                file.set_resets(file.get_resets() + 1);
                            }
                            if (!handled_finish && race_state == CTrackManiaPlayer::ERaceState::Finished && !network.PlaygroundClientScriptAPI.IsSpectator) {
                                handled_finish = true;
                                finishes++;
                                file.set_finishes(file.get_finishes() + 1);
                            }
                            if (handled_reset && race_state != CTrackManiaPlayer::ERaceState::BeforeStart && (race_state != CTrackManiaPlayer::ERaceState::Finished && !network.PlaygroundClientScriptAPI.IsSpectator)) {
                                handled_reset = false;
                            }
                            if (handled_finish && race_state != CTrackManiaPlayer::ERaceState::Finished) {
                                handled_finish = false;
                            }
                        }
#endif
                }
            }
        }
        yield();
    }
}


void save_time() {
    auto app = GetApp();
    auto playground = app.CurrentPlayground;
    auto network = cast<CTrackManiaNetwork>(app.Network);

    file.set_time(file.get_time() + time - start_time);

    file.write_file();
    
    start_time = network.PlaygroundClientScriptAPI.GameTime;

}

void OnDestroyed() {
    save_time();
}

void RenderSettings() {
    auto app = GetApp();
#if TMNEXT||MP4
    auto rootmap = app.RootMap;
#elif TURBO
    auto rootmap = app.Challenge;
#endif
     if (UI::Button("Reset current map's data")) {
        if (rootmap is null) {
            return;
        }
        file.reset_file();
        resets = 0;
        finishes = 0;
        respawns = 0;
        auto network = cast<CTrackManiaNetwork>(app.Network);
        start_time = network.PlaygroundClientScriptAPI is null ? 0 : network.PlaygroundClientScriptAPI.GameTime;
        UI::ShowNotification("Reset current map's data",4000);
    }
    if (UI::Button("Reset all map data")) {
        if (rootmap !is null) {
        resets = 0;
        finishes = 0;
        respawns = 0;
        auto network = cast<CTrackManiaNetwork>(GetApp().Network);
        start_time = network.PlaygroundClientScriptAPI is null ? 0 : network.PlaygroundClientScriptAPI.GameTime;
        }
        file.reset_all();
        
        UI::ShowNotification("Reset all map data",4000);
    }
}