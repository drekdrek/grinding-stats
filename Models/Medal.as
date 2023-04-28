class Medal {
    private bool _is_locked = false;
    uint64 time_to_acq = 0;

    Medal() {}

    Medal(uint64 _time_to_acq) {
        time_to_acq = _time_to_acq;
    }

    string toString() {
        if (_is_locked) {
            return COLOR_GRAY + '+';
        }
        return COLOR_GRAY + Medal::to_string(time_to_acq);
    }

    void lock() {
        _is_locked = true;
    }

    bool is_locked() {
        return _is_locked;
    }
}

namespace Medal {
    string to_string(uint64 time) {
        if (time == 0) return '-';
        return Time::Format(time, false, true, setting_show_hour_if_0, false);
    }
}
