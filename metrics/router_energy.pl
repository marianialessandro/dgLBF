% router_energy(+Load_bps, +energyProfile, +timePeriod(Seconds), -Energy_kWh)
%
% Calcola l'energia in kWh consumata da un router in base al carico (bps),
% al profilo energetico (inclusa potenza fissa) e al periodo di tempo specificato.
% Tutti i parametri numerici sono reali.
%
% Unità:
% - Load (L) in bps (bit per second)
% - IdlePower in Watt (W)
% - Eps in Watt/bps (W per bit/s) => tipicamente molto piccolo (es. 1.0e-9)
% - Tempo in secondi (s), convertito internamente in ore (h)
% - Output Energy in kilowattora (kWh)

% definisco il valore di default per il periodo di tempo
default_time_period(3600).  % in secondi

% wrapper: 3 parametri, usa il periodo di default
router_energy(Load, EnergyProfile, Energy_kWh) :-
    default_time_period(T),
    router_energy(Load, EnergyProfile, timePeriod(T), Energy_kWh).

% Zona 1: consumo lineare → P_var [W] = Eps * L
router_energy(L, energyProfile(_, IdlePower, p(Eps, T1, _), _, _), timePeriod(T), Energy_kWh) :-
    L < T1,
    T_h     is T / 3600,                    % tempo in ore
    P_var   is L * Eps,                     % potenza variabile in Watt
    P_total is IdlePower + P_var,           % potenza totale in Watt
    Energy_kWh is (P_total * T_h) / 1000.   % energia in kWh

% Zona 2: consumo polinomiale → P_var [W] = L^(2/3)
router_energy(L, energyProfile(_, IdlePower, p(_, T1, T2), _, _), timePeriod(T), Energy_kWh) :-
    L >= T1,
    L =< T2,
    T_h     is T / 3600,
    P_var   is L ** (2/3),             % potenza variabile in Watt
    P_total is IdlePower + P_var,
    Energy_kWh is (P_total * T_h) / 1000.

% Zona 3: consumo esponenziale → P_var [W] = 2^L
router_energy(L, energyProfile(_, IdlePower, p(_, _, T2), _, _), timePeriod(T), Energy_kWh) :-
    L > T2,
    T_h     is T / 3600,
    P_var   is 2 ** L,                 % potenza variabile in Watt
    P_total is IdlePower + P_var,
    Energy_kWh is (P_total * T_h) / 1000.
