void render_ui() {
    auto app = cast<CTrackMania>(GetApp());
#if TMNEXT||MP4
    auto map = app.RootMap;
#elif TURBO
    auto map = app.Challenge;
#endif
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
                UI::Text("\\$888" + StripFormatCodes(map.MapInfo.AuthorNickName));
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
#if TMNEXT
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
#endif
        }
        UI::EndTable();
    UI::EndGroup();
    UI::End();
}
void render_time(int t) {
    int hour = int(Math::Floor((t) / 3600000));
    int minute =  int(Math::Floor((t) / 60000 - hour * 60));
    int second =  int(Math::Floor((t) / 1000 - hour * 3600 - minute * 60));
    int millisecond = Text::ParseInt(Text::Format("%03d",(t) % 1000).SubStr(0,(setting_show_thousands ? 3 : 2)));
    UI::Text("\\$bbb" + (setting_show_hour_if_0 || hour > 0 ? Time::Internal::PadNumber(hour,2) + ":" : "") + Time::Internal::PadNumber(minute,2) + ":" + Time::Internal::PadNumber(second,2) + "." + Time::Internal::PadNumber(millisecond,setting_show_thousands ? 3 : 2));
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
#if TMNEXT
       if (playground is null || playground.Interface is null  || !UI::IsGameUIVisible() ) {
            return;
        }

#elif MP4||TURBO
        if(playground is null || playground.Interface is null || Dev::GetOffsetUint32(playground.Interface, 0x1C) == 0) {
            return;
        }
#endif
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
#if TMNEXT
        if (playground is null || playground.Interface is null || !UI::IsGameUIVisible()) {
            return;
        }
#elif MP4
        if(playground is null || playground.Interface is null || Dev::GetOffsetUint32(playground.Interface, 0x1C) == 0) {
            return;
        }
#endif
    }
    render_ui();
}