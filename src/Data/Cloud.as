class Cloud : AbstractData {

	Cloud() {}

	Cloud(const string &in id) { super(id); }

	void load() override {}

	void save() override {}

	void overwrite(AbstractData @other) override {}
}