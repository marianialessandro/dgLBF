:- use_module(library(ansi_term)).

group_and_compute([(FlowId, PathId, PathInfo) | Rest], [(FlowId, OverallReliability, Paths) | GroupedRest]) :-
    extract_flowid(FlowId, Rest, PathsRest, Remaining),
    append([(PathId, PathInfo)], PathsRest, Paths),
    compute_overall_reliability(Paths, OverallReliability),
    group_and_compute(Remaining, GroupedRest).
group_and_compute([], []).

extract_flowid(FlowId, [(FlowId, PathId, PathInfo) | Rest], [(PathId, PathInfo) | Paths], Remaining) :-
    extract_flowid(FlowId, Rest, Paths, Remaining).
extract_flowid(FlowId, [(OtherFlowId, PathId, PathInfo) | Rest], Paths, [(OtherFlowId, PathId, PathInfo) | Remaining]) :-
    FlowId \= OtherFlowId, extract_flowid(FlowId, Rest, Paths, Remaining).
extract_flowid(_, [], [], []).

compute_overall_reliability([(_, (_, Reliability, _, _)) | Paths], OverallReliability) :-
    compute_overall_reliability(Paths, PartialReliability),
    OverallReliability is PartialReliability * Reliability.
compute_overall_reliability([], 1).

% Pretty print the grouped data
pretty_print([(FlowId, OverallReliability, Paths) | Rest]) :-
    ansi_format([bold, fg(green)], '~w: ', [FlowId]),
    ansi_format([bold, fg(yellow)], '~2f~n', [OverallReliability]),
    print_paths(Paths),
    pretty_print(Rest).
pretty_print([]).

print_paths([(PathId, (Path, Reliability, (MinBudget, MaxBudget), Delay)) | Rest]) :-
    ansi_format([fg(cyan)], '  PathId: ~w~n', [PathId]),
    ansi_format([fg(magenta)], '    Path: ~w~n', [Path]),
    ansi_format([fg(blue)], '    Reliability: ',[]), format('~2f~n', [Reliability]),
    ansi_format([fg(blue)], '    MinB, MaxB: ',[]), format('(~2f, ~2f)~n', [MinBudget, MaxBudget]),
    ansi_format([fg(blue)], '    Delay: ',[]), format('~4f~n', [Delay]),
    print_paths(Rest).
print_paths([]).

prettyPrint(Paths) :-
    group_and_compute(Paths, Grouped),
    pretty_print(Grouped).