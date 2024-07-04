class Medals { 
    private bool running = true;
    private bool handled = false;
    private array<BaseMedal@> medals;

    Medals() {
        medals = {
            BaseMedal(Medal::Type::Bronze),
            BaseMedal(Medal::Type::Silver),
            BaseMedal(Medal::Type::Gold),
#if TMNEXT || MP4
            BaseMedal(Medal::Type::Author),
#elif TURBO
            BaseMedal(Medal::Type::Trackmaster),
            BaseMedal(Medal::Type::S_Bronze),
            BaseMedal(Medal::Type::S_Silver),
            BaseMedal(Medal::Type::S_Gold),
            BaseMedal(Medal::Type::S_Trackmaster),
#endif
#if TMNEXT && DEPENDENCY_CHAMPIONMEDALS
            BaseMedal(Medal::Type::Champion)
#endif
            };
    }

    void handler() {
        //when the player loads into a map, check if they have achieved the medal
        //whenever the player finishes, check if they have achieved the medal
            //get their current time on the map
            //compare against all medals

        while (running) {

        }
    }



    BaseMedal@ get_highest_medal() {
        //for all medals in the medal array, find the last medal in the array that has been achieved
        //returns null if none have been achieved
        //return the medal
        BaseMedal@ candidate = null;
        for (uint i = 0; i < medals.Length; i++) {
            if (medals[i].achieved) {
                candidate = medals[i];
            }
        }
        return candidate;
    }
}