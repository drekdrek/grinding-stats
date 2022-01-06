enum display_setting
{
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

[Setting name="Show only one number" category="UI" description="Only one number is shown, instead of showing the same number twice."]
bool setting_show_only_one_number = false;

[Setting name="Show only one time" category="UI" description="Only one time is shown, instead of showing the same time twice."]
bool setting_show_only_one_time = false;

[Setting name="Show map name/author" category="UI"]
bool setting_show_map_name = true;

[Setting name="Show thousands" category="UI"]
bool setting_show_thousands = true;

[Setting name="Show hour if 0" category="UI"]
bool setting_show_hour_if_0 = true;

[Setting name="Show Time spent on current Campaign" category="Stats"]
bool setting_show_campaign_time = false;

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


[Setting name="Show Session respawns" category="Stats"]
bool setting_show_respawns_session = false;
[Setting name="Show Total respawns" category="Stats"]
bool setting_show_respawns_total = false;


<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes
uint finishes = 0;
uint resets = 0;
uint respawns = 0;
uint start_time = 0;
uint time = 0;
uint disabled_time = 0;
uint total_disabled_time = 0;
uint disabled_start_time = 0;
string map_id = "";
vec2 anchor = vec2(0,500);
Files file;

<<<<<<< Updated upstream
uint disabled_time = 0;
uint total_disabled_time = 0;
uint disabled_start_time = 0;

void Main() {
    bool handled_timer = false;
    bool handled_reset = false ;
    bool handled_finish = false;
    bool handled_file = false;
    bool handled_respawn = false;
    bool handled_pb = false;
    bool handled_disable = false;
    bool handled_disabled_time = false;
    uint temp_respawns = 0;
    

=======
bool handled_timer = false;
bool handled_reset = false ;
bool handled_finish = false;
bool handled_respawn = false;
bool handled_pb = false;
bool handled_disable = false;
bool handled_disabled_time = false;
bool handled_file = false;

void file_loader() {
    while(true) {
    CGameCtnApp@ app = GetApp();
    auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
    auto network = cast<CTrackManiaNetwork>(app.Network);
    {
        map_id = (playground is null || playground.Map is null) ? "" : playground.Map.IdName;
        handled_file = map_id == file.get_map_id();
        if (!handled_file) {
            if (file !is null) {save_time(-4000);}
            file = Files(map_id);
            start_time = network.PlaygroundClientScriptAPI.GameTime;
            handled_file = true;
            handled_timer = false;
        }
    }
    yield();   
    }
}
void Main() {
    uint temp_respawns = 0;
    startnew(file_loader);
>>>>>>> Stashed changes
    while(true) {
        CGameCtnApp@ app = GetApp();
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
        auto network = cast<CTrackManiaNetwork>(app.Network);

        if (!setting_enabled && !handled_disable) {
            if (!handled_disabled_time) {
                handled_disabled_time = true;
                disabled_start_time = network.PlaygroundClientScriptAPI.GameTime;
                disabled_time = 0;
            }
        }
        if (setting_enabled) {
            if (handled_disabled_time) {
                handled_disabled_time = false;
                disabled_time = network.PlaygroundClientScriptAPI.GameTime;
                total_disabled_time = total_disabled_time + (disabled_time - disabled_start_time);
            }
            if (handled_disable)
            handled_disable = false;
            

            if (app.RootMap is null) {
                
                handled_timer = false;
                handled_reset = false;
                handled_finish = false;
                handled_respawn = false;
                handled_pb = false;
                

                resets = 0;
                finishes = 0;
                start_time = 0;
                respawns = 0;
<<<<<<< Updated upstream
                pbs = 0;
=======
>>>>>>> Stashed changes
                total_disabled_time = 0;
            }
            if (app.RootMap !is null) {

                if (playground !is null && playground.Arena !is null
                && playground.Map !is null && playground.GameTerminals.Length > 0 ) {

                    auto terminal = playground.GameTerminals[0];
                    auto player = cast<CSmPlayer>(terminal.GUIPlayer);
                    auto ui_sequence = terminal.UISequence_Current;

                    if (player !is null) {
                        auto script = player.ScriptAPI;
                        auto post = script.Post;
                        if (!handled_timer && post == CSmScriptPlayer::EPost::Char) {
                            //not using Time::Now, because Time::Now doesn't pause when the game is paused.
                            start_time = network.PlaygroundClientScriptAPI.GameTime;
                            handled_timer = true;
                        }
                        if (!handled_reset && post == CSmScriptPlayer::EPost::Char) {
                            resets++;
                            file.set_resets(file.get_resets()+ 1);
                            handled_reset = true;
                        }
                        if (handled_reset && post != CSmScriptPlayer::EPost::Char) {
                            handled_reset = false;
                        }
                        if (script.Score.NbRespawnsRequested != temp_respawns && post != CSmScriptPlayer::EPost::Char) {
                            temp_respawns = script.Score.NbRespawnsRequested;
                            respawns++;
                            file.set_respawns(file.get_respawns()+ 1);
                        }
                        
                    }
                    if (!handled_finish && ui_sequence == CGamePlaygroundUIConfig::EUISequence::Finish
                    && player !is null) {
                        handled_finish = true;
                        finishes++;
                        file.set_finishes(file.get_finishes()+ 1);
                    }
                    if (ui_sequence != CGamePlaygroundUIConfig::EUISequence::Finish) {
                        handled_finish = false;
                    }
                }
            }
        }
        yield();
    }
}

void render_ui() {
    auto app = cast<CTrackMania>(GetApp());
    auto map = app.RootMap;
    auto network = cast<CTrackManiaNetwork>(app.Network);
    time = network.PlaygroundClientScriptAPI.GameTime - (total_disabled_time);
    UI::SetNextWindowPos(int(anchor.x), int(anchor.y), setting_lock_window_location ? UI::Cond::Always : UI::Cond::FirstUseEver);

    int window_flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
    if (!UI::IsOverlayShown()) {
        window_flags |= UI::WindowFlags::NoInputs;
    }
    UI::Begin("Grinding Stats", window_flags);
    if (!setting_lock_window_location) {
        anchor = UI::GetWindowPos();
    }
    UI::BeginGroup();
        if (setting_show_map_name) {
            UI::BeginTable("header",1,UI::TableFlags::SizingFixedFit);
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + StripFormatCodes(map.MapInfo.Name));
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$888" + map.MapInfo.AuthorNickName);
            UI::EndTable();
        }
        int columns = 2;
        if (UI::BeginTable("table",columns,UI::TableFlags::SizingFixedFit)){
            if (setting_show_total_time && !(setting_show_only_one_time && file.get_time() == 0)) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::ClockO + " Total Time");
                UI::TableNextColumn();
                render_time(file.get_time() + time - start_time);

            }
            if (setting_show_session_time || (setting_show_only_one_time && file.get_time() == time-start_time)) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::PlayCircleO + " Session Time");
                UI::TableNextColumn();
                render_time(time-start_time);
            }
            if (setting_show_finishes_session || setting_show_finishes_total) {
                string text = setting_show_finishes_session ? "\\$bbb" + finishes : "";
                if (!(setting_show_only_one_number && finishes == file.get_finishes())) {
                    text += setting_show_finishes_session && setting_show_finishes_total ? "\\$fff  /  " : "";
                    text += setting_show_finishes_total ? "\\$bbb" + file.get_finishes() : "";
                }

                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::Flag + " Finishes");
                UI::TableNextColumn();
                UI::Text("\\$bbb" +text);
            }
            if (setting_show_resets_session || setting_show_resets_total) {
                string text = setting_show_resets_session ? "\\$bbb" + resets : "";
                if (!(setting_show_only_one_number && resets == file.get_resets())) {
                    text += setting_show_resets_session && setting_show_resets_total ? "\\$fff  /  " : "";
                    text += setting_show_resets_total ? "\\$bbb" + file.get_resets() : "";
                }

                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::Repeat + " Resets");
                UI::TableNextColumn();
                UI::Text(text);
            }
            if (setting_show_respawns_session || setting_show_respawns_total) {
                string text = setting_show_respawns_session ? "\\$bbb" + respawns : "";
                if (!(setting_show_only_one_number && respawns == file.get_respawns())) {
                    text += setting_show_respawns_session && setting_show_respawns_total ? "\\$fff  /  " : "";
                    text += setting_show_respawns_total ? "\\$bbb" + file.get_respawns() : "";
                }

                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::Refresh + " Respawns");
                UI::TableNextColumn();
                UI::Text(text);
            }
        }
        UI::EndTable();
    UI::EndGroup();
    UI::End();
}

void Render() {
    if (!setting_enabled || setting_display == display_setting::Only_when_Openplanet_menu_is_open) return;
    auto app = cast<CTrackMania>(GetApp());
    auto map = app.RootMap;
    auto network = cast<CTrackManiaNetwork>(app.Network);
    if (app.RootMap is null) {
        return;
    }
    if(setting_display == display_setting::Always_except_when_interface_is_hidden) {
        auto playground = app.CurrentPlayground;
        if(playground is null || playground.Interface is null || Dev::GetOffsetUint32(playground.Interface, 0x1C) == 0) {
            return;
        }
    }
    render_ui();
}
void RenderInterface() {
    if (!setting_enabled || setting_display != display_setting::Only_when_Openplanet_menu_is_open) return;
    auto app = cast<CTrackMania>(GetApp());
    auto map = app.RootMap;
    auto network = cast<CTrackManiaNetwork>(app.Network);
    if (app.RootMap is null) {
        return;
    }
    if(setting_display == display_setting::Always_except_when_interface_is_hidden) {
        auto playground = app.CurrentPlayground;
        if(playground is null || playground.Interface is null || Dev::GetOffsetUint32(playground.Interface, 0x1C) == 0) {
            return;
        }
    }
    render_ui();
}


void render_time(int t) {
    int hour = int(Math::Floor((t) / 3600000));
    int minute =  int(Math::Floor((t) / 60000 - hour * 60));
    int second =  int(Math::Floor((t) / 1000 - hour * 3600 - minute * 60));
    int millisecond = Text::ParseInt(Text::Format("%03d",(t) % 1000).SubStr(0,(setting_show_thousands ? 3 : 2)));
    UI::Text("\\$bbb" + (setting_show_hour_if_0 || hour > 0 ? Time::Internal::PadNumber(hour,2) + ":" : "") + Time::Internal::PadNumber(minute,2) + ":" + Time::Internal::PadNumber(second,2) + "." + Time::Internal::PadNumber(millisecond,setting_show_thousands ? 3 : 2));
}

void save_time(int offset) {
    file.set_time(file.get_time() + time - start_time + offset);
    file.write_file();
}