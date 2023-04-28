class NullableUint64 {
    private bool _has_value = false;
    private uint64 _value;

    NullableUint64() {}

    NullableUint64(uint64 value) {
        _value = value;
        _has_value = true;
    }

    bool has_value {
        get const {
            return _has_value;
        }
    }

    uint64 value {
        get const {
            if (!_has_value) {
                throw("Nullable uint64 has no value");
            }
            return _value;
        }
    }

    uint64 value_or_default {
        get const {
            return _has_value ? _value : 0;
        }
    }
}
