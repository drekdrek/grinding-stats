void render_ui() {
#if TMNEXT||MP4
    auto map_info = GetApp().RootMap.MapInfo;
#elif TURBO
    auto map_info = GetApp().Challenge.MapInfo;
#endif
    running = is_timer_running();
    UI::SetNextWindowPos(200, 200, false ? UI::Cond::Always : UI::Cond::FirstUseEver);
    int window_flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
    if (!UI::IsOverlayShown()) window_flags |= UI::WindowFlags::NoInputs;
    UI::Begin("Grinding Stats", window_flags);
         UI::BeginGroup();
         if (setting_show_map_name) {
            UI::BeginTable("header",1,UI::TableFlags::SizingFixedFit);
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + format_string(map_info.Name));
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$888" + format_string(map_info.AuthorNickName));
            UI::EndTable();
        }
            UI::BeginTable("table",2,UI::TableFlags::SizingFixedFit);
            if (setting_show_total_time &&
                 (!time.get_same() ||
                  (time.get_same() && !setting_show_session_time) ||
                   (time.get_same() && setting_show_session_time && setting_show_duplicates))) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + (running ? Icons::ClockO : Icons::PauseCircleO) + " Total Time");
                UI::TableNextColumn();
                UI::Text("\\$bbb" + time.to_string(time.get_total_time()));
            }
            if (setting_show_session_time) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + (running ? Icons::PlayCircleO : Icons::PauseCircleO) + " Session Time");
                UI::TableNextColumn();
                UI::Text("\\$bbb" + time.to_string(time.get_session_time()));
            }
            if (setting_show_finishes_session || setting_show_finishes_total) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::Flag + " Finishes");
                UI::TableNextColumn();
                UI::Text("\\$bbb" + finishes.to_string());
            }
            if (setting_show_resets_session || setting_show_resets_total) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::Repeat + " Resets");
                UI::TableNextColumn();
                UI::Text(resets.to_string());
            }
#if TMNEXT
            if (setting_show_respawns_current || setting_show_respawns_total || setting_show_respawns_session) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::Refresh + " Respawns");
                UI::TableNextColumn();
                UI::Text(respawns.to_string());
            }
#endif
            UI::EndTable();
        UI::EndGroup();
    UI::End();
}

void Render() {

    if (!setting_enabled || setting_display == display_setting::Only_when_Openplanet_menu_is_open) return;
    auto app = cast<CTrackMania>(GetApp());
#if TMNEXT||MP4
    auto map = app.RootMap;
#elif TURBO
    auto map = app.Challenge;
#endif
    auto network = cast<CTrackManiaNetwork>(app.Network);
    if (map is null || map.MapInfo.MapUid == "" || app.Editor !is null) {
        return;
    }
    if(setting_display == display_setting::Always_except_when_interface_is_hidden) {
        auto playground = app.CurrentPlayground;
    if (playground is null || playground.Interface is null  || !UI::IsGameUIVisible() ) {
            return;
    }
    }
    render_ui();
    if (setting_show_debug) debug_render();
}
void RenderInterface() {
    if (!setting_enabled || setting_display != display_setting::Only_when_Openplanet_menu_is_open) return;
    auto app = cast<CTrackMania>(GetApp());
#if TMNEXT||MP4
    auto map = app.RootMap;
#elif TURBO
    auto map = app.Challenge;
#endif
    auto network = cast<CTrackManiaNetwork>(app.Network);
    if (map is null) {
        return;
    }
    if(setting_display == display_setting::Always_except_when_interface_is_hidden) {
        auto playground = app.CurrentPlayground;
        if (playground is null || playground.Interface is null || !UI::IsGameUIVisible()) {
            return;
        }
    }
    render_ui();

}

string format_string(const string &in str) {
    return setting_show_map_name_color ? ColoredString(str) : StripFormatCodes(str);
}

