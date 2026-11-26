class SQLite : AbstractData {
  private SQLite::Database @db = null;
  protected BaseMedal @highest_medal = BaseMedal(-1, false, 0);

	SQLite() {}

	SQLite(SQLite::Database @db) {
		super();
		// clang-format off
		@this.db = db;
		// clang-format on
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
		// clang-format off
		@this.db = db;
		// clang-format on
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

auto query = data.db.Prepare("""
          SELECT
            maps.*,
            MAX(medals.type) as highest_medal,
            medals.achieved_time,
            MAX(medals.type) is not null as has_acheived_medal
        FROM
            maps
        LEFT JOIN medals ON
            maps.map_id = medals.map_id
        WHERE maps.map_id = ?
        GROUP BY maps.map_id
        """);
						query.Bind(1, mapUid);
		print(query.GetQueryExpanded());
		query.NextRow();
		finishes = uint64(query.GetColumnInt64("finishes"));
		resets = uint64(query.GetColumnInt64("resets"));
		time = uint64(query.GetColumnInt64("time"));
		respawns = uint64(query.GetColumnInt64("respawns"));

		// highest medal
		print("has_achieved_medal" + query.GetColumnInt("has_achieved_medal"));
		bool has_medal = query.GetColumnInt("has_acheived_medal") == 1;
		print("has medal:" + has_medal);
		if (has_medal) {
			Medals::Type type = Medals::Type(query.GetColumnInt("highest_medal"));
			uint64 medal_time = uint64(query.GetColumnInt64("achieved_time"));
			highest_medal = BaseMedal(type, true, medal_time);
			print(highest_medal.toString());
	}

	debug_print("Loaded finishes " + finishes + " resets " + resets + " time " + time +
				" respawns " + respawns + " with map_id " + mapUid);

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

		insert_map(mapUid, time, finishes, resets, respawns);

		auto medals = medalsComponent.export_medals();

		for (uint i = 0; i < medals.Length; i++) {
			Json::Value @medal = medals[i];
			if (!bool(medal.Get("achieved"))) {
				break;
			}
			insert_medal(mapUid, Medals::Type(int(medal.Get("medal"))), uint64(medal.Get("achieved_time")));
		}
	}

	void insert_map(const string &in map_id, uint64 time, uint64 finishes, uint64 resets, uint64 respawns) {
		auto query = db.Prepare("""
            INSERT INTO maps (map_id, time, finishes, resets, respawns, updated_at)
            VALUES (?,?,?,?,?,?)
            ON CONFLICT(map_id)
            DO UPDATE SET time=excluded.time, finishes=excluded.finishes, resets=excluded.resets, respawns=excluded.respawns, updated_at=excluded.updated_at;
		""");
		query.Bind(1, map_id);
		query.Bind(2, time);
		query.Bind(3, finishes);
		query.Bind(4, resets);
		query.Bind(5, respawns);
		query.Bind(6, Time::get_Stamp());

		query.Execute();
		debug_print("Wrote finishes " + finishes + " resets " + resets + " time " + time +
					" respawns " + respawns + " with map_id " + map_id);
	}

	void insert_medal(const string &in map_id, Medals::Type medal, uint64 time) {
	auto medals_query = db.Prepare("""
                INSERT INTO medals (map_id, type, achieved_time)
                VALUES (?,?,?)
                ON CONFLICT(map_id, type) DO NOTHING;
            """);
			medals_query.Bind(1, mapUid);
			medals_query.Bind(2, int(medal));
			medals_query.Bind(3, uint64(time));

			medals_query.Execute();
			debug_print("Wrote medal " + Medals::to_string(medal) + " time " + time + " with map_id " + map_id);
	}

	void create_components() {
		finishesComponent = Finishes(finishes);
		resetsComponent = Resets(resets);
		timerComponent = Timer(time);
		respawnsComponent = Respawns(respawns);
		medalsComponent = Medals(highest_medal);
	}

	uint get_track_count() override {
		auto query = db.Prepare("SELECT count(*) as count FROM maps");
		query.NextRow();
		int count = query.GetColumnInt("count");
		return count;
	}
}