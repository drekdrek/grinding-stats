bool setting_recap_show_menu = false;
bool setting_recap_show_colors = setting_show_map_name_color;

void RenderMenu() {
    if (UI::MenuItem(Icons::List + " Grinding Stats Recap","",setting_recap_show_menu)) {
        setting_recap_show_menu = !setting_recap_show_menu;
        if (setting_recap_show_menu) recap.start();
    }
}

enum recap_filter {
    all,
    all_with_name,
#if TMNEXT
    current_campaign,
    all_nadeo_campaigns,
#elif TURBO
    turbo_white,
    turbo_green,
    turbo_blue,
    turbo_red,
    turbo_black,
#endif
    totd
    }

string recap_filter_string(recap_filter filter) {
    switch(filter){
        case recap_filter::all:
            return "All Tracks";
#if MP4 
        case recap_filter::all_with_name:
            return "All Tracks uploaded to TM² Exchange";
#elif TMNEXT 
        case recap_filter::all_with_name:
            return "All Tracks uploaded to NadeoServices";
        case recap_filter::current_campaign:
            return "Current seasonal campaign";
        case recap_filter::all_nadeo_campaigns:
            return "All seasonal campaigns";
        case recap_filter::totd:
            return "All TOTDs";
#elif TURBO
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
    UI::PushStyleVar(UI::StyleVar::Alpha, float(1.022));
    if(UI::Begin("Grinding Stats Recap",setting_recap_show_menu,UI::WindowFlags::NoCollapse | UI::WindowFlags::MenuBar)) {
        //menu bar
        if (UI::BeginMenuBar()) {
            if (UI::MenuItem(Icons::Refresh + " Refresh")) {
                startnew(CoroutineFunc(recap.refresh));
            }
            UI::Text("Filter:");
            if(UI::BeginCombo("",recap_filter_string(current_recap))) {
                add_selectable(recap_filter::all);
#if TMNEXT || MP4
                add_selectable(recap_filter::all_with_name);
#endif
#if TMNEXT
                add_selectable(recap_filter::current_campaign);
                add_selectable(recap_filter::all_nadeo_campaigns);
                add_selectable(recap_filter::totd);
#elif TURBO
                add_selectable(recap_filter::turbo_white);
                add_selectable(recap_filter::turbo_green);
                add_selectable(recap_filter::turbo_blue);
                add_selectable(recap_filter::turbo_red);
                add_selectable(recap_filter::turbo_black);
#endif
            UI::EndCombo();
            }
            //bool UI::RadioButton(const string&in label, bool active)
            if (UI::RadioButton("Show colored names", setting_recap_show_colors)) {
                setting_recap_show_colors = !setting_recap_show_colors;
            }
                    
        UI::EndMenuBar();
        }
#if TURBO
uint columns = 5;
#elif TMNEXT
uint columns = 10;
#elif MP4
uint columns = 6;
#endif
        if (UI::BeginTable("Items",columns,UI::TableFlags::Sortable | UI::TableFlags::Resizable | UI::TableFlags::ScrollY)) {
            //headers

            UI::TableSetupColumn("Name",UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::NoHide,200);
            UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::DefaultSort |
                                         UI::TableColumnFlags::PreferSortDescending | UI::TableColumnFlags::NoHide,150);
            UI::TableSetupColumn("Finishes",UI::TableColumnFlags::WidthFixed,100);
            UI::TableSetupColumn("Resets",UI::TableColumnFlags::WidthFixed,100);
#if TMNEXT
            UI::TableSetupColumn("Respawns",UI::TableColumnFlags::WidthFixed,100);
            UI::TableSetupColumn(
                "Bronze" + recap.medal_totals.bronze_perc,
                UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::PreferSortDescending,
                150
            );
            UI::TableSetupColumn(
                "Silver" + recap.medal_totals.silver_perc,
                UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::PreferSortDescending,
                150
            );
            UI::TableSetupColumn(
                "Gold" + recap.medal_totals.gold_perc,
                UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::PreferSortDescending,
                150
            );
            UI::TableSetupColumn(
                "Author" + recap.medal_totals.author_perc,
                UI::TableColumnFlags::WidthFixed | UI::TableColumnFlags::PreferSortDescending,
                150
            );
#elif MP4
            UI::TableSetupColumn("Title pack",UI::TableColumnFlags::WidthFixed|UI::TableColumnFlags::NoResize,100);
#endif
            UI::TableSetupColumn("Last Played", UI::TableColumnFlags::WidthFixed, 100);
            UI::TableHeadersRow();

            //sorting
            auto sortSpecs = UI::TableGetSortSpecs();
            if (sortSpecs !is null && (sortSpecs.Dirty || recap.dirty)) recap.SortItems(sortSpecs);

            //drawing items
            UI::ListClipper clipper(recap.filtered_elements.Length + 1);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                        string name;
                        string map_id;
                        string time;
                        string finishes;
                        string resets;
                        string respawns;
                        string time_to_bronze;
                        string time_to_silver;
                        string time_to_gold;
                        string time_to_author;
                        string stripped_name;
                        string time_modified;
#if MP4
                        string titlepack;
#endif
                    if (i != 0) {
                        RecapElement@ element = recap.filtered_elements[i - 1];
                        stripped_name = element.stripped_name;
                        map_id = element.map_id;
                        name = element.name;
                        time = element.time;
                        finishes = "" + element.finishes;
                        resets = "" + element.resets;
                        respawns = "" + element.respawns;
                        time_to_bronze = element.time_to_bronze.to_string();
                        time_to_silver = element.time_to_silver.to_string();
                        time_to_gold = element.time_to_gold.to_string();
                        time_to_author = element.time_to_author.to_string();
                        time_modified = Time::FormatString("%F %r",element.modified_time);
#if MP4
                        titlepack = element.titlepack;
#endif
                    } else {
                        map_id = "";
                        name = "TOTAL (" + recap.filtered_elements.Length + ")";
                        stripped_name = name;
                        time = Timer::to_string(recap.total_time);
                        finishes = "" + recap.total_finishes;
                        resets = "" + recap.total_resets;
                        respawns = "" + recap.total_respawns;
                        time_to_bronze = recap.medal_totals.bronze_totals;
                        time_to_silver = recap.medal_totals.silver_totals;
                        time_to_gold = recap.medal_totals.gold_totals;
                        time_to_author = recap.medal_totals.author_totals;
                        time_modified = "--:--:--";
                    }
                        UI::TableNextRow();
                        UI::TableSetColumnIndex(0);
                        UI::Text(setting_recap_show_colors ? name : stripped_name);
                        if (UI::IsItemHovered() && Meta::IsDeveloperMode()) {
                            UI::BeginTooltip();
                                if (map_id == stripped_name) UI::Text(stripped_name);
                                else UI::Text(map_id + "\n" + "'" + StripFormatCodes(name) + "'"); 
                            UI::EndTooltip();
                        }
                        UI::TableSetColumnIndex(1);
                        UI::Text(time);
                        UI::TableSetColumnIndex(2);
                        UI::Text(finishes);
                        UI::TableSetColumnIndex(3);
                        UI::Text(resets);
#if TMNEXT
                        UI::TableSetColumnIndex(4);
                        UI::Text(respawns);
                        UI::TableSetColumnIndex(5);
                        UI::Text(time_to_bronze);
                        UI::TableSetColumnIndex(6);
                        UI::Text(time_to_silver);
                        UI::TableSetColumnIndex(7);
                        UI::Text(time_to_gold);
                        UI::TableSetColumnIndex(8);
                        UI::Text(time_to_author);
                        UI::TableSetColumnIndex(9);
                        UI::Text(time_modified);
#elif MP4
                        UI::TableSetColumnIndex(4);
                        UI::Text(titlepack);
                        UI::TableSetColumnIndex(5);
                        UI::Text(time_modified);
#else
                        UI::TableSetColumnIndex(4);
                        UI::Text(time_modified);
#endif
                }
            }
        UI::EndTable();
        }
    }
    UI::End();
    UI::PopStyleVar();
}

void add_selectable(recap_filter filter) {
    if(UI::Selectable(recap_filter_string(filter), current_recap == filter)){
        if (current_recap == filter) return;
        current_recap = filter;
        startnew(CoroutineFunc(recap.filter_elements));
    } 
}