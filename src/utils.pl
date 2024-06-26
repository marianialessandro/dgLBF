updateCapacities([(N1,N2)|Ns], BitRate, OldAlloc, NewAlloc) :-
    select((N1,N2,OldC), OldAlloc, Rest), NewC is OldC + BitRate,
    updateCapacities(Ns, BitRate, [(N1,N2,NewC)|Rest], NewAlloc).
updateCapacities([(N1,N2)|Ns], BitRate, OldAlloc, NewAlloc) :-
    \+ member((N1,N2,_), OldAlloc),
    updateCapacities(Ns, BitRate, [(N1,N2,BitRate)|OldAlloc], NewAlloc).
updateCapacities([], _, Alloc, Alloc).

usedBandwidth(N1, N2, Alloc, UsedBW) :- member((N1,N2,UsedBW), Alloc).
usedBandwidth(N1, N2, Alloc, 0) :- \+ member((N1,N2,_), Alloc).

flatPath([(X,_)|Rest], [X|FlattenedRest]) :- flatPath(Rest, FlattenedRest).
flatPath([(C,D)], [C,D]).

middle([_|Rest], Middle) :- append(Middle, [_], Rest).
