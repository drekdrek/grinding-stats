//Resets.as
class Resets {

    private bool running;
    private bool handled = false;
    private uint session_resets = 0;
    private uint total_resets = 0;

    Resets() {}

    Resets(uint total) {
        total_resets = total;
    }
    ~Resets() {
        running = false;
    }
    void destroy() {
        running = false;
    }
    void start() {
        running = true;
        startnew(CoroutineFunc(this.reset_handler));
    }

    private void set_session_resets(uint r) {session_resets = r;}
    private void set_total_resets(uint r) {total_resets = r;}
    private void set_running(bool g) {running = g;}
    private void set_handled(bool h) {handled = h;}


    uint get_session_resets(){return session_resets;}
    uint get_total_resets()  {return total_resets;}
    private bool get_running() {return running;}
    private bool get_handled() {return handled;}

    string to_string() {
        string s = "";
        if (setting_show_resets_session && 
        !(session_resets == total_resets && !setting_show_duplicates)) {
            s += "\\$bbb" + session_resets;
        }
        if (setting_show_resets_session && setting_show_resets_total &&
         !(session_resets == total_resets && !setting_show_duplicates)) {
            s += "\\$fff  /  ";
        }
        if (setting_show_resets_total) {
            s += "\\$bbb" + total_resets;
        }
        return s;
    }

    void reset_handler() {
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
                        session_resets += 1;
                        total_resets += 1;
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
                        session_resets += 1;
                        total_resets += 1;
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
                        session_resets += 1;
                        total_resets += 1;
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