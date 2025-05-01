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
            respawns integer
        );
        CREATE TABLE IF NOT EXISTS medals (
            map_id VARCHAR(32),
            medal_id integer,
            achieved boolean,
            achieved_time integer,
            FOREIGN KEY(map_id) references grinds(map_id)
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

        string query_string = """
        SELECT * from grinds where map_id = ?;
        """;

        auto query = db.Prepare(query_string);
        query.Bind(1, mapUid);
        query.Execute();

        query.NextRow(); // im not sure why i have to do this twice, but its blank otherwise
        query.NextRow();

        print(query.GetColumnString("map_id"));
        finishes = uint64(query.GetColumnInt64("finishes"));
        resets = uint64(query.GetColumnInt64("resets"));
        time = uint64(query.GetColumnInt64("time"));
        respawns = uint64(query.GetColumnInt64("respawns"));
        // print(query.GetQueryExpanded());
    

        debug_print("Loaded finishes " + finishes + " resets " + resets + " time " + time +
					" respawns " + respawns);
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

        string query_string = """
        INSERT INTO grinds (map_id, time, finishes, resets, respawns)
        VALUES (?,?,?,?,?)
        ON CONFLICT(map_id)
        DO UPDATE SET time=excluded.time, finishes=excluded.finishes, resets=excluded.resets, respawns=excluded.respawns;
        """;

        auto query = db.Prepare(query_string);
        query.Bind(1, mapUid);
        query.Bind(2, time);
        query.Bind(3, finishes);
        query.Bind(4, resets);
        query.Bind(5, respawns);
        
        debug_print("Wrote finishes " + finishes + " resets " + resets + " time " + time +
					" respawns " + respawns);
        print(query.GetQueryExpanded());
        query.Execute();

    }

    	void create_components() {
		finishesComponent = Finishes(finishes);
		resetsComponent = Resets(resets);
		timerComponent = Timer(time);
		respawnsComponent = Respawns(respawns);
	}

}