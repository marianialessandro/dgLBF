allFlows(Flows) :-
    findall(FlowId, flow(FlowId, _, _), Flows).

allNodes(AllNodes) :-
    findall(Node, node(Node, _), AllNodes).