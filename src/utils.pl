updateCapacities([N1,N2|Ns], BitRate, OldAlloc, NewAlloc) :-
    select((N1,N2,OldC), OldAlloc, Rest), NewC is OldC + BitRate,
    updateCapacities([N2|Ns], BitRate, [(N1,N2,NewC)|Rest], NewAlloc).
updateCapacities([N1,N2|Ns], BitRate, OldAlloc, NewAlloc) :-
    \+ member((N1,N2,_), OldAlloc),
    updateCapacities([N2|Ns], BitRate, [(N1,N2,BitRate)|OldAlloc], NewAlloc).
updateCapacities([_], _, Alloc, Alloc).

usedBandwidth(N1, N2, Alloc, UsedBW) :- member((N1,N2,UsedBW), Alloc).
usedBandwidth(N1, N2, Alloc, 0) :- \+ member((N1,N2,_), Alloc).

intermediateNodes([_|Rest], Middle) :- append(Middle, [_], Rest).

sortPaths(Order, (FlowId1, _, (_, Reliability1, _, _)), (FlowId2, _, (_, Reliability2, _, _))) :-
    ( FlowId1 @< FlowId2 -> Order = '<'
    ; FlowId1 @> FlowId2 -> Order = '>'
    ; Reliability1 > Reliability2 -> Order = '<'
    ; Reliability1 < Reliability2 -> Order = '>'
    ; Order = '='
    ).
