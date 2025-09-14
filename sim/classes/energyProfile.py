class EnergyProfile:
    def __init__(
        self,
        node: str,
        idle_power: float,
        maxPower: float,
        eps: float,
        t1: int,
        t2: int,
        alphaDay: float,
        alphaNight: float,
        cost_kwh: float,
    ):
        self.node = node
        self.idle_power = idle_power
        self.maxPower = maxPower
        self.eps = eps
        self.t1 = t1
        self.t2 = t2
        self.alphaDay = alphaDay
        self.alphaNight = alphaNight
        self.cost_kwh = cost_kwh

    def to_prolog(self) -> str:
        factEp = (
            f"energyProfile({self.node}, {self.idle_power:.2f}, "
            f"p({self.eps:.1e}, {self.t1}, {self.t2}), "
            f"{self.maxPower:.2f},"
            f"{self.cost_kwh:.2f})."
        )
        
        factCID = (
            f"carbonIntensity({self.node}, day, "
            f"{self.alphaDay:.2f})."
        )
        
        factCIN = (
            f"carbonIntensity({self.node}, night, "
            f"{self.alphaNight:.2f})."
        )
        
        return "\n".join([factEp, factCID, factCIN])
