class SQLite : AbstractData {
    private SQLite::Database@ db = null;
    
    SQLite() {}

    SQLite(SQLite::Database@ db, const string &in id) {
        
        super(id);
        if (id == "" || id == "Unassigned") {
            return;
        }
        @this.db = db;
        initialize();

        try {migrate();} catch {}
    }


    void initialize() {
        string query = """
        CREATE TABLE IF NOT EXISTS grinds (
            map_id VARCHAR(32) PRIMARY KEY,
            time integer,
            finishes integer,
            resets integer,
            respawns integer,
            updated_at timestamp
        );
        CREATE TABLE IF NOT EXISTS medals (
            id INTEGER PRIMARY KEY,
            map_id VARCHAR(32),
            medal_id INTEGER,
            achieved BOOLEAN,
            achieved_time INTEGER,
            FOREIGN KEY (map_id) REFERENCES grinds(map_id),
            UNIQUE (map_id, medal_id)
        );
        """;

        db.Execute(query);
        print("executed " + query);
    }

    void migrate() {
        string query = """
            ALTER TABLE grinds
            ADD example varchar(1);
        """;
        // db.Execute(query);
    }

    void load() override {
        
        if (mapUid == "" || mapUid == "Unassigned") {
            return;
        }

        string grinds_query_string = """
        SELECT * FROM grinds WHERE map_id = ?;
        """;

        auto grinds_query = db.Prepare(grinds_query_string);
        grinds_query.Bind(1, mapUid);
        grinds_query.Execute();

        grinds_query.NextRow(); // im not sure why i have to do this twice, but its blank otherwise
        grinds_query.NextRow();

        print(grinds_query.GetColumnString("map_id"));
        finishes = uint64(grinds_query.GetColumnInt64("finishes"));
        resets = uint64(grinds_query.GetColumnInt64("resets"));
        time = uint64(grinds_query.GetColumnInt64("time"));
        respawns = uint64(grinds_query.GetColumnInt64("respawns"));
        // print(grinds_query.GetQueryExpanded());
    

        debug_print("Loaded finishes " + finishes + " resets " + resets + " time " + time +
					" respawns " + respawns + " with map_id " + mapUid);

        string medals_query_string = """
        SELECT * FROM medals WHERE map_id = ?;
        """;

        auto medals_query = db.Prepare(medals_query_string);
        medals_query.Bind(1, mapUid);
        medals_query.Execute();

        medals_json = Json::Array();
        while (medals_query.NextRow()) {
            if (medals_query.GetColumnString("map_id") == "") {
                Json::Value@ medal = Json::Object();
                medal["medal"] = medals_query.GetColumnInt("medal_id");
                medal["achieved"] = medals_query.GetColumnInt("achieved") == 1;
                medal["achieved_time"] = uint64(medals_query.GetColumnInt64("achieved_time"));
                medals_json.Add(medal);
            }
        }
        if (medals_json.Length == 0) {
            medals_json = Json::Parse('[{"medal":0,"achieved":false,"achieved_time":"          0"},{"medal":1,"achieved":false,"achieved_time":"          0"},{"medal":2,"achieved":false,"achieved_time":"          0"},{"medal":3,"achieved":false,"achieved_time":"          0"},{"medal":4,"achieved":false,"achieved_time":"          0"},{"medal":5,"achieved":false,"achieved_time":"          0"},{"medal":6,"achieved":false,"achieved_time":"          0"},{"medal":7,"achieved":false,"achieved_time":"          0"},{"medal":8,"achieved":false,"achieved_time":"          0"}]');
        }


        create_components();
    }

    void save() override {

        if (mapUid == "" || mapUid == "Unassigned") {
            return;
        }

        finishes = finishesComponent.total;
		resets = resetsComponent.total;
		time = timerComponent.total;
		respawns = respawnsComponent.total;

        string grinds_insert = """
        INSERT INTO grinds (map_id, time, finishes, resets, respawns, updated_at)
        VALUES (?,?,?,?,?,?)
        ON CONFLICT(map_id)
        DO UPDATE SET time=excluded.time, finishes=excluded.finishes, resets=excluded.resets, respawns=excluded.respawns, updated_at=excluded.updated_at;
        """;

        auto grinds_query = db.Prepare(grinds_insert);
        grinds_query.Bind(1, mapUid);
        grinds_query.Bind(2, time);
        grinds_query.Bind(3, finishes);
        grinds_query.Bind(4, resets);
        grinds_query.Bind(5, respawns);
        grinds_query.Bind(6, Time::get_Stamp());
        
        debug_print("Wrote finishes " + finishes + " resets " + resets + " time " + time +
					" respawns " + respawns + " with map_id " + mapUid);
        print(grinds_query.GetQueryExpanded());
        grinds_query.Execute();


        string medals_insert = """
        INSERT INTO medals (map_id, medal_id, achieved, achieved_time)
        VALUES (?,?,?,?)
        ON CONFLICT(map_id, medal_id)
        DO UPDATE SET achieved=excluded.achieved, achieved_time=excluded.achieved_time
        """;

        auto medals = medalsComponent.export_medals();

        for (uint i = 0; i < medals.Length; i++) {
            Json::Value@ medal = medals[i];
            print(Json::Write(medal));
            auto medals_query = db.Prepare(medals_insert);
            medals_query.Bind(1,mapUid);
            medals_query.Bind(2, int(medal.Get("medal")));
            medals_query.Bind(3, bool(medal.Get("achieved")) ? 1 : 0);
            medals_query.Bind(4, uint64(medal.Get("achieved_time")));
            medals_query.Execute();
        }
    }

    	void create_components() {
		finishesComponent = Finishes(finishes);
		resetsComponent = Resets(resets);
		timerComponent = Timer(time);
		respawnsComponent = Respawns(respawns);
        medalsComponent = Medals(medals_json);
	}

}