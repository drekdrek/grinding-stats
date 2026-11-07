
Recap recap;
DataManager data;
Migrate migrate;

void Main() {
#if TURBO
	await(startnew(TurboSTM::LoadSuperTimes));
#endif
#if DEPENDENCY_NADEOSERVICES
	NadeoServices::AddAudience("NadeoLiveServices");
#endif
	if (setting_recap_show_menu && !recap.started) {
		recap.start();
	}

	data.start();
}
