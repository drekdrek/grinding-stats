class MedalTotals {
    private uint _item_count = 0;

    private uint _bronze_medal_count = 0;
    private uint _silver_medal_count = 0;
    private uint _gold_medal_count = 0;
    private uint _author_medal_count = 0;

    private uint _bronze_medal_time_unknown_count = 0;
    private uint _silver_medal_time_unknown_count = 0;
    private uint _gold_medal_time_unknown_count = 0;
    private uint _author_medal_time_unknown_count = 0;

    private uint _unread_file_count = 0;

    private uint _total_time_to_bronze = 0;
    private uint _total_time_to_silver = 0;
    private uint _total_time_to_gold = 0;
    private uint _total_time_to_author = 0;

    void count_totals(array<RecapElement@> elements) {
        _item_count = elements.Length;

        _bronze_medal_count = 0;
        _silver_medal_count = 0;
        _gold_medal_count = 0;
        _author_medal_count = 0;

        _bronze_medal_time_unknown_count = 0;
        _silver_medal_time_unknown_count = 0;
        _gold_medal_time_unknown_count = 0;
        _author_medal_time_unknown_count = 0;

        _unread_file_count = 0;

        _total_time_to_bronze = 0;
        _total_time_to_silver = 0;
        _total_time_to_gold = 0;
        _total_time_to_author = 0;
        
        for (uint i = 0; i < elements.Length; i++) {
            if (elements[i].time_to_bronze.medal_time_type == MedalTimeType::KeyNotExists) {
                _unread_file_count++;
                continue;
            }

            _total_time_to_bronze += elements[i].time_to_bronze.time;
            _total_time_to_silver += elements[i].time_to_silver.time;
            _total_time_to_gold += elements[i].time_to_gold.time;
            _total_time_to_author += elements[i].time_to_author.time;

            if (elements[i].time_to_bronze.medal_time_type == MedalTimeType::Achieved) {
                _bronze_medal_count++;
            } else if (elements[i].time_to_bronze.medal_time_type == MedalTimeType::MedalAchievementTimeUnknown) {
                _bronze_medal_time_unknown_count++;
            }
                
            if (elements[i].time_to_silver.medal_time_type == MedalTimeType::Achieved) {
                _silver_medal_count++;
            } else if (elements[i].time_to_silver.medal_time_type == MedalTimeType::MedalAchievementTimeUnknown) {
                _silver_medal_time_unknown_count++;
            }

            if (elements[i].time_to_gold.medal_time_type == MedalTimeType::Achieved) {
                _gold_medal_count++;
            } else if (elements[i].time_to_gold.medal_time_type == MedalTimeType::MedalAchievementTimeUnknown) {
                _gold_medal_time_unknown_count++;
            }

            if (elements[i].time_to_author.medal_time_type == MedalTimeType::Achieved) {
                _author_medal_count++;
            } else if (elements[i].time_to_author.medal_time_type == MedalTimeType::MedalAchievementTimeUnknown) {
                _author_medal_time_unknown_count++;
            }
        }
    }

    private string acq_percentage_str(uint medal_count) {
        if (_item_count == 0 || _unread_file_count != 0) {
            return '';
        }
        auto remaining_items = _item_count - medal_count;

        if (remaining_items == 0) {
            return COLOR_BRIGHT_GREEN + ' (100%)';
        } else {
            auto acq_perc = Math::Round((float(medal_count) / _item_count) * 100);
            return COLOR_BRIGHT_ORANGE + ' (' + medal_count + '/' + _item_count + ' - ' + acq_perc + '%)';
        }
    }

    private string totals_str(
        uint medal_count, uint unknown_medal_count, uint total_time
    ) {
        auto all_medals_acq = _item_count == (medal_count + unknown_medal_count);
        auto color_prefix = all_medals_acq ? COLOR_BRIGHT_GREEN : '';

        if (all_medals_acq && total_time == 0) {
            return color_prefix + '+';
        }
        auto unknown_prefix = (unknown_medal_count > 0 && total_time > 0) ? '> ' : '';

        return color_prefix + unknown_prefix + Medal::to_string(total_time);
    }

    string bronze_perc {
        get const {
            return acq_percentage_str(_bronze_medal_count + _bronze_medal_time_unknown_count);
        }
    }
    string silver_perc {
        get const {
            return acq_percentage_str(_silver_medal_count + _silver_medal_time_unknown_count);
        }
    }
    string gold_perc {
        get const {
            return acq_percentage_str(_gold_medal_count + _gold_medal_time_unknown_count);
        }
    }
    string author_perc {
        get const {
            return acq_percentage_str(_author_medal_count + _author_medal_time_unknown_count);
        }
    }
    
    string bronze_totals {
        get const {
            return totals_str(_bronze_medal_count, _bronze_medal_time_unknown_count, _total_time_to_bronze);
        }
    }
    string silver_totals {
        get const {
            return totals_str(_silver_medal_count, _silver_medal_time_unknown_count, _total_time_to_silver);
        }
    }
    string gold_totals {
        get const {
            return totals_str(_gold_medal_count, _gold_medal_time_unknown_count, _total_time_to_gold);
        }
    }
    string author_totals {
        get const {
            return totals_str(_author_medal_count, _author_medal_time_unknown_count, _total_time_to_author);
        }
    }

    MedalTotals() {}
}
