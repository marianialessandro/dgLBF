timePeriod(3600).  % in secondi

routerEnergy(N, Load, Energy_kWh) :-
    timePeriod(T),
    energyProfile(N, IdlePower, P, _, _),
    routerEnergy(Load, IdlePower, P, T, Energy_kWh).

% Zona 1: consumo lineare → P_var [W] = Eps * L
routerEnergy(L, IdlePower, p(Eps, T1, _), T, Energy_kWh) :-
    L < T1,
    T_h     is T / 3600,
    P_var   is L * Eps,
    P_total is IdlePower + P_var,
    Energy_kWh is (P_total * T_h) * 1.0e-3.

% Zona 2: consumo polinomiale → P_var [W] = L^(2/3)
routerEnergy(L, IdlePower, p(_, T1, T2), T, Energy_kWh) :-
    L >= T1,
    L =< T2,
    T_h     is T / 3600,
    P_var   is L ** (2/3),
    P_total is IdlePower + P_var,
    Energy_kWh is (P_total * T_h) * 1.0e-3.

% Zona 3: consumo esponenziale → P_var [W] = 2^L
routerEnergy(L, IdlePower, p(_, _, T2), T, Energy_kWh) :-
    L > T2,
    T_h     is T / 3600,
    P_var   is 2 ** L,
    P_total is IdlePower + P_var,
    Energy_kWh is (P_total * T_h) * 1.0e-3.