//Respawns.as (currently only working for TMNEXT) //will be finished later, slightly broken
class Respawns {
    private bool running = true;
    uint current_respawns = 0;
    uint session_respawns = 0;
    uint total_respawns = 0;

    Respawns() {}

    Respawns(uint total) {
        total_respawns = total;
    }
    ~Respawns() {
        running = false;
    }
    void destroy() {
        running = false; 
    }
    void start() {
        running = true;
        startnew(CoroutineFunc(respawn_handler));
    }
    
    uint get_total_respawns() {return total_respawns;}
    private void set_total_respawns(uint t) {total_respawns = t;}
    uint get_current_respawns() {return current_respawns;}
    private void set_current_respawns(uint c) {current_respawns = c;}
    uint get_session_respawns() {return session_respawns;}
    private void set_session_respawns(uint s) {session_respawns = s;}

    void respawn_handler() {
#if TMNEXT
        while(running) {
            auto app = GetApp();
            auto playground = app.CurrentPlayground;
            if (playground !is null && playground.GameTerminals.Length > 0) {
                auto terminal = playground.GameTerminals[0];
                auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
                if (gui_player !is null) {
                    auto script = cast<CSmScriptPlayer>(gui_player.ScriptAPI);
                    auto post = script.Post;

                    if (script.Score.NbRespawnsRequested > current_respawns && post != CSmScriptPlayer::EPost::Char) {
                        current_respawns += 1;
                        session_respawns += 1;
                        total_respawns += 1;   
                    }
                    if (script.Score.NbRespawnsRequested == 0) {
                        current_respawns = 0;
                    }
                }
            }
            yield();
        }
#endif
    }
}
