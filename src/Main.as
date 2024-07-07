
DataManager data;
Recap recap;

void Main() {
#if TURBO
	startnew(CoroutineFunc(TurboSTM::LoadSuperTimes));
#endif
#if DEPENDENCY_NADEOSERVICES
	NadeoServices::AddAudience("NadeoLiveServices");
#endif
	if (setting_recap_show_menu && !recap.started)
		recap.start();

	migrateOldData();
}

void migrateOldData() {
	auto old_path = IO::FromDataFolder("Grinding Stats");
	if (IO::FolderExists(old_path)) {
		UI::ShowNotification(
			"Grinding Stats",
			"Found old data folder, attempting to merge data together.",
			UI::HSV(0.10f, 1.0f, 1.0f), 2500);
		auto new_path = IO::FromStorageFolder("data");
		if (IO::FolderExists(new_path)) {
			// the new folder already exists, error
			UI::ShowNotification(
				"Grinding Stats",
				"Data migration failed.\nAttempting to merge data together.",
				UI::HSV(0.10f, 1.0f, 1.0f), 7500);
			warn("The new data folder already exists.\tOld path: " + old_path +
				 "\tnew path: " + new_path);
			startnew(CoroutineFunc(mergeData));
		}
		IO::Move(old_path, new_path);
		// check if the folder is empty,
		// if it is, delete it
		if (IO::IndexFolder(old_path, true).Length == 0) {
			IO::DeleteFolder(old_path);
		}
	}
}

void mergeData() {
	auto old_path = IO::FromDataFolder("Grinding Stats");
	auto new_path = IO::FromStorageFolder("data");

	auto old = IO::IndexFolder(old_path, true);
	auto new = IO::IndexFolder(new_path, true);
	for (uint i = 0; i < old.Length; i++) {
		const string[] @parts = old[i].Split("/");
		const string base_name = parts[parts.Length - 1];
		print("moving " + old[i] + " to " + new_path + "/" + base_name);
		IO::Move(old[i], new_path + "/" + base_name);

		yield();
	}

	if (IO::IndexFolder(old_path, true).Length == 0) {
		IO::DeleteFolder(old_path);
		UI::ShowNotification("Grinding Stats", "Completed Data Transfer",
							 UI::HSV(0.35f, 1.0f, 1.0f), 10000);
	} else {
		UI::ShowNotification("Grinding Stats",
							 "There was a conflict with file names, please "
							 "manually merge the data folders",
							 UI::HSV(1.0f, 1.0f, 1.0f), 10000);
	}
}
