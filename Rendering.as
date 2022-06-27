void render_ui() {
#if TMNEXT||MP4
    auto map_info = GetApp().RootMap.MapInfo;
#elif TURBO
    auto map_info = GetApp().Challenge.MapInfo;
#endif
    running = is_timer_running();
    UI::SetNextWindowPos(200, 200, false ? UI::Cond::Always : UI::Cond::FirstUseEver);
    int window_flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
    if (!UI::IsOverlayShown()) {
        window_flags |= UI::WindowFlags::NoInputs;
    }
    UI::Begin("Grinding Stats", window_flags);
         UI::BeginGroup();  
         if (setting_show_map_name) {
            UI::BeginTable("header",1,UI::TableFlags::SizingFixedFit);
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + StripFormatCodes(map_info.Name));
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$888" + StripFormatCodes(map_info.AuthorNickName));
            UI::EndTable();
        }
            UI::BeginTable("table",2,UI::TableFlags::SizingFixedFit);
            if (setting_show_total_time && !(!setting_show_duplicates && total_time.get_offset() == session_time.get_offset())) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::ClockO + " Total Time");
                UI::TableNextColumn();
                UI::Text("\\$bbb" + total_time.get_time_string());
            }
            if (setting_show_session_time || (setting_show_duplicates && total_time.get_time() == session_time.get_time())) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::PlayCircleO + " Session Time");
                UI::TableNextColumn();
                UI::Text("\\$bbb" + session_time.get_time_string());
            }
            if (setting_show_finishes_session || setting_show_finishes_total) {
                string text = setting_show_finishes_session ? "\\$bbb" + finishes.get_session_finishes() : "";
                if (!(!setting_show_duplicates && finishes.get_session_finishes() == finishes.get_total_finishes())) {
                    text += setting_show_finishes_session && setting_show_finishes_total ? "\\$fff  /  " : "";
                    text += setting_show_finishes_total ? "\\$bbb" + finishes.get_total_finishes() : "";
                }
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::Flag + " Finishes");
                UI::TableNextColumn();
                UI::Text("\\$bbb" +text);
            }
            if (setting_show_resets_session || setting_show_resets_total) {
                string text = setting_show_resets_session ? "\\$bbb" + resets.get_session_resets() : "";
                if (!(!setting_show_duplicates && resets.get_session_resets() == resets.get_total_resets())) {
                    text += setting_show_resets_session && setting_show_resets_total ? "\\$fff  /  " : "";
                    text += setting_show_resets_total ? "\\$bbb" + resets.get_total_resets() : "";
                }
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("\\$ddd" + Icons::Repeat + " Resets");
                UI::TableNextColumn();
                UI::Text(text);
            }
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