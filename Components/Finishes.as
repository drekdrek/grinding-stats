//Finishes.as
class Finishes {

    private bool running = true;
    private bool handled = false;
    uint session_finishes = 0;
    uint total_finishes = 0;

    Finishes() {}

    Finishes(uint total) {
        total_finishes = total;
    }
    ~Finishes() {
        running = false;
    }
    void destroy() {
        running = false;
    }
    void start() {
        running = true;
        startnew(CoroutineFunc(finish_handler));
    }
    private void set_session_finishes(uint f) {session_finishes = f;}
    private void set_total_finishes(uint f) {total_finishes = f;}
    private void set_running(bool g) {running = g;}
    private void set_handled(bool h) {handled = h;}


    uint get_session_finishes(){return session_finishes;}
    uint get_total_finishes()  {return total_finishes;}
    private bool get_running() {return running;}
    private bool get_handled() {return handled;}    


    void finish_handler() {
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
                        session_finishes += 1;
                        total_finishes += 1;
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
                        session_finishes += 1;
                        total_finishes += 1;
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
                        session_finishes += 1;
                        total_finishes += 1;
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