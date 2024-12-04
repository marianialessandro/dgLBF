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

sharedFirst([H|T1], [H|T2], T1, T2).
sharedFirst([H1|T1], [H2|T2], [H1|T1], [H2|T2]) :- dif(H1, H2).

sharedLast(T1, T2, NewT1, NewT2) :- 
    last(T1, L1), last(T2, L2), L1 == L2, 
    append(NewT1, [L1], T1), append(NewT2, [L2], T2).
sharedLast(T1, T2, T1, T2) :- last(T1, L1), last(T2, L2), dif(L1, L2).

sharedFirstAndLast(T1, T2, NewT1, NewT2) :- sharedFirst(T1, T2, Tmp1, Tmp2), sharedLast(Tmp1, Tmp2, NewT1, NewT2).

sortPaths(Order, (FlowId1, _, (_, Reliability1, _, _)), (FlowId2, _, (_, Reliability2, _, _))) :-
    ( FlowId1 @< FlowId2 -> Order = '<'
    ; FlowId1 @> FlowId2 -> Order = '>'
    ; Reliability1 > Reliability2 -> Order = '<'
    ; Reliability1 < Reliability2 -> Order = '>'
    ; Order = '='
    ).
