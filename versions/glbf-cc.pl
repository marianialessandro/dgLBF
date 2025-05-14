:-['./glbf-plain.pl'].
:-['../metrics/router_energy.pl'].

% ————————————————————————————————————————————————————————————————
% glbf_with_node_carbon_and_costs(-Out, -Alloc, -NodeCarbonCost)
%
% Out             = lista dei flow con percorso, budget e delay (come per glbf/2)
% Alloc           = lista (N1,N2,UsedBW) per ogni link usato
% NodeCarbonCost  = lista (Node, Load, CarbonEmissions, EnergyCost)
%                   Load            = somma di UsedBW sui link incidenti a Node
%                   CarbonEmissions = EnergyUsed * Alpha
%                   EnergyCost      = EnergyUsed * CE
% ————————————————————————————————————————————————————————————————
glbf_with_node_carbon_and_costs(Out, Alloc, NodeCarbonCost) :-
    glbf(Out, Alloc),                    % 1) deployment
    alloc_node_loads(Alloc, NodeLoads),  % 2) calcola il load per nodo
    findall((Node, LoadMb, Carbon, Cost),
        (
            member((Node, LoadMb), NodeLoads),
            % 1) prendi tutti i parametri dal profilo:
            energyProfile(Node, IdlePower, p(Eps,T1,T2), Alpha, CE),
            % 2) calcola l’energia consumata in un certo intervallo (es. 1 ora = 3600 s):
            LoadBps is LoadMb * 1.0e6,
            router_energy(LoadBps,
                        energyProfile(Node, IdlePower, p(Eps,T1,T2), Alpha, CE),
                        timePeriod(3600),
                        EnergyUsed),
            % 3) emissioni e costo
            Carbon is EnergyUsed * Alpha,
            Cost   is EnergyUsed * CE
        ),
        NodeCarbonCost
    ).


% router_energy trova la potenza 


glbf_with_node_carbon_and_costs :-
    % 1) esegue deployment + calcolo carbonio/costi
    glbf_with_node_carbon_and_costs(Out, Alloc, NodeCarbonCost),
    % 2) visualizza i risultati
    format('~n--- Risultati glbf_with_node_carbon_and_costs ---~n', []),
    format('Out           = ~w~n', [Out]),
    format('Alloc         = ~w~n', [Alloc]),
    format('NodeCarbonCost= ~w~n~n', [NodeCarbonCost]).


% alloc_node_loads(+Alloc, -NodeLoads)
alloc_node_loads(Alloc, NodeLoads) :-
    % 1) ottieni tutti i nodi definiti come fatti node/2
    findall(Node, node(Node, _), AllNodes),
    % 2) estrai i nodi che compaiono in Alloc come N1 o N2
    findall(N, ( member((N,_,_), Alloc)
              ; member((_,N,_), Alloc)
              ), UsedNodesDup),
    sort(UsedNodesDup, UsedNodes),
    % 3) calcola i load solo per i nodi usati in Alloc
    findall((Node,Load),
            ( member(Node, UsedNodes),
              findall(BW,
                      ( member((Node,_,BW), Alloc)
                      ; member((_,Node,BW), Alloc)
                      ),
                      BWs),
              sum_list(BWs, Load)
            ),
            UsedNodeLoads),
    % 4) aggiungi i nodi non usati, con load = 0
    findall((Node, 0),
            ( member(Node, AllNodes),
              \+ member(Node, UsedNodes)
            ),
            UnusedNodeLoads),
    % 5) combina i risultati
    append(UsedNodeLoads, UnusedNodeLoads, NodeLoads).