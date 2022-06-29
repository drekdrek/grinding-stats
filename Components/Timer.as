//Timer.as
class Timer {

    uint64 start_time;
    uint64 current_time;
    uint64 time_dif;
    uint64 time_offset;
    bool running = false;

    Timer() {
    }

    Timer(uint64 offset) {
        time_offset = offset;
        start_time = 0;
        current_time = 0;
        time_dif = (current_time + time_offset) - start_time;
    }
    ~Timer() {
        running = false;
    }
    void destroy() {
        running = false;
    }

    void start_timer() {
        while(running) {
            current_time = Time::Now;
            time_dif = (current_time + time_offset) - start_time;
            yield();
        }
    }
    void start() {
        start_time = Time::Now;
        running = true;
        startnew(CoroutineFunc(start_timer));
    }

    void stop() {
        time_offset = time_dif;
        running = false;
    }

    uint get_time() {
        return time_dif;
    }
    uint get_offset() {
        return time_offset;
    }

    string get_time_string() {
        if (time_dif == 0) return "--:--:--";
        int h = int(Math::Floor((time_dif) / 3600000));
        int m =  int(Math::Floor((time_dif) / 60000 - h * 60));
        int s =  int(Math::Floor((time_dif) / 1000 - h * 3600 - m * 60));
        int ms = Text::ParseInt(Text::Format("%03d",(time_dif) % 1000).SubStr(0,(setting_show_thousands ? 3 : 2)));

       return "" + (h == 0 && !setting_show_hour_if_0 ? "" : Time::Internal::PadNumber(h,2) + ":") + Time::Internal::PadNumber(m,2) + ":" + Time::Internal::PadNumber(s,2) + "." + Time::Internal::PadNumber(ms,setting_show_thousands ? 3 : 2); 
    }
}

void timer_handler() {
    bool handled = true;
    timing = true;
    while (timing) {
        if (!running && !handled) {
            handled = true;
            session_time.stop();
            total_time.stop();
        } else if (running && handled) {
            handled = false;
            session_time.start();
            total_time.start();
        }
        yield();
    }
}

bool is_timer_running() {
    bool idle = false;
    bool playing = false;
    bool paused = false;
    bool multiplayer = false;
    bool countdown = false;
    auto app = GetApp();
#if TMNEXT||MP4
    auto rootmap = app.RootMap;
#elif TURBO
    auto rootmap = app.Challenge;
#endif
    auto playground = app.CurrentPlayground;
    if (rootmap !is null && playground !is null && playground.GameTerminals.Length > 0) {
        multiplayer = app.PlaygroundScript is null;
        auto terminal = playground.GameTerminals[0];
#if TMNEXT
        paused = app.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed && !multiplayer;
        auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
        if (gui_player is null) return false;
        auto script_player = cast<CSmScriptPlayer>(gui_player.ScriptAPI);
        countdown = script_player.CurrentRaceTime < 0;
#elif MP4
        paused = app.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed;
        auto gui_player = cast<CTrackManiaPlayer>(terminal.GUIPlayer);
        if (gui_player is null) return false;
        auto script_player = gui_player.ScriptAPI;
#elif TURBO
        paused = playground.Interface.ManialinkScriptHandler.IsInGameMenuDisplayed;
        auto gui_player = cast<CTrackManiaPlayer>(terminal.ControlledPlayer);
        if (gui_player is null) return false;
        auto script_player = gui_player;
#endif
        if (gui_player !is null) {
            playing = true;
            if (script_player.Speed < int(setting_idle_speed) && script_player.Speed > -1 * int(setting_idle_speed)) {
                if (start_idle == 0) {
                    start_idle = Time::Now/10;
                } else if (Time::Now/10 - start_idle > 100 * int(setting_idle_time)) {
                    idle = true;
                }
            } else {
                idle = false;
                start_idle = 0;
            }
        } else {
            playing = false;
            idle = false;
            start_idle = 0;
        }
    } 
    return (!idle && playing && !paused && !countdown);
}