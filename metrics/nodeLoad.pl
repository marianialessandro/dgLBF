computeNodeLoad(AllNodes, Alloc, NodeLoads) :-
    computeNodeLoadList(AllNodes, Alloc, NodeLoads).

computeNodeLoadList([Node|Rest], Alloc, [(Node,Load)|NodeLoads]) :-
    nodeBandwidths(Node, Alloc, BWs),
    sum_list(BWs, Load),
    computeNodeLoadList(Rest, Alloc, NodeLoads).
computeNodeLoadList([], _, []).

nodeBandwidths(Node, Alloc, BWs) :-
    findall(BW, inOutBw(Node,Alloc,BW), BWs). 

inOutBw(Node, Alloc, BW) :- 
    member((Node,_,BW), Alloc) ; member((_,Node,BW), Alloc).
