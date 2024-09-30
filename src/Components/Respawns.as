class Respawns : BaseComponent {
	uint current;
	uint offset;

	Respawns() {}

	Respawns(uint total) {
		super(total);
		current = 0;
	}

	~Respawns() { running = false; }

	string toString() override {
		string_constructor = array<string>();

		if (setting_show_duplicates) {

			if (setting_show_respawns_current)
				string_constructor.InsertLast("\\$bbb" + current);
			if (setting_show_respawns_session)
				string_constructor.InsertLast("\\$ddd" + session);
			if (setting_show_respawns_total)
				string_constructor.InsertLast("\\$bbb" + total);
		} else {
			if (setting_show_respawns_current)
				string_constructor.InsertLast("\\$bbb" + current);

			if (setting_show_respawns_session && session != current)
				string_constructor.InsertLast("\\$bbb" + session);

			if (setting_show_respawns_total && total != session)
				string_constructor.InsertLast("\\$bbb" + total);
		}
		if (string_constructor.Length == 3) {
			return string_constructor[0] + "\\$fff  /  " +
				   string_constructor[1] + "\\$fff  /  " +
				   string_constructor[2];
		}
		if (string_constructor.Length == 2) {
			return string_constructor[0] + "\\$fff  /  " +
				   string_constructor[1];
		}
		if (string_constructor.Length == 1) {
			return string_constructor[0];
		}
		return "";
	}
	void handler() override {
#if TMNEXT
		uint64 last_respawn_time = 0;
		while (this.running) {

			auto app = GetApp();
			auto map = app.RootMap;
			if (map is null)
				return;
			auto playground = app.CurrentPlayground;
			if (playground !is null && playground.GameTerminals.Length > 0) {
				auto terminal = playground.GameTerminals[0];
				auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
				if (gui_player !is null) {
					auto script = cast<CSmScriptPlayer>(gui_player.ScriptAPI);
					auto post = script.Post;

					if (script.Score.NbRespawnsRequested > current + offset &&
						post != CSmScriptPlayer::EPost::Char) {
						if ((Time::Now - last_respawn_time) < 1000 &&
							current != 0) {
							offset += 1;
						} else {
							current += 1;
							session += 1;
							total += 1;
							last_respawn_time = Time::Now;
						}
					}
					if (script.Score.NbRespawnsRequested == 0) {
						current = 0;
						offset = 0;
						last_respawn_time = Time::Now;
					}
				}
			}
			yield();
		}
#endif
	}
}
