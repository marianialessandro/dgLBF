energyCost(N, Energy_kWh, Cost) :-
    energyProfile(N, _, _, _, CostkWh),
    Cost is Energy_kWh * CostkWh.