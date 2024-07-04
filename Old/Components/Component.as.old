class Component {
    protected bool running = true;
    protected bool handled = false;
    uint64 session;
    uint64 total;
    
    Component() {}

    Component(uint64 _total) {
        total = _total;
        session = 0;    
    }

    void destroy() {
        running = false;
    }

    void start() {
        running = true;
        startnew(CoroutineFunc(handler));
    }

    void handler() {};

    string toString() {return "";};
}