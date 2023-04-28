//Finishes.as
class Finishes : Component{

    Finishes() {}

    Finishes(uint64 total) {
        super(total);
    }

    string toString() override {
        string s = "";
        if (setting_show_finishes_session && 
        !(session == total && !setting_show_duplicates)) {
            s += COLOR_GRAY + session;
        }
        if (setting_show_finishes_session && setting_show_finishes_total &&
         !(session == total && !setting_show_duplicates)) {
            s += COLOR_WHITE + '  /  ';
        }
        if (setting_show_finishes_total) {
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
                auto ui_sequence = terminal.UISequence_Current;
                if (gui_player !is null) {
                    if (!handled && ui_sequence == CGamePlaygroundUIConfig::EUISequence::Finish) {
                        handled = true;
                        session += 1;
                        total += 1;
                    } 
                    if (handled && ui_sequence != CGamePlaygroundUIConfig::EUISequence::Finish)
                        handled = false;
                }
#elif MP4
                auto gui_player = cast<CTrackManiaPlayer>(terminal.GUIPlayer);
                if (gui_player !is null) {
                    auto race_state = gui_player.ScriptAPI.RaceState;
                    if (!handled && race_state == CTrackManiaPlayer::ERaceState::Finished) {
                        handled = true;
                        session += 1;
                        total += 1;
                    }
                    if (handled && race_state != CTrackManiaPlayer::ERaceState::Finished) 
                        handled = false;
                }
#elif TURBO
                auto gui_player = cast<CTrackManiaPlayer>(terminal.ControlledPlayer);
                if (gui_player !is null) {
                    auto race_state = gui_player.RaceState;
                    if (!handled && race_state == CTrackManiaPlayer::ERaceState::Finished && !network.PlaygroundClientScriptAPI.IsSpectator) {
                        handled = true;
                        session += 1;
                        total += 1;
                    }
                    if (handled && race_state != CTrackManiaPlayer::ERaceState::Finished)
                        handled = false;
                }
#endif
            }
            yield();
            
        }
    }
}