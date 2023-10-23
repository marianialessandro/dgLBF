:-['../glbf.pl'].

:- set_prolog_flag(stack_limit, 128 000 000 000).
:- set_prolog_flag(last_call_optimisation, true).

sim_glbf(Out, Alloc, Infs, Time) :-
    statistics(inferences, I1),
        statistics(cputime, T1),
            glbf(Out, Alloc), 
        statistics(cputime, T2),
    statistics(inferences, I2), 

	Infs is I2 - I1 - 5,
	Time is T2 - T1.