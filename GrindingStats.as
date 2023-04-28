enum displays {
    Only_when_Openplanet_menu_is_open,
    Always_except_when_interface_is_hidden,
    Always
}

Data data;
Recap recap;

bool recap_enabled = false;
string folder_location = IO::FromDataFolder('') + 'Grinding Stats';

void Main()
{
#if DEPENDENCY_NADEOSERVICES
    NadeoServices::AddAudience("NadeoLiveServices");
#endif
    if (setting_recap_show_menu && !recap.started) recap.start(); 
    if (!IO::FolderExists(folder_location)) IO::CreateFolder(folder_location);
}
