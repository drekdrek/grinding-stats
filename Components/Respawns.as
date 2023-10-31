//Respawns.as (currently only working for TMNEXT)
class Respawns : Component {
    uint current;

    Respawns() {}

    Respawns(uint total) {
        super(total);
        current = 0;
    }

    string toString() override {
        string s = "";
        if (setting_show_respawns_current) {
            s += "\\$bbb" + current;
        }
		if (setting_show_respawns_current && setting_show_respawns_session &&
		!(!setting_show_duplicates && session == current)) {
			s += "\\$fff  /  ";
		}
        if (setting_show_respawns_session && !(!setting_show_duplicates &&
		session == current && setting_show_respawns_current)) {
            s += "\\$bbb" + session;
        }
		if ((setting_show_respawns_current || setting_show_respawns_session) &&
		setting_show_respawns_total && !(!setting_show_duplicates &&
		(total == session && setting_show_respawns_session))) {
			s += "\\$fff  /  ";
		}
		if (setting_show_respawns_total && !(!setting_show_duplicates &&
		total == session && setting_show_respawns_session)) {
			s += "\\$bbb" + total;
		}
		return s;
}

    void handler() override {
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

                    if (script.Score.NbRespawnsRequested > current && post != CSmScriptPlayer::EPost::Char) {
                        current += 1;
                        session += 1;
                        total += 1;   
                    }
                    if (script.Score.NbRespawnsRequested == 0) {
                        current = 0;
                    }
                }
            }
            yield();
        }
#endif
    }
}
