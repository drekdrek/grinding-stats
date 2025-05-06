class Resets : BaseComponent {
	Resets() {}

	Resets(uint64 total) { super(total); }

	~Resets() {}

	string toString() override {
		string_constructor = array<string>();

		if (setting_show_duplicates) {

			if (setting_show_resets_session)
				string_constructor.InsertLast("\\$ddd" + session);
			if (setting_show_resets_total)
				string_constructor.InsertLast("\\$bbb" + total);
		} else {

			if (setting_show_resets_session)
				string_constructor.InsertLast("\\$bbb" + session);

			if (setting_show_resets_total && total > session)
				string_constructor.InsertLast("\\$bbb" + total);
		}

		if (string_constructor.Length == 2) {
			return string_constructor[0] + "\\$fff  /  " + string_constructor[1];
		}
		if (string_constructor.Length == 1) {
			return string_constructor[0];
		}
		return "";
	}

	void handler() override {
		while (this.running) {
			yield();

			auto app = GetApp();
#if TMNEXT || MP4
			auto map = app.RootMap;
#elif TURBO
			auto map = app.Challenge;
#endif
			if (map is null)
				continue;
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
		}
	}
}