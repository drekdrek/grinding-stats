//Timer.as
class Timer : Component {

    private uint64 start_time = Time::Now;
    private uint64 current_time = Time::Now;
    private uint64 session_offset = 0;
    private uint64 total_offset = 0;
    bool same = false;
    bool timing = false;
    uint64 timer_start_idle = 0;
    uint64 timer_countdown_number = 0;
#if TURBO
    int64 timer_gametime_turbo = 0;
#endif


    Timer() {}

    Timer(uint64 _total_offset) {
        session_offset = 0;
        total_offset = _total_offset;   
        same = session_offset == total_offset;
        total = _total_offset;
    }


    bool isRunning() {
        bool timer_idle = false;
        bool timer_paused = false;
        bool timer_playing = false;
        bool timer_multiplayer = false;
        bool timer_countdown = false;
        bool timer_spectating = false;
        bool timer_focused = false;
        auto app = GetApp();
#if TMNEXT||MP4
        auto rootmap = app.RootMap;
#elif TURBO
        auto rootmap = app.Challenge;
#endif
        auto playground = app.CurrentPlayground;
        if (rootmap !is null && playground !is null && playground.GameTerminals.Length > 0) {
            timer_multiplayer = app.PlaygroundScript is null;
            auto terminal = playground.GameTerminals[0];
#if TMNEXT
            timer_paused = app.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed && !timer_multiplayer;
            auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
            if (gui_player is null) return false;
            auto script_player = cast<CSmScriptPlayer>(gui_player.ScriptAPI);
            timer_countdown = app.Network.PlaygroundClientScriptAPI.GameTime - script_player.StartTime < 0;
            timer_countdown_number = app.Network.PlaygroundClientScriptAPI.GameTime - script_player.StartTime;
            timer_spectating = app.Network.PlaygroundClientScriptAPI.IsSpectator;
            timer_focused = app.InputPort.IsFocused;
#elif MP4
            timer_paused = app.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed;
            auto gui_player = cast<CTrackManiaPlayer>(terminal.GUIPlayer);
            if (gui_player is null) return false;
            auto script_player = gui_player.ScriptAPI;
            timer_focused = app.InputPort.IsFocused;
#elif TURBO
            timer_paused = playground.Interface.InterfaceRoot.IsFocused;
            auto gui_player = cast<CTrackManiaPlayer>(terminal.ControlledPlayer);
            if (gui_player is null) return false;
            auto script_player = gui_player;
            timer_focused = true; // i could not find a place where i could check if the game is focused. D: -- if you do pls let me know :)
#endif
            if (gui_player !is null) {
                timer_playing = true;            
                if (Math::Abs(script_player.Speed) < int(setting_idle_speed)) {
                    if (timer_start_idle == 0) timer_start_idle = Time::Now;
                    if ((Time::Now - timer_start_idle) > (1000 * setting_idle_time)) {
                        timer_idle = true;
                    }
                } else {
                    timer_start_idle = 0;
                    timer_idle = false;
                }
            } else {
                timer_playing = false;
                timer_idle = false;
                timer_start_idle = 0;
            }
        }
        return (!timer_idle && timer_playing && !timer_paused && !timer_countdown && !timer_spectating && timer_focused);
    }


    void count_time() {
        while(running) {
            current_time = Time::Now;
            session = (current_time + session_offset) - start_time;
            total = (current_time + total_offset) - start_time;
            yield();
        }
    }

    void stop() {
        session_offset = session;
        total_offset = total;
        running = false;
    }

    void handler() override {
        bool handled = true;
        timing = true;
        while(timing) {
            if (!isRunning() && !handled) {
                handled = true;
                stop();
            } else if (isRunning() && handled) {
                handled = false;
                start_time = Time::Now;
                running = true;
                startnew(CoroutineFunc(count_time));
            }
            yield();
        }
    }   
}

namespace Timer {
    string to_string(uint64 time) {
        if (time == 0) return "--:--:--." + (setting_show_thousands ? "---":"--");
        string str = Time::Format(time, setting_show_fractions_of_second, true, setting_show_hour_if_0, false);
        return (!setting_show_fractions_of_second || setting_show_thousands) ? str : str.SubStr(0, str.Length - 1);
    }
}
