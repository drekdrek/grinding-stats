class RecapSQLite {
    RecapSQLite() {}

    RecapSQLite(SQLite::Database@ db) {

    }


    array<RecapElement@> get_recap_elements() {
        array<RecapElement@> ret = array<RecapElement @>();
        string query_string = """
            SELECT * FROM grinds
        """;
        auto query = data.db.Prepare(query_string);
        // query.Execute();
        while(query.NextRow()) {
            string map_id = query.GetColumnString("map_id");
            if (map_id != "") {

            uint64 finishes = uint64(query.GetColumnInt64("finishes"));
            uint64 resets = uint64(query.GetColumnInt64("resets"));
            uint64 time = uint64(query.GetColumnInt64("time"));
            uint64 respawns = uint64(query.GetColumnInt64("respawns"));
            int64 updated_at = query.GetColumnInt64("updated_at");

            string medals_query_string = """
            SELECT * FROM medals WHERE map_id = ?;
            """;

            auto medals_query = data.db.Prepare(medals_query_string);
            medals_query.Bind(1, map_id);
            medals_query.Execute();

            auto medals_json = Json::Array();
            while (medals_query.NextRow()) {
                if (medals_query.GetColumnString("map_id") != "") {
                    Json::Value@ medal = Json::Object();
                    medal["medal"] = medals_query.GetColumnInt("medal_id");
                    medal["achieved"] = medals_query.GetColumnInt("achieved") == 1;
                    medal["achieved_time"] = uint64(medals_query.GetColumnInt64("achieved_time"));
                }
            }

            ret.InsertLast(RecapElement(map_id, time, finishes, resets, respawns, updated_at, medals_json));
            }
        }
        return ret;
    }
    
}