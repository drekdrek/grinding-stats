enum RenderMode {
	Normal,
	Interface
}

bool should_render(RenderMode rendermode) {
	if (rendermode == RenderMode::Normal && (!setting_enabled || setting_display == displays::Only_when_Openplanet_menu_is_open))
		return false;
	if (rendermode == RenderMode::Interface && (!setting_enabled || setting_display != displays::Only_when_Openplanet_menu_is_open))
		return false;

	auto app = cast<CTrackMania>(GetApp());
#if TMNEXT || MP4
	auto map = app.RootMap;
#elif TURBO
	auto map = app.Challenge;
#endif
	if (map is null || map.MapInfo.MapUid == "" || app.Editor !is null)
		return false;
	if (app.CurrentPlayground is null || app.CurrentPlayground.Interface is null ||
		(setting_display == displays::Always_except_when_interface_is_hidden && !UI::IsGameUIVisible()))
		return false;
	return true;
}

void Render() {
	if (should_render(RenderMode::Normal))
		render_stats_ui();
}

void RenderInterface() {
	if (setting_recap_show_menu)
		RenderRecap();
	if (should_render(RenderMode::Interface))
		render_stats_ui();
}

void render_stats_ui() {
#if TMNEXT || MP4
	auto map_info = GetApp().RootMap.MapInfo;
#elif TURBO
	auto map_info = GetApp().Challenge.MapInfo;
#endif

	UI::SetNextWindowPos(200, 200, false ? UI::Cond::Always : UI::Cond::FirstUseEver);
	int window_flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse |
					   UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
	if (!UI::IsOverlayShown())
		window_flags |= UI::WindowFlags::NoInputs;
	UI::Begin("Grinding Stats", window_flags);
	UI::BeginGroup();

	if (setting_show_map_name) {
		UI::BeginTable("header", 1, UI::TableFlags::SizingFixedFit);
		UI::TableNextRow();
		UI::TableNextColumn();
		UI::Text("\\$ddd" + format_string(map_info.Name));
		UI::TableNextRow();
		UI::TableNextColumn();
		UI::Text("\\$888" + format_string(map_info.AuthorNickName));
		UI::EndTable();
	}

	UI::BeginTable("table", 2, UI::TableFlags::SizingFixedFit);
	if (setting_show_total_time &&
		(!data.timer.same || (data.timer.same && !setting_show_session_time) ||
		 (data.timer.same && setting_show_session_time && setting_show_duplicates))) {
		UI::TableNextRow();
		UI::TableNextColumn();
		UI::Text("\\$ddd" + (data.timer.isRunning() ? Icons::ClockO : Icons::PauseCircleO) + " Total Time");
		UI::TableNextColumn();
		UI::Text("\\$bbb" + data.timer.toString(data.timer.total));
	}
	if (setting_show_session_time) {
		UI::TableNextRow();
		UI::TableNextColumn();
		UI::Text("\\$ddd" + (data.timer.isRunning() ? Icons::PlayCircleO : Icons::PauseCircleO) + " Session Time");
		UI::TableNextColumn();
		UI::Text("\\$bbb" + data.timer.toString(data.timer.session));
	}
	if (setting_show_finishes_session || setting_show_finishes_total) {
		UI::TableNextRow();
		UI::TableNextColumn();
		UI::Text("\\$ddd" + Icons::Flag + " Finishes");
		UI::TableNextColumn();
		UI::Text("\\$bbb" + data.finishes.toString());
	}
	if (setting_show_resets_session || setting_show_resets_total) {
		UI::TableNextRow();
		UI::TableNextColumn();
		UI::Text("\\$ddd" + Icons::Repeat + " Attempts");
		UI::TableNextColumn();
		UI::Text(data.resets.toString());
	}
#if TMNEXT
	if (setting_show_respawns_current || setting_show_respawns_total || setting_show_respawns_session) {
		UI::TableNextRow();
		UI::TableNextColumn();
		UI::Text("\\$ddd" + Icons::Refresh + " Respawns");
		UI::TableNextColumn();
		UI::Text(data.respawns.toString());
	}
#endif
	UI::EndTable();
	UI::EndGroup();
	UI::End();
}

string format_string(const string &in str) {
	return setting_show_map_name_color ? Text::OpenplanetFormatCodes(str) : Text::StripFormatCodes(str);
}