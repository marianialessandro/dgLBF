timePeriod(3600).  % in secondi

routerEnergy(N, Load, Energy_kWh) :-
    timePeriod(T),
    energyProfile(N, IdlePower, P, MaxPower, _),
    routerEnergy(Load, IdlePower, MaxPower, P, T, Energy_kWh).

routerEnergy(L, IdlePower, MaxPower, p(Eps, _, _), T, Energy_kWh) :-
    P_var    is L * Eps,
    P_total  is IdlePower + P_var,
    T_h     is T / 3600,
    Energy_kWh is (min(P_total, MaxPower)* T_h) * 1.0e-3.