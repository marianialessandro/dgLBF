nodeBandwidths(Node, Alloc, BWs) :-
    findall(BW, inOutBw(Node,Alloc,BW), BWs). 

inOutBw(Node, Alloc, BW) :- 
    member((Node,_,BW), Alloc) ; member((_,Node,BW), Alloc).
