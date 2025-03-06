
class BaseMedal {
	Medals::Type type = Medals::Type::None;
	uint64 target = 0;
	uint64 achieved_time = 0;
	bool achieved = false;

	BaseMedal() {}

	BaseMedal(Medals::Type type, bool achieved, uint64 achieved_time, uint64 target = 0) {
		this.target = target;
		this.type = type;
		this.achieved = achieved;
		this.achieved_time = achieved_time;
	}

	BaseMedal(int type, bool achieved, uint64 achieved_time, uint64 target = 0) {
		this.target = target;
		this.type = Medals::Type(type);
		this.achieved = achieved;
		this.achieved_time = achieved_time;
	}

	void check_pb(uint pb) {
		// print("Checking medal " + Medals::to_string(type) + " with target " + target + " and pb " + pb);
		if (achieved)
			return;
		if (target != 0) {
			if (pb == 0)
				return;
			if (pb <= target) {
				// print("Achieved medal " + Medals::to_string(type) + " with target " + target + " and pb " + pb);
				achieved = true;
				achieved_time = data.localData.timerComponent.total;
			}
		}
	}
}