class SQLite : AbstractData {
  private SQLite::Database @db = null;

	SQLite() {}

	SQLite(SQLite::Database @db) {
		super();
		@ this.db = db;
		initialize();

		try {
			migrate();
		} catch {
		}
	}

	SQLite(SQLite::Database @db, const string &in id) {

		super(id);
		if (id == "" || id == "Unassigned") {
			return;
		}
		@ this.db = db;
		initialize();

		try {
			migrate();
		} catch {
		}
	}

	void initialize() {
		db.Execute("""
        CREATE TABLE IF NOT EXISTS maps (
            map_id VARCHAR(32) PRIMARY KEY,
            time integer,
            finishes integer,
            resets integer,
            respawns integer,
            updated_at timestamp,
            -- recap
            name text,
            titlepack VARCHAR(64)
        );
        CREATE TABLE IF NOT EXISTS medals (
            id INTEGER PRIMARY KEY,
            map_id VARCHAR(32),
            type INTEGER,
            achieved_time INTEGER,
            FOREIGN KEY (map_id) REFERENCES maps(map_id),
            UNIQUE (map_id, type)
        );
        """);
	}

	void migrate() {
		// db.Execute("""
		//     ALTER TABLE maps
		//     ADD example varchar(1);
		// """);
	}

	void load() override {

		if (mapUid == "" || mapUid == "Unassigned") {
			return;
		}

		SQLite::Statement @query = db.Prepare("SELECT * FROM maps WHERE map_id = ?");
		query.Bind(1, mapUid);
		print(query.GetQueryExpanded());
		query.NextRow();

		finishes = uint64(query.GetColumnInt64("finishes"));
		resets = uint64(query.GetColumnInt64("resets"));
		time = uint64(query.GetColumnInt64("time"));
		respawns = uint64(query.GetColumnInt64("respawns"));

		debug_print("Loaded finishes " + finishes + " resets " + resets + " time " + time +
					" respawns " + respawns + " with map_id " + mapUid);

		// auto medals = db.Prepare("SELECT * FROM medals WHERE map_id = ?;");
		auto medals = db.Prepare("""
        SELECT json_object(
         'medal', type,
         'achieved_time', achieved_time
       ) AS result, * FROM medals WHERE map_id = ?
        """);
        medals.Bind(1, mapUid);
        print(medals.GetQueryExpanded());

        medals_json = Json::Array();
        do {
			print("result:" + medals.GetColumnString("result"));
			if (medals.GetColumnString("map_id") != "") {
				Json::Value @medal = Json::Object();
				medal["medal"] = medals.GetColumnInt("type");
				medal["achieved"] = true;
				medal["achieved_time"] = uint64(medals.GetColumnInt64("achieved_time"));
				medals_json.Add(medal);
			}
        }while (medals.NextRow());
        print("medals from sql");
        print(Json::Write(medals_json));
         print("medals from sql");
        if (medals_json.Length == 0) {
			medals_json = Json::Parse('[{"medal":0,"achieved":false,"achieved_time":0},{"medal":1,"achieved":false,"achieved_time":0},{"medal":2,"achieved":false,"achieved_time":0},{"medal":3,"achieved":false,"achieved_time":0},{"medal":4,"achieved":false,"achieved_time":0},{"medal":5,"achieved":false,"achieved_time":0},{"medal":6,"achieved":false,"achieved_time":0},{"medal":7,"achieved":false,"achieved_time":0},{"medal":8,"achieved":false,"achieved_time":0}]');
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

		auto query = db.Prepare("""
            INSERT INTO maps (map_id, time, finishes, resets, respawns, updated_at)
            VALUES (?,?,?,?,?,?)
            ON CONFLICT(map_id)
            DO UPDATE SET time=excluded.time, finishes=excluded.finishes, resets=excluded.resets, respawns=excluded.respawns, updated_at=excluded.updated_at;
		""");
		query.Bind(1, mapUid);
		query.Bind(2, time);
		query.Bind(3, finishes);
		query.Bind(4, resets);
		query.Bind(5, respawns);
		query.Bind(6, Time::get_Stamp());

		debug_print("Wrote finishes " + finishes + " resets " + resets + " time " + time +
					" respawns " + respawns + " with map_id " + mapUid);
		query.Execute();


        auto medals = medalsComponent.export_medals();

		for (uint i = 0; i < medals.Length; i++) {
			Json::Value @medal = medals[i];
			if (bool(medal.Get("achieved")))
				break;
			auto medals_query = db.Prepare("""
                INSERT INTO medals (map_id, type, achieved_time)
                VALUES (?,?,?)
                ON CONFLICT(map_id, type)
                DO UPDATE SET achieved=excluded.achieved, achieved_time=excluded.achieved_time
            """);
			medals_query.Bind(1, mapUid);
			medals_query.Bind(2, int(medal.Get("medal")));
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

	uint get_track_count() override {
		auto query = db.Prepare("SELECT count(*) as count FROM maps");
		query.NextRow();
		int count = query.GetColumnInt("count");
		return count;
	}
}