class Finishes : BaseComponent {

	Finishes() {}

	Finishes(uint64 total) { super(total); }

	~Finishes() {}

	string toString() override {
		string_constructor = array<string>();
		if (setting_show_duplicates) {

			if (setting_show_finishes_session)
				string_constructor.InsertLast("\\$bbb" + session);
			if (setting_show_finishes_total)
				string_constructor.InsertLast("\\$bbb" + total);
		} else {

			if (setting_show_finishes_session)
				string_constructor.InsertLast("\\$bbb" + session);

			if (setting_show_finishes_total && total > session)
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

			auto app = GetApp();
#if TMNEXT || MP4
			auto map = app.RootMap;
#elif TURBO
			auto map = app.Challenge;
#endif
			if (map is null)
				return;
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
					if (!handled && race_state == CTrackManiaPlayer::ERaceState::Finished && UI::CurrentActionMap() == "TmRaceFull") {
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