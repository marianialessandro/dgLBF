routerCarbon(N, Energy_kWh, Carbon) :-
    energyProfile(N, _, _, Alpha, _),
    Carbon is Energy_kWh * Alpha.