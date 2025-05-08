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
    % 1) estrai tutti i nodi che compaiono come N1 o N2 in Alloc
    findall(N, ( member((N,_,_), Alloc)
              ; member((_,N,_), Alloc)
              ), NsDup),
    sort(NsDup, Nodes),
    % 2) per ciascun nodo somma i BW di tutti i suoi link
    findall((Node,Load),
            ( member(Node, Nodes),
              findall(BW,
                      ( member((Node,_,BW), Alloc)  % archi in uscita da node
                      ; member((_,Node,BW), Alloc)  % archi in entrata da node
                      ),
                      BWs),
              sum_list(BWs, Load)
            ),
            NodeLoads). 