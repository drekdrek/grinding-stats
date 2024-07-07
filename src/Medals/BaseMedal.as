
class BaseMedal {
	Medals::Type type;
	uint64 target = 0;
	uint64 achieved_time = 0;

	bool achieved = false;

	BaseMedal(Medals::Type type, uint64 target = 0) {
		this.target = target;
		this.type = type;
	}
	BaseMedal(int type, uint64 target = 0) {
		this.target = target;
		this.type = Medals::Type(type);
	}

	void check_pb(uint pb) {
		// print("Checking medal " + Medals::to_string(type) + " with target " +
		// target + " and pb " + pb);
		if (achieved)
			return;
		if (target != 0) {
			if (pb == 0)
				return;
			if (pb <= target) {
				// print("Achieved medal " + Medals::to_string(type) + " with
				// target " + target + " and pb " + pb);
				achieved = true;
				// the most wonderful line of code ever
				achieved_time = data.localData.timerComponent.total;
			}
		}
	}
}