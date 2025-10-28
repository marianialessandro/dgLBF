timePeriod(3600).

routerEnergy(N, Load_Mbps, Energy_kWh) :-
    timePeriod(Time),
    energyProfile(N, IdlePower, P, MaxPower, _),
    Load_Gbps is Load_Mbps / 1000,
    routerEnergy(Load_Gbps, IdlePower, MaxPower, P, Time, Energy_kWh).

routerEnergy(Load, IdlePower, MaxPower, Eps, Time, Energy_kWh) :-
    VariablePower    is Load * Eps,
    TotalPower  is IdlePower + VariablePower,
    T_h     is Time / 3600,
    Energy_kWh is (min(TotalPower, MaxPower)* T_h) * 1.0e-3.
