namespace Recap {
    enum campaign_filter {
        current,
        all
    }
    enum turbo_filter {
        white,
        green,
        blue,
        red,
        black
    }
}
class Recap {
    array<string> totds;
    array<string> campaigns;
    array<string> current_campaign;
    array<RecapElement@> elements;
    array<RecapElement@> filtered_elements;
    bool dirty;
    bool started = false;
    uint64 total_time = 0;
    uint total_finishes = 0;
    uint total_resets = 0;
    uint total_respawns = 0;
    MedalTotals@ medal_totals = MedalTotals();

    private void count_total_time() {
        total_time = 0;
        for (uint i = 0; i < filtered_elements.Length; i++) {
            total_time+= filtered_elements[i].time_uint;
        }
    }

    private void count_total_finishes() {
         total_finishes = 0;
        for (uint i = 0; i < filtered_elements.Length; i++) {
            total_finishes += filtered_elements[i].finishes;
        }
    }

    private void count_total_resets() {
        total_resets = 0;
        for (uint i = 0; i < filtered_elements.Length; i++) {
            total_resets += filtered_elements[i].resets;
        }
    }

    private void count_total_respawns() {
        total_respawns = 0;
        for (uint i = 0; i < filtered_elements.Length; i++) {
            total_respawns += filtered_elements[i].respawns;
        }
    }

    private void count_totals_for_medals() {
        medal_totals.count_totals(filtered_elements);
    }

    private void count_totals() {
        count_total_finishes();
        count_total_resets();
        count_total_respawns();
        count_total_time();
        count_totals_for_medals();
    }

    Recap() {
        elements = array<RecapElement@>();
        dirty = false;
    }

    void SortItems(UI::TableSortSpecs@ sortSpecs) {
        startnew(CoroutineFuncUserdata(sort_items),sortSpecs);
        sortSpecs.Dirty = false;
        dirty = false;
    }
    private void sort_items(ref@ s) {
        //coroutineFunc of sorting the items
        if (filtered_elements.Length < 2) return;

        auto specs = (cast<UI::TableSortSpecs@>(s)).Specs;
        for (uint i = 0; i < specs.Length; i++) {
            auto spec = specs[i];

            if (spec.SortDirection == UI::SortDirection::None) continue;

            if (spec.SortDirection == UI::SortDirection::Ascending) {
                switch(spec.ColumnIndex) {
                    case 0: filtered_elements.Sort(function(a,b) {return a.stripped_name < b.stripped_name;});break;
                    case 1: filtered_elements.Sort(function(a,b) {return a.time_uint < b.time_uint;});break;
                    case 2: filtered_elements.Sort(function(a,b) {return a.finishes < b.finishes;});break;
                    case 3: filtered_elements.Sort(function(a,b) {return a.resets < b.resets;});break;
#if TMNEXT
                    case 4: filtered_elements.Sort(function(a,b) {return a.respawns < b.respawns;});break;
                    case 5: filtered_elements.Sort(function(a,b) {return a.time_to_bronze.sort_val < b.time_to_bronze.sort_val;});break;
                    case 6: filtered_elements.Sort(function(a,b) {return a.time_to_silver.sort_val < b.time_to_silver.sort_val;});break;
                    case 7: filtered_elements.Sort(function(a,b) {return a.time_to_gold.sort_val < b.time_to_gold.sort_val;});break;
                    case 8: filtered_elements.Sort(function(a,b) {return a.time_to_author.sort_val < b.time_to_author.sort_val;});break;
                    case 9: filtered_elements.Sort(function(a,b) {return a.modified_time < b.modified_time;});break;
#elif MP4
                    case 4: filtered_elements.Sort(function(a,b) {return a.titlepack < b.titlepack;});break;
                    case 5: filtered_elements.Sort(function(a,b) {return a.modified_time < b.modified_time;});break;
#else
                    case 4: filtered_elements.Sort(function(a,b) {return a.modified_time < b.modified_time;});break;
#endif
                }
            }
            else if (spec.SortDirection == UI::SortDirection::Descending) {
                switch(spec.ColumnIndex) {
                    case 0: filtered_elements.Sort(function(a,b) {return a.stripped_name > b.stripped_name;});break;
                    case 1: filtered_elements.Sort(function(a,b) {return a.time_uint > b.time_uint;});break;
                    case 2: filtered_elements.Sort(function(a,b) {return a.finishes > b.finishes;});break;
                    case 3: filtered_elements.Sort(function(a,b) {return a.resets > b.resets;});break;
#if TMNEXT
                    case 4: filtered_elements.Sort(function(a,b) {return a.respawns > b.respawns;});break;
                    case 5: filtered_elements.Sort(function(a,b) {return a.time_to_bronze.sort_val > b.time_to_bronze.sort_val;});break;
                    case 6: filtered_elements.Sort(function(a,b) {return a.time_to_silver.sort_val > b.time_to_silver.sort_val;});break;
                    case 7: filtered_elements.Sort(function(a,b) {return a.time_to_gold.sort_val > b.time_to_gold.sort_val;});break;
                    case 8: filtered_elements.Sort(function(a,b) {return a.time_to_author.sort_val > b.time_to_author.sort_val;});break;
                    case 9: filtered_elements.Sort(function(a,b) {return a.modified_time > b.modified_time;});break;
#elif MP4
                    case 4: filtered_elements.Sort(function(a,b) {return a.titlepack > b.titlepack;});break;
                    case 5: filtered_elements.Sort(function(a,b) {return a.modified_time > b.modified_time;});break;
#else
                    case 4: filtered_elements.Sort(function(a,b) {return a.modified_time > b.modified_time;});break;
#endif
                }
            }
            yield();
        }
    }
    void start() {
        startnew(CoroutineFunc(load_files));
    }

    void refresh() {
        elements = array<RecapElement@>();
        campaigns = array<string>();
        current_campaign = array<string>();
        totds = array<string>();
        await(startnew(CoroutineFunc(load_files)));
        count_totals();
        filter_elements();
    }
    
    private void load_files() {
        auto files = IO::IndexFolder(folder_location, true);
        if (elements.Length != files.Length) {
            elements = array<RecapElement@>();
        } else {return;}
        uint path_length = (folder_location + '/').Length;
        //loading files will be done in batches of 100
        uint batches = uint(Math::Ceil(files.Length / 100.0));
        for (uint i = 0; i < batches; i++) {
            //100 or less if there is less than 100 left
            uint amt = Math::Min(100,files.Length - (i * 100));
            for (uint j = 0; j < amt; j++) {
                string map_id = files[i * 100 + j].SubStr(path_length, files[i * 100 + j].Length - 5 - path_length);
                elements.InsertLast(RecapElement(map_id));
            }
            yield();
        }
        dirty = true;
        count_totals();
        recap.filter_elements();
    }
    void filter_elements() {
        filtered_elements = array<RecapElement@>();
        switch(current_recap) {
            case recap_filter::all: this.filter_all(true); break;
#if TMNEXT || MP4
            case recap_filter::all_with_name: this.filter_all(false); break;
#endif
#if TMNEXT
            case recap_filter::current_campaign: this.filter_campaign(Recap::campaign_filter::current); break;
            case recap_filter::all_nadeo_campaigns: this.filter_campaign(Recap::campaign_filter::all); break;
            case recap_filter::totd: this.filter_totd(); break;
#elif TURBO
            case recap_filter::turbo_white: this.filter_turbo(Recap::turbo_filter::white); break;
            case recap_filter::turbo_green: this.filter_turbo(Recap::turbo_filter::green); break;
            case recap_filter::turbo_blue: this.filter_turbo(Recap::turbo_filter::blue); break;
            case recap_filter::turbo_red: this.filter_turbo(Recap::turbo_filter::red); break;
            case recap_filter::turbo_black: this.filter_turbo(Recap::turbo_filter::black); break;
#endif
            default: this.filter_all(true); break;
        }
        this.dirty = true;

        count_totals();
    }
    private void filter_all(bool uploaded) {
        for (uint i = 0; i < elements.Length; i++) {
            RecapElement@ element = elements[i];
            if (uploaded || element.name != element.map_id)
                filtered_elements.InsertLast(element);
        }
    }
#if TMNEXT
    private void filter_campaign(Recap::campaign_filter campaign_filter) {
        if (campaigns.Length == 0 || current_campaign.Length == 0) {
            print("Fetching campaign data");
            while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();
            string url = NadeoServices::BaseURL() + "/api/token/campaign/official?length=20&offset=0&royal=false";
            auto req = NadeoServices::Get("NadeoLiveServices",url);
            req.Start();
            while (!req.Finished()) yield();
            Json::Value@ maps = Json::Parse(req.String());
            uint total_campaigns = maps['campaignList'].Length;
            for (uint campaign = 0; campaign < total_campaigns; campaign++) {
                for (uint j = 0; j < maps['campaignList'][campaign]['playlist'].Length; j++) {
                    if (campaign == 0) 
                        current_campaign.InsertLast(maps['campaignList'][campaign]['playlist'][j]['mapUid']);
                    campaigns.InsertLast(maps['campaignList'][campaign]['playlist'][j]['mapUid']);
                }
            }
        }
        
        for (uint i = 0; i < elements.Length; i++) {
            RecapElement@ element = elements[i];
            if (campaign_filter == Recap::campaign_filter::all) {
                for (uint j = 0; j < campaigns.Length; j++) {
                    if (campaigns[j] == element.map_id) {
                        filtered_elements.InsertLast(element);
                        continue;
                    }
                }

            } else {
                for (uint j = 0; j < current_campaign.Length; j++) {
                    if (current_campaign[j] == element.map_id) {
                        filtered_elements.InsertLast(element);
                        continue;
                    }
                }
            
            }
        }
    }
    private void filter_totd() {
        if (totds.Length == 0) {
            print("Fetching totd data");
            while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) yield();
            string url = NadeoServices::BaseURL() + "/api/token/campaign/month?length=100&offset=0";
            auto req = NadeoServices::Get("NadeoLiveServices",url);
            req.Start();
            while (!req.Finished()) yield();
        
            Json::Value@ maps = Json::Parse(req.String());
            for (uint month = 0; month < maps['monthList'].Length; month++) {
                for (uint j = 0; j < maps['monthList'][month]['days'].Length; j++) {
                    totds.InsertLast(maps['monthList'][month]['days'][j]['mapUid']);
                }
                yield();
            }
        }
        
        for (uint i = 0; i < elements.Length; i++) {
            RecapElement@ element = elements[i];
            for (uint j = 0; j < totds.Length; j++) {
                if (totds[j] == element.map_id) {
                    filtered_elements.InsertLast(element);
                    continue;
                }
            }
        }
    }
#endif
    private void filter_turbo(Recap::turbo_filter filter) {
        for(uint i = 0; i < elements.Length; i++) {
            RecapElement@ element = elements[i];
            if(uint(Math::Floor((Text::ParseUInt64(element.stripped_name) - 1) / 40)) == uint(filter)) {
                filtered_elements.InsertLast(element);
            }
        }
    }
}