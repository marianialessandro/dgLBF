from dataclasses import dataclass
from typing import List, Any, Dict

@dataclass
class NodeMetrics:
    id: str
    load: float
    emission: float
    energy_cost: float

class Experiment:
    # ... qui viene tutto il resto della tua classe ...

    def get_node_metrics(self) -> List[NodeMetrics]:
        """
        Restituisce una lista di NodeMetrics basata su self.result["NodeCarbonCost"].
        Ogni elemento di NodeCarbonCost è una tupla:
            ( node_id, ( load, ( carbon_em, energy_cost ) ) )
        """
        raw = self.result.get("NodeCarbonCost", [])
        metrics = []
        for entry in raw:
            node_id, (load, (carbon_em, energy_cost)) = entry
            metrics.append(NodeMetrics(
                id=node_id,
                load=load,
                emission=carbon_em,
                energy_cost=energy_cost
            ))
        return metrics
