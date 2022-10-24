void timer_debug_render() {
    int window_flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
    UI::Begin("Grinding Stats", window_flags);
        UI::BeginGroup();
            UI::BeginTable("timer", 2, UI::TableFlags::SizingFixedFit);
                UI::TableNextColumn();
                UI::Text("Timer ");
                UI::TableNextColumn();
                UI::Text(running ? "\\$0f0Running" : "\\$f00Stopped");
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("Idle");
                UI::TableNextColumn();
                UI::Text((timer_idle ? "\\$f00True" : "\\$0f0False"));
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("Playing");
                UI::TableNextColumn();
                UI::Text(timer_playing ? "\\$0f0True" : "\\$f00False");
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("Paused");
                UI::TableNextColumn();
                UI::Text(timer_paused ? "\\$f00True" : "\\$0f0False");
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("Multiplayer");
                UI::TableNextColumn();
                UI::Text(timer_multiplayer ? "True" : "False");
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("Countdown");
                UI::TableNextColumn();
                UI::Text(timer_countdown ? "\\$f00True" : "\\$0f0False");
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("Spectating");
                UI::TableNextColumn();
                UI::Text(timer_spectating ? "\\$f00True" : "\\$0f0False");
                UI::TableNextRow();
                UI::TableNextColumn();
                UI::Text("Focused");
                UI::TableNextColumn();
                UI::Text(timer_focused ? "\\$0f0True" : "\\$f00False");
            UI::EndTable();
        UI::EndGroup();
    UI::End();
}

void multiplayer_debug_render() {
    string gameModeStr = "";
    auto app = cast<CTrackMania>(GetApp());
    auto network = cast<CTrackManiaNetwork>(app.Network);
    auto server_info = cast<CTrackManiaNetworkServerInfo>(network.ServerInfo);
    gameModeStr = server_info.CurGameModeStr;
    int window_flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
    UI::Begin("Grinding Stats", window_flags);
        UI::BeginGroup();
            UI::BeginTable("multiplayer", 2, UI::TableFlags::SizingFixedFit);
                UI::TableNextColumn();
                UI::Text("CurGameModeStr ");
                UI::TableNextColumn();
                 

                UI::Text(gameModeStr);
            UI::EndTable();
        UI::EndGroup();
    UI::End();
    
}