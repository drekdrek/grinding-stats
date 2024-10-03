#if TURBO

namespace TurboSTM {

class SuperTime {
	int m_number;
	uint m_time;
	string m_player;
}

array<SuperTime @> g_superTimes;
SuperTime @g_hoveringSuperTime;

SuperTime @GetSuperTime(int number) {
	for (uint i = 0; i < g_superTimes.Length; i++) {
		if (g_superTimes[i].m_number == number) {
			return g_superTimes[i];
		}
	}
	return null;
}

CSystemFidFile @GetFile(const string &in path) {
	for (int i = int(Fids::AllPacks.Length) - 1; i >= 0; i--) {
		auto pack = Fids::AllPacks[i];
		auto file = Fids::GetFidsFile(pack.Location, path);
		if (file !is null) {
			return file;
		}
	}
	return null;
}

void LoadSuperTimes() {
	while (Fids::AllPacks.Length != 2) {
		yield();
	}

	auto superSoloFile = GetFile("Media/Config/TMConsole/Campaign/SuperSoloCampaign.xml");
	if (Fids::Preload(superSoloFile) is null) {
		print("Unable to preload SuperSoloCampaign file!");
		return;
	}

	auto superSoloText = cast<CPlugFileText>(superSoloFile.Nod);
	if (superSoloText is null) {
		print("SuperSoloCampaign file is not a CPlugFileText file!");
		return;
	}

	auto superSoloDoc = XML::Document(superSoloText.Text);
	auto nodeRoot = superSoloDoc.Root();

	auto nodeTrackList = nodeRoot.Child("supersolocampaign");
	auto nodeTrack = nodeTrackList.FirstChild();
	while (nodeTrack) {
		auto newSuperTime = SuperTime();
		newSuperTime.m_number = Text::ParseInt(nodeTrack.Attribute("id")) + 1;
		newSuperTime.m_time = Text::ParseUInt(nodeTrack.Attribute("superauthortime"));
		newSuperTime.m_player = nodeTrack.Attribute("superplayer");
		g_superTimes.InsertLast(newSuperTime);

		nodeTrack = nodeTrack.NextSibling();
	}
}

} // namespace TurboSTM

#endif