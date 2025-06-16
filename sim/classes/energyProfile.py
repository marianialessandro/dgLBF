class EnergyProfile:
    def __init__(
        self,
        node: str,
        idle_power: float,
        eps: float,
        t1: int,
        t2: int,
        alpha: float,
        cost_kwh: float,
    ):
        self.node = node
        self.idle_power = idle_power
        self.eps = eps
        self.t1 = t1
        self.t2 = t2
        self.alpha = alpha
        self.cost_kwh = cost_kwh

    def to_prolog(self) -> str:
        return (
            f"energyProfile({self.node}, {self.idle_power:.2f}, "
            f"p({self.eps:.1e}, {self.t1}, {self.t2}), "
            f"{self.alpha:.4f}, {self.cost_kwh:.2f})."
        )