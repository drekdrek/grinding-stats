class RecapMedals : Medals {
    RecapMedals() {}

    RecapMedals(Json::Value@ medals) {
        super(medals);
    }

    void handler() override {} // don't want a handler
    uint get_pb_time() override {return 0;}      
    void build_medals(Json::Value @m) override {
        for (uint i = 0; i < m.Length; i++) {
            Json::Value medal = m[i];
            int medal_id = medal.Get("medal", 0);
            bool achieved = medal.Get("achieved", false);
            uint64 achieved_time = medal.Get("achieved_time", 0);
            medals.InsertLast(BaseMedal(medal_id, achieved, achieved_time));
        }
    }


}