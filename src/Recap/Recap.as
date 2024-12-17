namespace Recap {
enum campaign_filter {
	current,
	previous,
	all
} enum turbo_filter {
	white,
	green,
	blue,
	red,
	black,
	canyon,
	valley,
	lagoon,
	stadium
}

string time_to_string(uint64 time) {
	if (time == 0)
		return "--:--:--." + (setting_show_thousands ? "---" : "--");
	string str = "\\$bbb" + Time::Format(time, true, true, setting_show_hour_if_0, false);
	return setting_show_thousands ? str : str.SubStr(0, str.Length - 1);
}

string time_to_string(uint64 time, bool thousands) {
	if (time == 0)
		return "--:--:--." + (thousands ? "---" : "--");
	string str = "\\$bbb" + Time::Format(time, true, true, setting_show_hour_if_0, false);
	return thousands ? str : str.SubStr(0, str.Length - 1);
}
} // namespace Recap

class Recap {
	array<string> totds;
	array<string> campaigns;
	array<string> previous_campaign;
	array<string> current_campaign;
	array<string> custom;
	array<RecapElement @> elements;
	array<RecapElement @> filtered_elements;
	bool dirty;
	bool started = false;
	uint64 total_time = 0;
	uint total_finishes = 0;
	uint total_resets = 0;
	uint total_respawns = 0;
	array<string> log;

  private void count_total_time() {
		total_time = 0;
		for (uint i = 0; i < filtered_elements.Length; i++) {
			total_time += filtered_elements[i].time_uint;
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

	Recap() {
		elements = array<RecapElement @>();
		dirty = false;
	}

	void SortItems(UI::TableSortSpecs @sortSpecs) {
		startnew(CoroutineFuncUserdata(sort_items), sortSpecs);
		sortSpecs.Dirty = false;
		dirty = false;
	}

  private void sort_items(ref @s) {
		if (filtered_elements.Length < 2)
			return;

		auto specs = (cast<UI::TableSortSpecs @>(s)).Specs;
		for (uint i = 0; i < specs.Length; i++) {
			auto spec = specs[i];
			if (spec.SortDirection == UI::SortDirection::None)
				continue;

			if (spec.SortDirection == UI::SortDirection::Ascending) {
				switch (spec.ColumnIndex) {
				case 0:
					filtered_elements.Sort(function(a, b) { return a.stripped_name < b.stripped_name; });
					break;
				case 1:
					filtered_elements.Sort(function(a, b) { return a.time_uint < b.time_uint; });
					break;
				case 2:
					filtered_elements.Sort(function(a, b) { return a.finishes < b.finishes; });
					break;
				case 3:
					filtered_elements.Sort(function(a, b) { return a.resets < b.resets; });
					break;
				case 4:
					filtered_elements.Sort(function(a, b) { return a.respawns < b.respawns; });
					break;
				case 5:
					filtered_elements.Sort(function(a, b) { return a.modified_time < b.modified_time; });
					break;
				}
			} else if (spec.SortDirection == UI::SortDirection::Descending) {
				switch (spec.ColumnIndex) {
				case 0:
					filtered_elements.Sort(function(a, b) { return a.stripped_name > b.stripped_name; });
					break;
				case 1:
					filtered_elements.Sort(function(a, b) { return a.time_uint > b.time_uint; });
					break;
				case 2:
					filtered_elements.Sort(function(a, b) { return a.finishes > b.finishes; });
					break;
				case 3:
					filtered_elements.Sort(function(a, b) { return a.resets > b.resets; });
					break;
				case 4:
					filtered_elements.Sort(function(a, b) { return a.respawns > b.respawns; });
					break;
				case 5:
					filtered_elements.Sort(function(a, b) { return a.modified_time > b.modified_time; });
					break;
				}
			}
			yield();
		}
	}

	void start() { startnew(CoroutineFunc(load_files)); }

	void refresh() {
		elements = array<RecapElement @>();
		campaigns = array<string>();
		current_campaign = array<string>();
		previous_campaign = array<string>();
		totds = array<string>();
		custom = array<string>();
		await(startnew(CoroutineFunc(load_files)));
		count_total_finishes();
		count_total_resets();
		count_total_respawns();
		count_total_time();
		filter_elements();
	}

  private void load_files() {
		auto files = IO::IndexFolder(IO::FromStorageFolder("data"), true);
		if (elements.Length != files.Length) {
			elements = array<RecapElement @>();
		} else {
			return;
		}
		uint path_length = (IO::FromStorageFolder("data")).Length;
		uint batches = uint(Math::Ceil(files.Length / 50.0));
		for (uint i = 0; i < batches; i++) {
			uint amt = Math::Min(50, Math::Max(0, files.Length - (i * 50)));
			for (uint j = 0; j < amt; j++) {
				string[] @matches = Regex::Search(files[i * 50 + j], "\\/data\\/(.+)\\.json");
				string map_id = matches[1];
				elements.InsertLast(RecapElement(map_id));
				log.InsertLast("Loaded " + map_id);
				if (log.Length > 5) {
					log.RemoveAt(0);
				}
			}
			sleep(100);
		}
		dirty = true;
		count_total_finishes();
		count_total_resets();
		count_total_respawns();
		count_total_time();
		recap.filter_elements();
	}

	void filter_elements() {
		filtered_elements = array<RecapElement @>();
		switch (current_recap) {
		case recap_filter::all:
			this.filter_all(true);
			break;
		case recap_filter::custom:
			this.filter_custom();
			break;
#if TMNEXT || MP4
		case recap_filter::all_with_name:
			this.filter_all(false);
			break;
#endif
#if TMNEXT
		case recap_filter::current_campaign:
			this.filter_campaign(Recap::campaign_filter::current);
			break;
		case recap_filter::all_nadeo_campaigns:
			this.filter_campaign(Recap::campaign_filter::all);
			break;
		case recap_filter::previous_campaign:
			this.filter_campaign(Recap::campaign_filter::previous);
			break;
		case recap_filter::totd:
			this.filter_totd();
			break;
#elif MP4
		case recap_filter::canyon:
			this.filter_titlePack("Canyon");
			break;
		case recap_filter::stadium:
			this.filter_titlePack("TMStadium");
			break;
		case recap_filter::valley:
			this.filter_titlePack("TMValley");
			break;
		case recap_filter::lagoon:
			this.filter_titlePack("TMLagoon");
			break;
#elif TURBO
		case recap_filter::turbo_white:
			this.filter_turbo(Recap::turbo_filter::white);
			break;
		case recap_filter::turbo_green:
			this.filter_turbo(Recap::turbo_filter::green);
			break;
		case recap_filter::turbo_blue:
			this.filter_turbo(Recap::turbo_filter::blue);
			break;
		case recap_filter::turbo_red:
			this.filter_turbo(Recap::turbo_filter::red);
			break;
		case recap_filter::turbo_black:
			this.filter_turbo(Recap::turbo_filter::black);
			break;
		case recap_filter::canyon:
			this.filter_titlePack(Recap::turbo_filter::canyon);
			break;
		case recap_filter::stadium:
			this.filter_titlePack(Recap::turbo_filter::stadium);
			break;
		case recap_filter::valley:
			this.filter_titlePack(Recap::turbo_filter::valley);
			break;
		case recap_filter::lagoon:
			this.filter_titlePack(Recap::turbo_filter::lagoon);
			break;
#endif
		default:
			this.filter_all(true);
			break;
		}
		this.dirty = true;

#if MP4
		startnew(CoroutineFunc(get_all_tm2_names_from_api));
#endif

		count_total_finishes();
		count_total_resets();
		count_total_respawns();
		count_total_time();
	}

  private void filter_all(bool uploaded) {
		for (uint i = 0; i < elements.Length; i++) {
			RecapElement @element = elements[i];
			if (uploaded || element.name != element.map_id)
				filtered_elements.InsertLast(element);
		}
	}

#if TMNEXT
  private void filter_campaign(Recap::campaign_filter campaign_filter) {
		if (campaigns.Length == 0 || current_campaign.Length == 0) {
			print("Fetching campaign data");
			while (!NadeoServices::IsAuthenticated("NadeoLiveServices"))
				yield();
			string url = NadeoServices::BaseURLLive() + "/api/token/campaign/official?length=20&offset=0&royal=false";
			auto req = NadeoServices::Get("NadeoLiveServices", url);
			req.Start();
			while (!req.Finished())
				yield();
			Json::Value @maps = Json::Parse(req.String());
			uint total_campaigns = maps['campaignList'].Length;
			for (uint campaign = 0; campaign < total_campaigns; campaign++) {
				for (uint j = 0; j < maps['campaignList'][campaign]['playlist'].Length; j++) {
					if (campaign == 0)
						current_campaign.InsertLast(maps['campaignList'][campaign]['playlist'][j]['mapUid']);
					if (campaign == 1)
						previous_campaign.InsertLast(maps['campaignList'][campaign]['playlist'][j]['mapUid']);
					campaigns.InsertLast(maps['campaignList'][campaign]['playlist'][j]['mapUid']);
				}
			}
		}

		for (uint i = 0; i < elements.Length; i++) {
			RecapElement @element = elements[i];
			if (campaign_filter == Recap::campaign_filter::all) {
				for (uint j = 0; j < campaigns.Length; j++) {
					if (campaigns[j] == element.map_id) {
						filtered_elements.InsertLast(element);
						continue;
					}
				}
			} else if (campaign_filter == Recap::campaign_filter::current) {
				for (uint j = 0; j < current_campaign.Length; j++) {
					if (current_campaign[j] == element.map_id) {
						filtered_elements.InsertLast(element);
						continue;
					}
				}
			} else if (campaign_filter == Recap::campaign_filter::previous) {
				for (uint j = 0; j < previous_campaign.Length; j++) {
					if (previous_campaign[j] == element.map_id) {
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
			while (!NadeoServices::IsAuthenticated("NadeoLiveServices"))
				yield();
			string url = NadeoServices::BaseURLLive() + "/api/token/campaign/month?length=100&offset=0";
			auto req = NadeoServices::Get("NadeoLiveServices", url);
			req.Start();
			while (!req.Finished())
				yield();

			Json::Value @maps = Json::Parse(req.String());
			for (uint month = 0; month < maps['monthList'].Length; month++) {
				for (uint j = 0; j < maps['monthList'][month]['days'].Length; j++) {
					totds.InsertLast(maps['monthList'][month]['days'][j]['mapUid']);
				}
				yield();
			}
		}

		for (uint i = 0; i < elements.Length; i++) {
			RecapElement @element = elements[i];
			for (uint j = 0; j < totds.Length; j++) {
				if (totds[j] == element.map_id) {
					filtered_elements.InsertLast(element);
					continue;
				}
			}
		}
	}
#elif MP4
  private void filter_titlePack(const string &in titlepack) {
		for (uint i = 0; i < elements.Length; i++) {
			RecapElement @element = elements[i];
			if (element.titlepack == titlepack) {
				filtered_elements.InsertLast(element);
			}
		}
	}

  private void get_all_tm2_names_from_api() {
		uint req_uid_limit = 8;

		for (uint cur_uid = 0; cur_uid < elements.Length; cur_uid += req_uid_limit) {
			string[] map_uids = array<string>();

			for (uint i = cur_uid; i < cur_uid + req_uid_limit && i < elements.Length; i++) {
				map_uids.InsertLast(elements[i].map_id);
			}

			auto req = Net::HttpRequest();
			req.Method = Net::HttpMethod::Get;
			req.Url = 'https://tm.mania.exchange/api/maps/get_map_info/multi/' + string::Join(map_uids, ",");
			req.Start();
			while (!req.Finished())
				yield();

			string resp_str = req.String();

			if (req.ResponseCode() == 200 && resp_str != "") {
				Json::Value @maps = Json::Parse(resp_str);

				for (uint m = 0; m < maps.Length; m++) {
					Json::Value @map = maps[m];

					for (uint e = cur_uid; e < cur_uid + req_uid_limit && e < elements.Length; e++) {
						RecapElement @elem = elements[e];

						if (elem.map_id == map['TrackUID']) {
							elem.name = format_string(map['GbxMapName']);
							elem.titlepack = map['TitlePack'];

							elem.stripped_name = Text::StripFormatCodes(elem.name).Replace('\\','');
							for (int j = 0; j < elem.stripped_name.Length; j++) {
								if (elem.stripped_name.StartsWith(" "))
									elem.stripped_name = elem.stripped_name.SubStr(2);
								else
									break;
							}

							break;
						}
					}
				}
			}
		}
	}
#elif TURBO
  private void filter_titlePack(Recap::turbo_filter filter) {
		for (uint i = 0; i < elements.Length; i++) {
			RecapElement @element = elements[i];
			int num = Text::ParseInt(element.stripped_name);
			int numMod40 = num % 40;
			switch (filter) {
			case Recap::turbo_filter::canyon:
				if (numMod40 >= 1 && numMod40 <= 10) {
					filtered_elements.InsertLast(element);
				}
				break;
			case Recap::turbo_filter::stadium:
				if (numMod40 >= 11 && numMod40 <= 20) {
					filtered_elements.InsertLast(element);
				}
				break;
			case Recap::turbo_filter::valley:
				if (numMod40 >= 21 && numMod40 <= 30) {
					filtered_elements.InsertLast(element);
				}
				break;
			case Recap::turbo_filter::lagoon:
				if (numMod40 >= 31 && numMod40 <= 40 || numMod40 == 0) {
					filtered_elements.InsertLast(element);
				}
				break;
			default:
				break;
			}
		}
	}

  private void filter_turbo(Recap::turbo_filter filter) {
		for (uint i = 0; i < elements.Length; i++) {
			RecapElement @element = elements[i];
			if (uint(Math::Floor((Text::ParseUInt64(element.stripped_name) - 1) / 40)) == uint(filter)) {
				filtered_elements.InsertLast(element);
			}
		}
	}
#endif
  private void filter_custom() {
		if (custom.Length == 0) {
			string[] custom_maps = setting_custom_recap.Split("\n");
			for (uint i = 0; i < custom_maps.Length; i++) {
				custom.InsertLast(custom_maps[i]);
			}
		}

		for (uint i = 0; i < elements.Length; i++) {
			RecapElement @element = elements[i];
			for (uint j = 0; j < custom.Length; j++) {
				if (custom[j] == element.map_id) {
					filtered_elements.InsertLast(element);
					continue;
				}
			}
		}
	}
}