//Resets.as
class Resets : Component {

    Resets() {}

    Resets(uint64 total) {
        super(total);
    }

    string toString() override {
        string s = "";
        if (setting_show_resets_session && 
        !(session == total && !setting_show_duplicates)) {
            s += COLOR_GRAY + session;
        }
        if (setting_show_resets_session && setting_show_resets_total &&
         !(session == total && !setting_show_duplicates)) {
            s += COLOR_WHITE + '  /  ';
        }
        if (setting_show_resets_total) {
            s += COLOR_GRAY + total;
        }
        return s;
    }

    void handler() override {
        while(running){
            auto app = GetApp();
            auto playground = app.CurrentPlayground;
            auto network = cast<CTrackManiaNetwork>(app.Network);
            if (playground !is null && playground.GameTerminals.Length > 0) {
                auto terminal = playground.GameTerminals[0];
#if TMNEXT
                auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
                if (gui_player !is null) {
                    auto post = (cast<CSmScriptPlayer>(gui_player.ScriptAPI)).Post;
                    if (!handled && post == CSmScriptPlayer::EPost::Char) {
                        handled = true;
                        session += 1;
                        total += 1;
                    }
                    if (handled && post != CSmScriptPlayer::EPost::Char)
                        handled = false;
                    }
#elif MP4
                auto gui_player = cast<CTrackManiaPlayer>(terminal.GUIPlayer);
                if (gui_player !is null) {
                    auto race_state = gui_player.ScriptAPI.RaceState;
                    if (!handled && race_state == CTrackManiaPlayer::ERaceState::BeforeStart) {
                        handled = true;
                        session += 1;
                        total += 1;
                    }
                    if (handled && race_state != CTrackManiaPlayer::ERaceState::BeforeStart)
                        handled = false;
                }
#elif TURBO
                auto gui_player = cast<CTrackManiaPlayer>(terminal.ControlledPlayer);
                if (gui_player !is null) {
                    auto ui_sequence = (cast<CGamePlaygroundUIConfig>(network.PlaygroundClientScriptAPI.UI)).UISequence;
                    auto race_state = gui_player.RaceState;
                    if (!handled && race_state == CTrackManiaPlayer::ERaceState::BeforeStart && ui_sequence == CGamePlaygroundUIConfig::EUISequence::Playing) {
                        handled = true;
                        session += 1;
                        total += 1;
                    }
                    if (handled && race_state != CTrackManiaPlayer::ERaceState::BeforeStart && (race_state != CTrackManiaPlayer::ERaceState::Finished && !network.PlaygroundClientScriptAPI.IsSpectator))
                        handled = false;
                }
#endif
            }
            yield();
        }
    }
}