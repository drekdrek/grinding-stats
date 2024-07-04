namespace Medal {
    enum Type {
        Bronze,
        Silver,
        Gold,
#if TMNEXT || MP4
        Author,
#elif TURBO
        Trackmaster,
        S_Bronze,
        S_Silver,
        S_Gold,
        S_Trackmaster,
#endif
#if TMNEXT && DEPENDENCY_CHAMPIONMEDALS
        Champion
#endif
    }
}

class BaseMedal {
    Medal::Type medal;
    uint64 target_time;
    uint64 current_time;
    
    bool achieved = false;
    uint64 achieved_time = 0;

    BaseMedal(Medal::Type medal) {
        this.medal = medal;
    }
}