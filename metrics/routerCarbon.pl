routerCarbon(Node, Load, Carbon) :-
    routerEnergy(Node, Load, Energy_kWh),
    alpha(Node, Alpha),
    Carbon is Energy_kWh * Alpha.

alpha(NodeId, Alpha) :-
    timeOfDay(Period),
    carbonIntensity(NodeId, Period, Alpha).
