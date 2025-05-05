class Timer : BaseComponent {

  private uint64 start_time = Time::Now;
  private uint64 current_time = Time::Now;
  private uint64 session_offset = 0;
  private uint64 total_offset = 0;
  private bool timing = true;
	bool same = false;

  private uint64 timer_start_idle = 0;

	Timer() {}

	Timer(uint64 _total_offset) {
		session_offset = 0;
		total_offset = _total_offset;
		same = session_offset == total_offset;
		total = _total_offset;
	}

	~Timer() {
		this.timing = false;
	}

	bool isRunning() {
		bool is_idle = false;
		bool is_paused = false;
		bool is_playing = false;
		bool is_multiplayer = false;
		bool is_countdown = false;
		bool is_spectating = false;
		bool is_focused = false;

		auto app = GetApp();
#if TMNEXT || MP4
		auto rootmap = app.RootMap;
#elif TURBO
		auto rootmap = app.Challenge;
#endif
		auto playground = app.CurrentPlayground;
		if (rootmap !is null && playground !is null && playground.GameTerminals.Length > 0) {
			is_multiplayer = app.PlaygroundScript is null;
			auto terminal = playground.GameTerminals[0];
#if TMNEXT
			is_paused = (app.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed || UI::CurrentActionMap() != "Vehicle") && !is_multiplayer;
			auto gui_player = cast<CSmPlayer>(terminal.GUIPlayer);
			if (gui_player is null)
				return false;
			auto script_player = cast<CSmScriptPlayer>(gui_player.ScriptAPI);
			is_countdown = app.Network.PlaygroundClientScriptAPI.GameTime - script_player.StartTime < 0;
			is_spectating = app.Network.PlaygroundClientScriptAPI.IsSpectator;
			is_focused = app.InputPort.IsFocused;
#elif MP4
			is_paused = app.Network.PlaygroundClientScriptAPI.IsInGameMenuDisplayed || UI::CurrentActionMap() != "TmRaceFull";
			auto gui_player = cast<CTrackManiaPlayer>(terminal.GUIPlayer);
			if (gui_player is null)
				return false;
			auto script_player = gui_player.ScriptAPI;
			is_focused = app.InputPort.IsFocused;
#elif TURBO
			is_paused = playground.Interface.InterfaceRoot.IsFocused || UI::CurrentActionMap() != "TmRacePad";
			auto gui_player = cast<CTrackManiaPlayer>(terminal.ControlledPlayer);
			if (gui_player is null)
				return false;
			auto script_player = gui_player;
			// thank you XertroV :)
			is_focused = Dev::GetOffsetUint8(app.InputPort, 0x890) == 1;
#endif
			if (gui_player !is null) {
				is_playing = true;
				if (Math::Abs(script_player.Speed) < int(setting_idle_speed)) {
					if (timer_start_idle == 0)
						timer_start_idle = Time::Now;
					if ((Time::Now - timer_start_idle) > (1000 * setting_idle_time)) {
						is_idle = true;
					}
				} else {
					timer_start_idle = 0;
					is_idle = false;
				}
			} else {
				is_playing = false;
				is_idle = false;
				timer_start_idle = 0;
			}
		}
		return (!is_idle && is_playing && !is_paused && !is_countdown && !is_spectating && is_focused);
	}

	void keep_time() {
		while (timing) {
			auto app = GetApp();
#if TMNEXT || MP4
			auto map = app.RootMap;
#elif TURBO
			auto map = app.Challenge;
#endif
			if (map is null)
				return;
			current_time = Time::Now;
			session = (current_time + session_offset) - start_time;
			total = (current_time + total_offset) - start_time;
			yield();
		}
	}

	void stop() override {
		running = false;
		session_offset = session;
		total_offset = total;
		timing = false;
	}

	void start() override {
		running = true;
		startnew(CoroutineFunc(handler));
		startnew(CoroutineFunc(keep_time));
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
			bool is_running = isRunning();
			if (!is_running && !handled) {
				handled = true;
				stop();
			} else if (is_running && handled) {
				handled = false;
				start_time = Time::Now;
				timing = true;
				startnew(CoroutineFunc(keep_time));
			}
			yield();
		}
	}

	string toString(uint64 time) {
		if (time == 0)
			return "--:--:--." + (setting_show_thousands ? "---" : "--");
		string str = "\\$bbb" + Time::Format(time, true, true, setting_show_hour_if_0, false);
		return setting_show_thousands ? str : str.SubStr(0, str.Length - 1);
	}
}
