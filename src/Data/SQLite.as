class SQLite : AbstractData {
    private string file_location = IO::FromStorageFolder("data.db");
    private SQLite::Database@ db = null;
    
    SQLite() {}

    SQLite(const string &in id) {
        super(id);
        if (id == "" || id == "Unassigned") {
            return;
        }
        @db = SQLite::Database(file_location);
        initialize();
        migrate();
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
        //db.execute(query)
    }
}