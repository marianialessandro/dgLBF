solutionCost([], Cost) :-
    allNodes(Nodes),
    solutionCostEmpty(Nodes, 0, Cost),
    format('.      solutionCost: ~w~n', [Cost]).
solutionCost(NodesMetrics, Cost) :-
    allNodes(Nodes),
    solutionCost(Nodes, NodesMetrics, 0, Cost),
    format('.      solutionCost: ~w~n', [Cost]).

solutionCostEmpty([], Cost, Cost).
solutionCostEmpty([Node | Tail], OldCost, NewCost) :-
    routerCost(Node, 0, RouterCost),
    TmpCost is OldCost + RouterCost,
    solutionCostEmpty(Tail, TmpCost, NewCost).

solutionCost([], _, Cost, Cost).
solutionCost([Node | Tail], NodeMetrics, OldCost, NewCost) :-
    routerLoad(Node, NodeMetrics, Load),
    routerCost(Node, Load, RouterCost), 
    TmpCost is OldCost + RouterCost, 
    solutionCost(Tail, NodeMetrics, TmpCost, NewCost).
