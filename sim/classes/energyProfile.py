class EnergyProfile:
    def __init__(
        self,
        node: str,
        idle_power: float,
        maxPower: float,
        eps: float,
        alphaDay: float,
        alphaNight: float,
        cost_kwh: float,
    ):
        self.node = node
        self.idle_power = idle_power
        self.maxPower = maxPower
        self.eps = eps
        self.alphaDay = alphaDay
        self.alphaNight = alphaNight
        self.cost_kwh = cost_kwh

    def to_prolog(self) -> str:
        factEp = (
            f"energyProfile({self.node}, {self.idle_power:.2f}, "
            f"{self.eps:.1e},"
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
