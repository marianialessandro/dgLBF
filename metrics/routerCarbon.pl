:- table routerCarbon/3.

currentTime("12:30").

/* routerCarbon(N, Energy_kWh, Carbon) :-
    alpha(N, Alpha),
    Carbon is Energy_kWh * Alpha. */

routerCarbon(N, Load, Carbon) :-
    routerEnergy(N, Load, Energy_kWh),
    alpha(N, Alpha),
    Carbon is Energy_kWh * Alpha.

timeOfDay(day) :-
    currentTime(T),
    % split_string/4: suddivide la stringa T su “:”
    split_string(T, ":", "", [HStr, _MStr]),
    % converte la parte ore in numero
    number_string(H, HStr),
    H >= 6,
    H < 18.

timeOfDay(night) :-
    currentTime(T),
    split_string(T, ":", "", [HStr, _MStr]),
    number_string(H, HStr),
    ( H < 6
    ; H >= 18 ).

% predicato helper per ottenere l’intensità carbonica in base al periodo
/* alpha(NodeId, Alpha) :-
    timeOfDay(Period),
    carbonIntensity(NodeId, Period, Alpha). */

alpha(NodeId, Alpha) :-
    /* timeOfDay(Period), */
    carbonIntensity(NodeId, day, Alpha).