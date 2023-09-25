updateCapacities([N1,N2|Ns], BitRate, OldAlloc, NewAlloc) :-
    select((N1,N2, OldC), OldAlloc, Rest), NewC is OldC + BitRate,
    updateCapacities([N2|Ns], BitRate, [(N1,N2,NewC)|Rest], NewAlloc).
updateCapacities([N1,N2|Ns], BitRate, OldAlloc, NewAlloc) :-
    \+ member((N1,N2,_), OldAlloc),
    updateCapacities([N2|Ns], BitRate, [(N1,N2,BitRate)|OldAlloc], NewAlloc).
updateCapacities([_], _, Alloc, Alloc).

updateFlows([N|Ns], FlowId) :- flowsAt(N, Flows), retract(flowsAt(N, Flows)), assert(flowsAt(N, [FlowId|Flows])), updateFlows(Ns, FlowId).
updateFlows([], _).

usedBandwidth(N1, N2, Alloc, Capacity) :- member((N1,N2,Capacity), Alloc).
usedBandwidth(N1, N2, Alloc, 0) :- \+ member((N1,N2,_), Alloc).

delay(((PathMinB, _),Path), Delay) :- PathMinB > 0, length(Path, L), Hops is L-1, Delay is PathMinB/Hops.
delay(((PathMinB, _),_), 0) :- PathMinB < 0.