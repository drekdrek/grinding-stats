enum MedalTimeType {
    KeyNotExists,
    MedalAchievementTimeUnknown,
    Unachieved,
    Achieved
}

class FileMedalTime {

    private BoolRef@ _is_unknown = BoolRef();
    private NullableUint64@ _time = NullableUint64();

    FileMedalTime() {}

    uint64 time {
        get const {
            return _time.value_or_default;
        }
    }

    int64 sort_val {
        get const {
            if (medal_time_type == MedalTimeType::KeyNotExists)
                return -3;
            if (medal_time_type == MedalTimeType::Unachieved)
                return -2;
            if (medal_time_type == MedalTimeType::MedalAchievementTimeUnknown)
                return -1;
            return int64(this.time);
        }
    }

    MedalTimeType medal_time_type {
        get const {
            if (_is_unknown.value) {
                return MedalTimeType::MedalAchievementTimeUnknown;
            }
            if (!_time.has_value) {
                return MedalTimeType::KeyNotExists;
            }
            if (_time.value == 0) {
                return MedalTimeType::Unachieved;
            }
            return MedalTimeType::Achieved;
        }
    }

    void set_time_from_medal(Medal medal) {
        if (medal.is_locked()) {
            _is_unknown.value = true;
            return;
        }
        _time = medal.time_to_acq;
    }

    void decode_time(const string &in json_value) {
        if (json_value == '')
            return;

        if (json_value == 'unknown') {
            _is_unknown.value = true;
            return;
        }
        _time = NullableUint64(Text::ParseUInt64(json_value));
    }

    string encode_time() {
        if (_is_unknown.value) {
            return 'unknown';
        }
        return Text::Format("%11d", this.time);
    }
    
    string to_string() {
        if (medal_time_type == MedalTimeType::KeyNotExists)
            return '';
        if (medal_time_type == MedalTimeType::Unachieved)
            return COLOR_ORANGE + '-';

        return COLOR_GREEN + (
            medal_time_type == MedalTimeType::MedalAchievementTimeUnknown
            ? '+'
            : Medal::to_string(_time.value)
        );
    }
}
