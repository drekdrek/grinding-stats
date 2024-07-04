class BaseComponent {
    protected bool running = true;
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

    void start() {
        running = true;
        startnew(CoroutineFunc(handler));
    }

    protected void handler() {}

    string toString() {return "";}

}