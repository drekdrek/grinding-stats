void render_stats() {
#if TMNEXT||MP4
    auto map_info = GetApp().RootMap.MapInfo;
#elif TURBO
    auto map_info = GetApp().Challenge.MapInfo;
#endif
    UI::SetNextWindowPos(200, 200, false ? UI::Cond::Always : UI::Cond::FirstUseEver);
    int window_flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
    if (!UI::IsOverlayShown()) window_flags |= UI::WindowFlags::NoInputs;
    UI::Begin("Grinding Stats", window_flags);
        UI::BeginGroup();
            if (setting_show_map_name) {
                UI::BeginTable("header",1,UI::TableFlags::SizingFixedFit);
                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text(COLOR_LIGHT_GRAY + format_string(map_info.Name));
                    UI::TableNextRow();
                    UI::TableNextColumn();
                    UI::Text(COLOR_DARK_GRAY + format_string(map_info.AuthorNickName));
                UI::EndTable();
            }
            UI::BeginTable("table",2,UI::TableFlags::SizingFixedFit);
                if (setting_show_total_time &&
                 (!data.timer.same ||
                  (data.timer.same && !setting_show_session_time) ||
                   (data.timer.same && setting_show_session_time && setting_show_duplicates))) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(COLOR_LIGHT_GRAY + (data.timer.isRunning() ? Icons::ClockO : Icons::PauseCircleO) + " Total Time");
                UI::TableNextColumn();
                UI::Text(COLOR_GRAY + Timer::to_string(data.timer.total));
            }
            if (setting_show_session_time) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(COLOR_LIGHT_GRAY + (data.timer.isRunning() ? Icons::PlayCircleO : Icons::PauseCircleO) + " Session Time");
                UI::TableNextColumn();
                UI::Text(COLOR_GRAY + Timer::to_string(data.timer.session));
            }
            if (setting_show_finishes_session || setting_show_finishes_total) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(COLOR_LIGHT_GRAY + Icons::Flag + " Finishes");
                UI::TableNextColumn();
                UI::Text(COLOR_GRAY + data.finishes.toString());
            }
            if (setting_show_resets_session || setting_show_resets_total) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(COLOR_LIGHT_GRAY + Icons::Repeat + " Resets");
                UI::TableNextColumn();
                UI::Text(data.resets.toString());
            }
#if TMNEXT
            if (setting_show_respawns_current || setting_show_respawns_total || setting_show_respawns_session) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(COLOR_LIGHT_GRAY + Icons::Refresh + " Respawns");
                UI::TableNextColumn();
                UI::Text(data.respawns.toString());
            }
            if (setting_show_time_to_bronze) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(COLOR_LIGHT_GRAY + Icons::Kenney::StarO + " Bronze");
                UI::TableNextColumn();
                UI::Text(data.medals.bronze.toString());
            }
            if (setting_show_time_to_silver) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(COLOR_LIGHT_GRAY + Icons::Kenney::StarHalfO + " Silver");
                UI::TableNextColumn();
                UI::Text(data.medals.silver.toString());
            }
            if (setting_show_time_to_gold) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(COLOR_LIGHT_GRAY + Icons::Kenney::Star + " Gold");
                UI::TableNextColumn();
                UI::Text(data.medals.gold.toString());
            }
            if (setting_show_time_to_author) {
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text(COLOR_LIGHT_GRAY + Icons::Kenney::BadgeAlt + " Author");
                UI::TableNextColumn();
                UI::Text(data.medals.author.toString());
            }
#endif
            UI::EndTable();
        UI::EndGroup();
    UI::End();
}


enum RenderMode {
    Normal,
    Interface
}

void Render() {
    if (can_render(RenderMode::Normal)) render_stats();
}
void RenderInterface() {
    if (setting_recap_show_menu) RenderRecap();

    if (can_render(RenderMode::Interface)) render_stats();

}


bool can_render(RenderMode rendermode) {
    if (rendermode == RenderMode::Normal && (!setting_enabled || setting_display == displays::Only_when_Openplanet_menu_is_open)) return false;
    if (rendermode == RenderMode::Interface && (!setting_enabled || setting_display != displays::Only_when_Openplanet_menu_is_open)) return false;
    
    auto app = cast<CTrackMania>(GetApp());
#if TMNEXT||MP4
    auto map = app.RootMap;
#elif TURBO
    auto map = app.Challenge;
#endif
    if (map is null || map.MapInfo.MapUid == "" || app.Editor !is null) return false;
    if (app.CurrentPlayground is null || app.CurrentPlayground.Interface is null  ||
     (setting_display == displays::Always_except_when_interface_is_hidden && !UI::IsGameUIVisible())) return false;
    return true;
}


string format_string(const string &in str) {
    return setting_show_map_name_color ? ColoredString(str) : StripFormatCodes(str);
}

