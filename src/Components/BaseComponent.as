class BaseComponent {
  protected bool running = false;
  protected bool handled = false;
  protected array<string> string_constructor;

	uint64 session;
	uint64 total;

	BaseComponent() {}

	BaseComponent(uint64 _total) {
		total = _total;
		string_constructor = array<string>();
		session = 0;
	}

	~BaseComponent() {
		running = false;
	}

	void start() {
		running = true;
		startnew(CoroutineFunc(handler));
	}

	void stop() {
		running = false;
	}

  protected void handler() {}

	string toString() { return ""; }
}