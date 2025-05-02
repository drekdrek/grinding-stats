bool setting_recap_show_menu = false;
bool load_recap = false;
bool setting_recap_show_colors = setting_show_map_name_color;
int total_files = 0;

void RenderMenu() {
	if (UI::MenuItem(Icons::List + " Grinding Stats Recap", "", setting_recap_show_menu)) {
		total_files = IO::IndexFolder(IO::FromStorageFolder("data"), true).Length;
		setting_recap_show_menu = !setting_recap_show_menu;
	}
}

enum recap_filter {
	all,
	all_with_name,
#if TMNEXT
	current_campaign,
	previous_campaign,
	all_nadeo_campaigns,
	shorts,
	this_week_shorts,
	totd,
#elif MP4 || TURBO
	canyon,
	stadium,
	valley,
	lagoon,
#endif
#if TURBO
	turbo_white,
	turbo_green,
	turbo_blue,
	turbo_red,
	turbo_black,
#endif
	custom
}

string recap_filter_string(recap_filter filter) {
	switch (filter) {
	case recap_filter::all:
		return "All Tracks";
	case recap_filter::custom:
		return "Custom";
#if MP4
	case recap_filter::all_with_name:
		return "All Tracks uploaded to TM² Exchange";
	case recap_filter::canyon:
		return "TM² Canyon Titlepack";
	case recap_filter::stadium:
		return "TM² Stadium Titlepack";
	case recap_filter::valley:
		return "TM² Valley Titlepack";
	case recap_filter::lagoon:
		return "TM² Lagoon Titlepack";
#elif TMNEXT
	case recap_filter::all_with_name:
		return "All Tracks uploaded to NadeoServices";
	case recap_filter::current_campaign:
		return "Current seasonal campaign";
	case recap_filter::previous_campaign:
		return "Previous seasonal campaign";
	case recap_filter::all_nadeo_campaigns:
		return "All seasonal campaigns";
	case recap_filter::totd:
		return "All TOTDs";
	case recap_filter::shorts:
		return "All Weekly Shorts";
	case recap_filter::this_week_shorts:
		return "Current Week's Shorts";
#elif TURBO
	case recap_filter::canyon:
		return "Canyon";
	case recap_filter::stadium:
		return "Stadium";
	case recap_filter::valley:
		return "Valley";
	case recap_filter::lagoon:
		return "Lagoon";
	case recap_filter::turbo_white:
		return "White Tracks (1-40)";
	case recap_filter::turbo_green:
		return "Green Tracks (41-80)";
	case recap_filter::turbo_blue:
		return "Blue Tracks (81-120)";
	case recap_filter::turbo_red:
		return "Red Tracks (121-160)";
	case recap_filter::turbo_black:
		return "Black Tracks (161-200)";
#endif
	}
	return "";
}

recap_filter current_recap = recap_filter::all;

void RenderRecap() {
	if (UI::Begin("Grinding Stats Recap", setting_recap_show_menu, UI::WindowFlags::NoCollapse | UI::WindowFlags::MenuBar)) {
		if (UI::BeginMenuBar()) {
			if (UI::MenuItem(Icons::Refresh + " Refresh")) {
				startnew(CoroutineFunc(recap.refresh));
			}
			UI::Text("Filter:");
			if (UI::BeginCombo("", recap_filter_string(current_recap))) {
				add_selectable(recap_filter::all);
#if TMNEXT || MP4
				add_selectable(recap_filter::all_with_name);
#endif
#if TMNEXT
				add_selectable(recap_filter::current_campaign);
				add_selectable(recap_filter::previous_campaign);
				add_selectable(recap_filter::all_nadeo_campaigns);
				add_selectable(recap_filter::totd);
				add_selectable(recap_filter::shorts);
				add_selectable(recap_filter::this_week_shorts);
#elif MP4 || TURBO
				add_selectable(recap_filter::canyon);
				add_selectable(recap_filter::stadium);
				add_selectable(recap_filter::valley);
				add_selectable(recap_filter::lagoon);
#endif
#if TURBO
				add_selectable(recap_filter::turbo_white);
				add_selectable(recap_filter::turbo_green);
				add_selectable(recap_filter::turbo_blue);
				add_selectable(recap_filter::turbo_red);
				add_selectable(recap_filter::turbo_black);
#endif
				add_selectable(recap_filter::custom);
				UI::EndCombo();
			}
			if (UI::RadioButton("Show colored names", setting_recap_show_colors)) {
				setting_recap_show_colors = !setting_recap_show_colors;
			}
			UI::EndMenuBar();
		}

		uint columns = 8;

		if (!load_recap) {
			auto windowWidth = UI::GetWindowSize();
			string text = "You have " + total_files + " files in your Grinding Stats data folder.\n" +
						  "This will take a while depending on how many files you have.\n" +
						  "It will lag/freeze the game while loading.";
			vec2 textWidth = Draw::MeasureString(text);
			UI::SetCursorPos(vec2(windowWidth.x / 2 - textWidth.x / 2, windowWidth.y / 2 + 25));
			UI::Text(text);
			UI::SetCursorPos(vec2(windowWidth.x / 2 - 100, windowWidth.y / 2 - 25));
			if (UI::Button("Load Recap", vec2(200, 50))) {
				load_recap = true;
				recap.start();
			}
		}

		if (recap.filtered_elements.Length == 0) {
			UI::SetCursorPos(vec2(10, 60));
			if (recap.log.Length > 0) {
				UI::Text("Recap Log");
			}
			for (uint i = 0; i < recap.log.Length; i++) {
				UI::Text(recap.log[i]);
			}
		}

		if (load_recap && UI::BeginTable("Items", columns, UI::TableFlags::Sortable | UI::TableFlags::Resizable | UI::TableFlags::ScrollY | UI::TableFlags::RowBg)) {
			UI::TableSetupScrollFreeze(0, 1);
			UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoHide, 200);
			UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::DefaultSort | UI::TableColumnFlags::PreferSortDescending | UI::TableColumnFlags::NoHide, 150);
			UI::TableSetupColumn("Finishes", UI::TableColumnFlags::WidthFixed, 100);
			UI::TableSetupColumn("Resets", UI::TableColumnFlags::WidthFixed, 100);
#if TMNEXT
			UI::TableSetupColumn("Respawns", UI::TableColumnFlags::WidthFixed, 100);
#elif MP4
			UI::TableSetupColumn("Title pack", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoResize, 100);
#elif TURBO
			UI::TableSetupColumn("Environment", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoResize, 100);
#endif
			UI::TableSetupColumn("Last Played", UI::TableColumnFlags::WidthFixed, 100);
			UI::TableSetupColumn("Medal", UI::TableColumnFlags::WidthFixed, 100);
			UI::TableSetupColumn("Custom Recap", UI::TableColumnFlags::WidthFixed, 100);
			UI::TableHeadersRow();

			auto sortSpecs = UI::TableGetSortSpecs();
			if (sortSpecs !is null && (sortSpecs.Dirty || recap.dirty))
				recap.SortItems(sortSpecs);

			UI::ListClipper clipper(recap.filtered_elements.Length + 1);
			while (clipper.Step()) {
				for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
					string name, map_id, time, finishes, resets, respawns, stripped_name, time_modified;
#if MP4
					string titlepack;
#elif TURBO
					string environment;
#endif
					BaseMedal medal;
					if (i != 0) {
						RecapElement @element = recap.filtered_elements[i - 1];
						stripped_name = element.stripped_name;
						map_id = element.map_id;
						name = element.name;
						time = element.time_string;
						finishes = "" + element.finishes;
						resets = "" + element.resets;
						respawns = "" + element.respawns;
						time_modified = Time::FormatString("%F %r", element.updated_at);
#if MP4
						titlepack = element.titlepack;
#elif TURBO
						environment = element.environment;
#endif
						try {
							medal = element.medal.get_highest_medal();
						} catch {}
					} else {
						map_id = "";
						name = "TOTAL (" + recap.filtered_elements.Length + ")";
						stripped_name = name;
						time = Recap::time_to_string(recap.total_time);
						finishes = "" + recap.total_finishes;
						resets = "" + recap.total_resets;
						respawns = "" + recap.total_respawns;
					}
					UI::TableNextRow();
					UI::TableSetColumnIndex(0);
					UI::AlignTextToFramePadding();
					UI::Text(setting_recap_show_colors ? name : stripped_name);
					if (UI::IsItemHovered() && Meta::IsDeveloperMode()) {
						UI::BeginTooltip();
						if (map_id == stripped_name)
							UI::Text(stripped_name);
						else
							UI::Text(map_id + "\n" + "'" + Text::StripFormatCodes(name) + "'");
						UI::EndTooltip();
					}
					UI::TableSetColumnIndex(1);
					UI::Text(time);
					UI::TableSetColumnIndex(2);
					UI::Text(finishes);
					UI::TableSetColumnIndex(3);
					UI::Text(resets);
					UI::TableSetColumnIndex(4);
#if TMNEXT
					UI::Text(respawns);
#elif MP4
					UI::Text(titlepack);
#elif TURBO
					UI::Text(environment);
#endif
					UI::TableSetColumnIndex(5);
					UI::Text(time_modified);
					UI::TableSetColumnIndex(6);
					if (medal.type != Medals::Type::None) {
						string medal_color = Medals::get_color(medal.type);
						string medal_time = Recap::time_to_string(medal.achieved_time);
#if TURBO
						if (medal.type > 3 && medal.type < 8) {
						// i hate this
							vec2 curPos =  UI::GetCursorPos();
							curPos.y += 4;
							UI::Text(medal_color + Icons::Circle);
							UI::SetCursorPos(curPos);
							UI::Text("\\$0f1"+ Icons::CircleO);
							curPos.x += 21;
							UI::SetCursorPos(curPos);
							UI::Text("" + medal_time);
						} else {
							UI::Text(medal_color + Icons::Circle + " \\$bbb" + medal_time);
						}
#else
						UI::Text(medal_color + Icons::Circle + " \\$bbb" + medal_time);
#endif
					} else if (i != 0) {
						UI::Text(Medals::get_color(Medals::Type::None) + Icons::Circle + " \\$bbb" + "No Data");
					}
					if (i != 0) {
						UI::TableSetColumnIndex(7);
						bool is_cust_map = setting_custom_recap.Contains(map_id);
						if (UI::Checkbox("##" + map_id, is_cust_map) != is_cust_map) {
							if (is_cust_map)
								remove_custom_map(map_id);
							else
								add_custom_map(map_id);
						}
					}
				}
			}
			UI::EndTable();
		}
	}
	UI::End();
}

void add_selectable(recap_filter filter) {
	if (UI::Selectable(recap_filter_string(filter), current_recap == filter)) {
		if (current_recap == filter)
			return;
		current_recap = filter;
		startnew(CoroutineFunc(recap.filter_elements));
	}
}

void add_custom_map(const string &in UID) {
	if (setting_custom_recap != "")
		setting_custom_recap += "\n";
	setting_custom_recap += UID;
	setting_custom_recap = setting_custom_recap.Replace("\n\n", "\n");
}

void remove_custom_map(const string &in UID) {
	setting_custom_recap = setting_custom_recap.Replace(UID, "").Replace("\n\n", "\n");
	if (setting_custom_recap == "\n")
		setting_custom_recap = "";
}
