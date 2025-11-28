energyCost(N, Energy_kWh, Cost) :-
    energyProfile(N, _, _, _, CostkWh),
    Cost is Energy_kWh * CostkWh.

routerCost(Node, Load, Cost) :-
    routerEnergy(Node, Load, Energy_kWh),
    energyProfile(Node, _, _, _, CostkWh),
    Cost is Energy_kWh * CostkWh.
