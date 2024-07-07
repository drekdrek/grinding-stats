class RecapFiles : Files {

	RecapFiles() {}

	RecapFiles(const string &in id) {
		try {
			super(id);
		} catch {
			warn("unable to load file with id: " + id + " skipping...");
		}
	}

	void debug_print(const string &in text) override {} // don't need to print
	void save() override {} // don't need to save the files

	void start() override {} // don't need to start the handlers

	int64 get_modified_time() { return IO::FileModifiedTime(file_location); }
}