:- dynamic cross/1.
:- dynamic naught/1.
:- dynamic empty/1.
:- dynamic m/1.
:- dynamic n/1.

m(3).
n(3).
empty(0).
naught(1).
cross(2).


loss_score(-1).
win_score(1).

min(X, Y, X) :- X < Y,!. 
min(_, Y, Y). 

max(X, Y, X) :- X > Y,!. 
max(_, Y, Y). 

mydiv(Dividend, Divisor, Quotient) :-
    Quotient is Dividend // Divisor.

nth0(0, [X|_], X).
nth0(N, [_|T], X) :-
    N > 0,
    N1 is N - 1,
    nth0(N1, T, X).

    
grid_index(Index, I, J) :-
    n(N),
    (var(Index) ->
        Index is N*I + J
    ;
        mydiv(Index, N, I),
        J is Index mod N
    ).

replace_at(Index, List, NewElem, Result) :-
    nth0(Index, List, _, Rest),
    nth0(Index, Result, NewElem, Rest).

compare_tuples((X1, Y1), (X2, Y2)) :-
    (X1 > X2 ; (X1 = X2, Y1 > Y2)).

compare_tuples0((X1, _), (X2, _)) :- X1 > X2.

compare_tuples1((_, Y1), (_, Y2)) :- Y1 > Y2.

fmax_list([H|T], Comparator, Max) :-
    fmax_list(T, Comparator, H, Max), !.

fmax_list([], _, Max, Max).

fmax_list([H|T], Comparator, CurrentMax, Max) :-
    call(Comparator, H, CurrentMax),
    fmax_list(T, Comparator, H, Max).  

fmax_list([_|T], Comparator, CurrentMax, Max) :-
    fmax_list(T, Comparator, CurrentMax, Max). 

set_board_value(BoardValue, Num) :-
    ToRemove =.. [BoardValue, _],
    Fact =.. [BoardValue, Num],
    retractall(ToRemove),
    assertz(Fact). 

set_dimensions(M, N) :- 
    set_board_value(m, M), 
    set_board_value(n, N).

opponent(Player, Opponent) :- cross(Player), naught(Opponent).
opponent(Player, Opponent) :- naught(Player), cross(Opponent).

opposite_comparator(min, max).
opposite_comparator(max, min).

%replace with [P | Args]
apply(PArgs, AdditionalArgs) :-
    append(PArgs, AdditionalArgs, FullPArgs),
    Call =.. FullPArgs,
    call(Call).

for_each(PArgs, List, AccIn, AccOut) :- 
    for_each_util(PArgs, List, 0, AccIn, AccOut).

for_each_util(_, [], _,  Acc, Acc).
for_each_util(PArgs, [Elem|Elems], Index, AccIn, AccOut) :-
    apply(PArgs, [Elem, Index, AccIn, AccNext]),
    NextIndex is Index + 1,
    for_each_util(PArgs, Elems, NextIndex, AccNext, AccOut),!.

fmap_list(_, [], []).
fmap_list(PArgs, [X|Xs], [Y|Ys]) :-
    apply(PArgs, [X, Y]),
    fmap_list(PArgs, Xs, Ys).

find_win_sequence(OrigBoard, NextIndexPArgs, IndTripletCheckPArgs, Elem, Index0, AccIn, AccNext) :- 
    (
        empty(Empty),
        Elem \= Empty,
        apply(NextIndexPArgs, [Index0, Index1]),
        apply(NextIndexPArgs, [Index1, Index2]),
        apply(IndTripletCheckPArgs, [Index0, Index1, Index2]),
        nth0(Index0, OrigBoard, Elem),
        nth0(Index1, OrigBoard, Elem),
        nth0(Index2, OrigBoard, Elem),
        AccNext = [[Index0, Index1, Index2] | AccIn]
    );
    AccNext = AccIn.

shift_rght(Index, NxtIndex) :- NxtIndex is 1 + Index.
shift_down(Index, NxtIndex) :- n(N), NxtIndex is N + Index.
shift_diag(Index, NxtIndex) :- n(N), NxtIndex is 1 + N + Index.

within_one_row(Index0, Index1, Index2) :-
    grid_index(Index0, I, _),
    grid_index(Index1, I, _),
    grid_index(Index2, I, _).

within_one_col(Index0, Index1, Index2) :-
    grid_index(Index0, _, J),
    grid_index(Index1, _, J),
    grid_index(Index2, _, J).

within_one_dgn(_, _, _) :- true.

partial_victory_sequences(Board, ShiftPArgs, CheckIndexTripletPArgs, Sequences) :-
    PArgs = [find_win_sequence, Board, ShiftPArgs, CheckIndexTripletPArgs],
    for_each(PArgs, Board, [], Sequences).

all_victory_rows(Board, Rows) :-
    partial_victory_sequences(Board, [shift_rght], [within_one_row], Rows).

all_victory_cols(Board, Cols) :-
    partial_victory_sequences(Board, [shift_down], [within_one_col], Cols).

all_victory_dgns(Board, Dgns) :-
    partial_victory_sequences(Board, [shift_diag], [within_one_dgn], Dgns).

all_victory_sequences(Board, Sequences) :-
    all_victory_rows(Board, Rows),
    all_victory_cols(Board, Cols),
    all_victory_dgns(Board, Dgns),
    append(Rows, Cols, RC),
    append(RC, Dgns, Sequences).

is_victory_board(Board, Winner) :- 
    all_victory_sequences(Board, VictorySequences),
    length(VictorySequences, L),
    L > 0,
    nth0(0, VictorySequences, [WinIndex | _]),
    nth0(WinIndex, Board, Winner), !.

get_score(CurrPlayer, Winner, Score) :- CurrPlayer =:= Winner, win_score(Score),!.
get_score(_, _, Score) :- loss_score(Score).

process_next_board(NextBoard, CurrPlayer, _, _, Gain) :- 
    is_victory_board(NextBoard, Winner),
    get_score(CurrPlayer, Winner, Gain),!.
process_next_board(NextBoard, CurrPlayer, Comparator, AccIn, Gain) :-
    opponent(CurrPlayer, Opponent),
    opposite_comparator(Comparator, OppositeComparator),
    PArgs = [eval_unit_gain, OppositeComparator, NextBoard, Opponent],
    %writeln(PArgs),
    for_each(PArgs, NextBoard, AccIn, Gain),!.

eval_unit_gain(Comparator, Board, CurrPlayer, Elem, Index, AccIn, AccNext) :- 
    empty(Elem),
    %write(Index), write(': '),
    replace_at(Index, Board, CurrPlayer, NextBoard),
    process_next_board(NextBoard, CurrPlayer, Comparator, AccIn, Gain),
    call(Comparator, AccIn, Gain, Minmax), 
    %write('min('), write((AccIn, Gain)), write(') = '),writeln(Minmax),
    AccNext = Minmax,!.
eval_unit_gain(_, _, _, _, _, AccIn, AccIn).

process_unit(Comparator, Board, CurrPlayer, Elem, Index, AccIn, AccNext) :-
    empty(Elem),
    loss_score(LossScore),
    EmptyAccIn is LossScore - 1,
    eval_unit_gain(Comparator, Board, CurrPlayer, Elem, Index, EmptyAccIn, Gain),
    AccNext = [(Gain, Index) | AccIn].
process_unit(_, _, _, _, _, AccIn, AccIn).

decide(UnitProcessor, Board, CurrPlayer, Index) :- 
    PArgs = [UnitProcessor, Board, CurrPlayer],
    for_each(PArgs, Board, [], Tuples),
    fmax_list(Tuples, compare_tuples0, Index).

minimax_unit(Board, CurrPlayer, Elem, Index, AccIn, AccNext) :-
    process_unit(max, Board, CurrPlayer, Elem, Index, AccIn, AccNext).
maximin_unit(Board, CurrPlayer, Elem, Index, AccIn, AccNext) :-
    process_unit(min, Board, CurrPlayer, Elem, Index, AccIn, AccNext).

minimax(Board, CurrPlayer, Index) :- decide(minimax_unit, Board, CurrPlayer, Index).
maximin(Board, CurrPlayer, Index) :- decide(maximin_unit, Board, CurrPlayer, Index).

next_turn(_, CurrPlayer, -1) :- empty(CurrPlayer).
next_turn(Board, CurrPlayer, Index) :- minimax(Board, CurrPlayer, Index).
