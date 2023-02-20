// class Element {

//     string mapUid;
//     Files@ data;
//     Finishes@ finishes;
//     Resets@ resets;
//     Respawns@ respawns;
//     Timer@ timer;

//     Element() {
//         startnew(getMapUid);
//     }

//     void getMapUid() {
//         CGameCtnApp@ app = GetApp();
//         string id = "";
//         while (true) {
// #if TMNEXT
//         auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
//         id = (playground is null || playground.Map is null) ? "" : playground.Map.IdName;
// #elif MP4
//         auto rootmap = app.RootMap;
//         id = (rootmap is null ) ? "" : rootmap.IdName;
// #elif TURBO
//         auto challenge = app.Challenge;
//         id = (challenge is null) ? "" : challenge.IdName;
// #endif
//         if (id == "" && data is null) return;

//         if (app.Editor !is null) {
//              this.destroy();
//         } else if (id != mapUid) {
//             this.destroy();
//             this.mapUid = id;
//             this.create();
//         }

//         yield();
//         }
//     }
//     void destroy() {}
//     void create() {}
//     /*
    
//         data = Files(mapUid);
//         //wait while the Files constructor is working 
//         while(!data.created) yield();

//         finishes = Finishes(data.finishes);
//         resets = Resets(data.resets);
//         respawns = Respawns(data.respawns);
//         timer = Timer(data.time);
//  */
// }