//Timer.as
class Timer {

    private uint64 start_time = Time::Now;
    private uint64 current_time = Time::Now;
    uint64 session_time = 0;
    private uint64 session_offset = 0;
    uint64 total_time = 0;
    private uint64 total_offset = 0;
    private bool running = false;
    bool same = false;


    Timer() {}

    Timer(uint64 offset) {
        session_offset = 0;
        total_offset = offset;
        same = session_offset == total_offset;
    }

    ~Timer() {
        destroy();
    }
    void destroy() {
        running = false;
    }

    void start_timer() {
        while(running) {
            current_time = Time::Now;
            session_time = (current_time + session_offset) - start_time;
            total_time = (current_time + total_offset) - start_time;
            yield();
        }
    }

    void start() {
        start_time = Time::Now;
        running = true;
        startnew(CoroutineFunc(start_timer));
    }

    void stop() {
        session_offset = session_time;
        total_offset = total_time;
        running = false;
    }

    bool get_same() {
        return same;
    }
    private void set_same(bool b) {
        same = b;
    }
    uint64 get_session_time() {
        return session_time;
    }
    private void set_session_time(uint64 time) {
        session_time = time;
    }
    uint64 get_total_time() {
        if (total_time == 0) {
            total_time = (current_time + total_offset) - start_time;
        }
        return total_time;
    }
    private void set_total_time(uint64 time) {
        total_time = time;
    }

}

namespace Timer {
    string to_string(uint64 time) {
        if (time == 0) return "--:--:--." + (setting_show_thousands ? "---":"--");
        string str = Time::Format(time,true,true,setting_show_hour_if_0,false);
        return setting_show_thousands ? str: str.SubStr(0, str.Length - 1);
    }
}
void timer_handler() {
    bool handled = true;
    timing = true;
    while (timing) {
        if (!running && !handled) {
            handled = true;
            time.stop();
        } else if (running && handled) {
            handled = false;
            time.start();
        }
        yield();
    }
}


//mainly here for use in Debug.as//
bool timer_idle = false;
bool timer_paused = false;
bool timer_playing = false;
bool timer_multiplayer = false;
bool timer_countdown = false;
bool timer_spectating = false;
bool timer_focused = false;
float timer_start_idle = 0;
uint64 timer_countdown_number = 0;
#if TURBO
int64 timer_gametime_turbo = 0;
#endif
bool is_timer_running() {

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
#elif MP4.
        timer_paused = app.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed;
        auto gui_player = cast<CTrackManiaPlayer>(terminal.GUIPlayer);
        if (gui_player is null) return false;
        auto script_player = gui_player.ScriptAPI;
        timer_focused = app.InputPort.IsFocused;
#elif TURBO
        if (timer_gametime_turbo != playground.Interface.ManialinkScriptHandler.GameTime) {
            timer_gametime_turbo = playground.Interface.ManialinkScriptHandler.GameTime;

            timer_paused = false;
        } else {
            timer_paused = true;
        }
        auto gui_player = cast<CTrackManiaPlayer>(terminal.ControlledPlayer);
        if (gui_player is null) return false;
        auto script_player = gui_player;
        timer_focused = true; // i could not find a place where i could check if the game is focused. D: -- if you do pls let me know :)
#endif
        if (gui_player !is null) {
            timer_playing = true;
            if (script_player.Speed < int(setting_idle_speed) && script_player.Speed > -1 * int(setting_idle_speed)) {
                if (timer_start_idle == 0) {
                    timer_start_idle = Time::Now/10;
                } else if (Time::Now/10 - timer_start_idle > 100 * int(setting_idle_time)) {
                    timer_idle = true;
                }
            } else {
                timer_idle = false;
                timer_start_idle = 0;
            }
        } else {
            timer_playing = false;
            timer_idle = false;
            timer_start_idle = 0;
        }
    }
    return (!timer_idle && timer_playing && !timer_paused && !timer_countdown && !timer_spectating && timer_focused);
}