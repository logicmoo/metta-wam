:- dynamic(transpiler_predicate_store/4).
:- discontiguous transpiler_predicate_store/4.

from_prolog_args(_,X,X).
:-dynamic(pred_uses_fallback/2).
:-dynamic(pred_uses_impl/2).

pred_uses_impl(F,A):- transpile_impl_prefix(F,A,Fn),current_predicate(Fn/A).

use_interpreter:- fail.
mc_fallback_unimpl(Fn,Arity,Args,Res):- \+ use_interpreter, !,
  (pred_uses_fallback(Fn,Arity); (length(Args,Len), \+ pred_uses_impl(Fn,Len))),!,
    get_operator_typedef_props(_,Fn,Arity,Types,_RetType0),
    current_self(Self),
    maybe_eval(Self,Types,Args,NewArgs),
    [Fn|NewArgs]=Res.

%mc_fallback_unimpl(Fn,_Arity,Args,Res):-  u_assign([Fn|Args], Res).

maybe_eval(_Self,_Types,[],[]):-!.
maybe_eval(Self,[T|Types],[A|Args],[N|NewArgs]):-
    into_typed_arg(30,Self,T,A,N),
    maybe_eval(Self,Types,Args,NewArgs).


%'mc_2__:'(Obj, Type, [':',Obj, Type]):- current_self(Self), sync_type(10, Self, Obj, Type). %freeze(Obj, get_type(Obj,Type)),!.
%sync_type(D, Self, Obj, Type):- nonvar(Obj), nonvar(Type), !, arg_conform(D, Self, Obj, Type).
%sync_type(D, Self, Obj, Type):- nonvar(Obj), var(Type), !, get_type(D, Self, Obj, Type).
%sync_type(D, Self, Obj, Type):- nonvar(Type), var(Obj), !, set_type(D, Self, Obj, Type). %, freeze(Obj, arg_conform(D, Self, Obj, Type)).
%sync_type(D, Self, Obj, Type):- freeze(Type,sync_type(D, Self, Obj, Type)), freeze(Obj, sync_type(D, Self, Obj, Type)),!.

transpiler_predicate_store('get-type', 2, [x(noeval,eager,[])], x(doeval,eager,[])).
%'mc_1__get-type'(Obj,Type) :-  attvar(Obj),current_self(Self),!,trace,get_attrs(Obj,Atts),get_type(10, Self, Obj,Type).
'mc_1__get-type'(Obj,Type) :- current_self(Self), !, get_type(10, Self, Obj,Type).

%%%%%%%%%%%%%%%%%%%%% if

transpiler_predicate_store('if', 4, [x(doeval,eager,[]),x(doeval,lazy,[]),x(doeval,lazy,[])], x(doeval,lazy,[])).
'mc_3__if'(If,Then,Else,Result) :- (If*->Result=Then;Result=Else).
transpiler_predicate_store('if', 3, [x(doeval,eager,[]),x(doeval,lazy,[])], x(doeval,lazy,[])).
'mc_2__if'(If,Then,Result) :- (If*->Result=Then;fail).

compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Convert, Converted, ConvertedN) :-
  Convert = ['if',Cond,Then,Else],!,
  f2p(HeadIs,LazyVars,CondResult,CondResultN,LazyRetCond,Cond,CondCode,CondCodeN),
  lazy_impedance_match(LazyRetCond,x(doeval,eager,[]),CondResult,CondCode,CondResultN,CondCodeN,CondResult1,CondCode1),
  append(CondCode1,[[native(is_True),CondResult1]],If),
  compile_test_then_else(HeadIs,RetResult,RetResultN,LazyVars,LazyEval,If,Then,Else,Converted, ConvertedN).

compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Convert, Converted, ConvertedN) :-
  Convert = ['if',Cond,Then],!,
  f2p(HeadIs,LazyVars,CondResult,CondResultN,LazyRetCond,Cond,CondCode,CondCodeN),
  lazy_impedance_match(LazyRetCond,x(doeval,eager,[]),CondResult,CondCode,CondResultN,CondCodeN,CondResult1,CondCode1),
  append(CondCode1,[[native(is_True),CondResult1]],If),
  compile_test_then_else(HeadIs,RetResult,RetResultN,LazyVars,LazyEval,If,Then,'Empty',Converted, ConvertedN).

compile_test_then_else(HeadIs,RetResult,RetResultN,LazyVars,LazyEval,If,Then,Else,Converted, ConvertedN):-
  f2p(HeadIs,LazyVars,ThenResult,ThenResultN,ThenLazyEval,Then,ThenCode,ThenCodeN),
  f2p(HeadIs,LazyVars,ElseResult,ElseResultN,ElseLazyEval,Else,ElseCode,ElseCodeN),
  arg_properties_widen(ThenLazyEval,ElseLazyEval,LazyEval),
  %(Else=='Empty' -> LazyEval=ThenLazyEval ; arg_properties_widen(ThenLazyEval,ElseLazyEval,LazyEval)),
  %lazy_impedance_match(ThenLazyEval,LazyEval,ThenResult,ThenCode,ThenResultN,ThenCodeN,ThenResult1,ThenCode1),
  %lazy_impedance_match(ElseLazyEval,LazyEval,ElseResult,ElseCode,ElseResultN,ElseCodeN,ElseResult1,ElseCode1),
  % cannnot use add_assignment here as might not want to unify ThenResult and ElseResult
  append(ThenCode,[[assign,RetResult,ThenResult]],T),
  append(ElseCode,[[assign,RetResult,ElseResult]],E),
  Converted=[[prolog_if,If,T,E]],
  append(ThenCodeN,[[assign,RetResultN,ThenResultN]],TN),
  append(ElseCodeN,[[assign,RetResultN,ElseResultN]],EN),
  ConvertedN=[[prolog_if,If,TN,EN]].

%%%%%%%%%%%%%%%%%%%%% case. NOTE: there is no library equivalent for this, as various parts of the structure have to be lazy

compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Convert,Converted,ConvertedN) :-
   Convert=['case',Value,Cases],!,
   f2p(HeadIs,LazyVars,ValueResult,ValueResultN,LazyRetValue,Value,ValueCode,ValueCodeN),
   lazy_impedance_match(LazyRetValue,x(doeval,eager,[]),ValueResult,ValueCode,ValueResultN,ValueCodeN,ValueResult1,ValueCode1),
   ValueCode1a=[[prolog_if,ValueCode1,[[assign,ValueResult1a,ValueResult1]],[[assign,ValueResult1a,'Empty']]]],
   compile_flow_control_case(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,ValueResult1a,Cases,Converted0,Converted0N),
   append(ValueCode1a,Converted0,Converted),
   append(ValueCode1a,Converted0N,ConvertedN).

compile_flow_control_case(_,_,RetResult,RetResultN,_,_,[],[[assign,RetResult,'Empty']],[[assign,RetResultN,'Empty']]) :- !.
compile_flow_control_case(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,ValueResult,[[Match,Target]|Rest],Converted,ConvertedN) :-
   f2p(HeadIs,LazyVars,MatchResult,MatchResultN,LazyRetMatch,Match,MatchCode,MatchCodeN),
   lazy_impedance_match(LazyRetMatch,x(doeval,eager,[]),MatchResult,MatchCode,MatchResultN,MatchCodeN,MatchResult1,MatchCode1),
   f2p(HeadIs,LazyVars,TargetResult,TargetResultN,LazyEval0,Target,TargetCode,TargetCodeN),
   compile_flow_control_case(HeadIs,LazyVars,RestResult,RestResultN,LazyEval1,ValueResult,Rest,RestCode,RestCodeN),
   arg_properties_widen(LazyEval0,LazyEval1,LazyEval),
   append(TargetCode,[[assign,RetResult,TargetResult]],T),
   append(RestCode,[[assign,RetResult,RestResult]],R),
   append(MatchCode1,[[prolog_if,[[prolog_match,ValueResult,MatchResult1]],T,R]],Converted),
   append(TargetCodeN,[[assign,RetResultN,TargetResultN]],TN),
   append(RestCodeN,[[assign,RetResultN,RestResultN]],RN),
   append(MatchCode1,[[prolog_if,[[prolog_match,ValueResult,MatchResult1]],TN,RN]],ConvertedN).

/*
compile_flow_control(HeadIs,LazyVars,RetResult,LazyEval,Convert, Converted) :-
  Convert = ['case', Eval, CaseList],!,
  f2p(HeadIs, LazyVars, Var, x(doeval,eager,[]), Eval, CodeCanFail),
  case_list_to_if_list(Var, CaseList, IfList, [empty], IfEvalFails),
  compile_test_then_else(RetResult, LazyVars, LazyEval, CodeCanFail, IfList, IfEvalFails, Converted).

case_list_to_if_list(_Var, [], [empty], EvalFailed, EvalFailed) :-!.
case_list_to_if_list(Var, [[Pattern, Result] | Tail], Next, _Empty, EvalFailed) :-
    (Pattern=='Empty'; Pattern=='%void%'), !, % if the case Failed
    case_list_to_if_list(Var, Tail, Next, Result, EvalFailed).
case_list_to_if_list(Var, [[Pattern, Result] | Tail], Out, IfEvalFailed, EvalFailed) :-
    case_list_to_if_list(Var, Tail, Next, IfEvalFailed, EvalFailed),
    Out = ['if', [metta_unify, Var, Pattern], Result, Next].
*/

%%%%%%%%%%%%%%%%%%%%% arithmetic

transpiler_predicate_store('+', 3, [x(doeval,eager,[number]), x(doeval,eager,[number])], x(doeval,eager,[number])).
'mc_2__+'(A,B,R) :- number(A),number(B),!,plus(A,B,R).
'mc_2__+'(A,B,['+',A,B]).

transpiler_predicate_store('-', 3, [x(doeval,eager,[number]), x(doeval,eager,[number])], x(doeval,eager,[number])).
'mc_2__-'(A,B,R) :- number(A),number(B),!,plus(B,R,A).
'mc_2__-'(A,B,['-',A,B]).

transpiler_predicate_store('*', 3, [x(doeval,eager,[number]), x(doeval,eager,[number])], x(doeval,eager,[number])).
'mc_2__*'(A,B,R) :- number(A),number(B),!,R is A*B.
'mc_2__*'(A,B,['*',A,B]).

%%%%%%%%%%%%%%%%%%%%% logic

%transpiler_predicate_store('and', 3, [x(doeval,eager,[boolean]), x(doeval,eager,[boolean])], x(doeval,eager,[boolean])).
%mc_2__and(A,B,B) :- atomic(A), A\=='False', A\==0, !.
%mc_2__and(_,_,'False').

%transpiler_predicate_store('or', 3, [x(doeval,eager), x(doeval,eager,[boolean])], x(doeval,eager,[boolean])).
%mc_2__or(A,B,B):- (\+ atomic(A); A='False'; A=0), !.
%mc_2__or(_,_,'True').

transpiler_predicate_store('and', 3, [x(doeval,eager,[boolean]), x(doeval,lazy,[boolean])], x(doeval,eager,[boolean])).
mc_2__and(A,B,C) :- atomic(A), A\=='False', A\==0, !, as_p1_exec(B,C).
mc_2__and(_,_,'False').
compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Convert, Converted, ConvertedN) :-
  Convert = ['and',A,B],!,
  LazyEval=x(doeval,eager,[boolean]),
  % eval case
  f2p(HeadIs,LazyVars,AResult,AResultN,LazyRetA,A,ACode,ACodeN),
  lazy_impedance_match(LazyRetA,x(doeval,eager,[boolean]),AResult,ACode,AResultN,ACodeN,AResult1,ACode1),
  f2p(HeadIs,LazyVars,BResult,BResultN,LazyRetB,B,BCode,BCodeN),
  lazy_impedance_match(LazyRetB,x(doeval,eager,[boolean]),BResult,BCode,BResultN,BCodeN,BResult1,BCode1),
  append(ACode1,[[native(is_True),AResult1]],ATest),
  append(BCode1,[[assign,RetResult,BResult1]],BTest),
  CodeIf=[[prolog_if,ATest,BTest,[[assign,RetResult,'False']]]],
  Converted=CodeIf,
  % noeval case
  maplist(f2p(HeadIs,LazyVars), _RetResultsParts, RetResultsPartsN, LazyResultParts, Convert, _ConvertedParts, ConvertedNParts),
  f2p_do_group(x(noeval,eager,[]),LazyResultParts,RetResultsPartsN,NoEvalRetResults,ConvertedNParts,NoEvalCodeCollected),
  assign_or_direct_var_only(NoEvalCodeCollected,RetResultN,list(NoEvalRetResults),ConvertedN).

transpiler_predicate_store('or', 3, [x(doeval,eager,[boolean]), x(doeval,lazy,[boolean])], x(doeval,eager,[boolean])).
mc_2__or(A,B,C):- (\+ atomic(A); A='False'; A=0), !, as_p1_exec(B,C).
mc_2__or(_,_,'True').
compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Convert, Converted, ConvertedN) :-
  Convert = ['or',A,B],!,
  LazyEval=x(doeval,eager,[boolean]),
  % eval case
  f2p(HeadIs,LazyVars,AResult,AResultN,LazyRetA,A,ACode,ACodeN),
  lazy_impedance_match(LazyRetA,x(doeval,eager,[boolean]),AResult,ACode,AResultN,ACodeN,AResult1,ACode1),
  f2p(HeadIs,LazyVars,BResult,BResultN,LazyRetB,B,BCode,BCodeN),
  lazy_impedance_match(LazyRetB,x(doeval,eager,[boolean]),BResult,BCode,BResultN,BCodeN,BResult1,BCode1),
  append(ACode1,[[native(is_True),AResult1]],ATest),
  append(BCode1,[[assign,RetResult,BResult1]],BTest),
  CodeIf=[[prolog_if,ATest,[[assign,RetResult,'True']],BTest]],
  Converted=CodeIf,
  % noeval case
  maplist(f2p(HeadIs,LazyVars), _RetResultsParts, RetResultsPartsN, LazyResultParts, Convert, _ConvertedParts, ConvertedNParts),
  f2p_do_group(x(noeval,eager,[]),LazyResultParts,RetResultsPartsN,NoEvalRetResults,ConvertedNParts,NoEvalCodeCollected),
  assign_or_direct_var_only(NoEvalCodeCollected,RetResultN,list(NoEvalRetResults),ConvertedN).

transpiler_predicate_store('not', 2, [x(doeval,eager,[boolean])], x(doeval,eager,[boolean])).
mc_1__not(A,'False') :- atomic(A), A\=='False', A\==0, !.
mc_1__not(_,'True').

%%%%%%%%%%%%%%%%%%%%% comparison

% not sure about the signature for this one
transpiler_predicate_store('==', 3, [x(doeval,eager,[]), x(doeval,eager,[])], x(doeval,eager,[boolean])).
'mc_2__=='(A,B,'True') :- A==B,!.
'mc_2__=='(_,_,'False').

transpiler_predicate_store('<', 3, [x(doeval,eager,[number]), x(doeval,eager,[number])], x(doeval,eager,[boolean])).
'mc_2__<'(A,B,R) :- number(A),number(B),!,(A<B -> R='True' ; R='False').
'mc_2__<'(A,B,['<',A,B]).

transpiler_predicate_store('>', 3, [x(doeval,eager,[number]), x(doeval,eager,[number])], x(doeval,eager,[boolean])).
'mc_2__>'(A,B,R) :- number(A),number(B),!,(A>B -> R='True' ; R='False').
'mc_2__>'(A,B,['>',A,B]).

transpiler_predicate_store('>=', 3, [x(doeval,eager,[number]), x(doeval,eager,[number])], x(doeval,eager,[boolean])).
'mc_2__>='(A,B,R) :- number(A),number(B),!,(A>=B -> R='True' ; R='False').
'mc_2__>='(A,B,['>=',A,B]).

transpiler_predicate_store('<=', 3, [x(doeval,eager,[number]), x(doeval,eager,[number])], x(doeval,eager,[boolean])).
'mc_2__<='(A,B,R) :- number(A),number(B),!,(A=<B -> R='True' ; R='False'). % note that Prolog has a different syntax '=<'
'mc_2__<='(A,B,['<=',A,B]).

%%%%%%%%%%%%%%%%%%%%% lists

transpiler_predicate_store('car-atom', 2, [x(noeval,eager,[list])], x(noeval,eager,[])).
'mc_1__car-atom'([H|_],H).

transpiler_predicate_store('cdr-atom', 2, [x(noeval,eager,[list])], x(noeval,eager,[list])).
'mc_1__cdr-atom'([_|T],T).

transpiler_predicate_store('cons-atom', 3, [x(noeval,eager,[]), x(noeval,eager,[list])], x(noeval,eager,[list])).
'mc_2__cons-atom'(A,B,[A|B]).

transpiler_predicate_store('decons-atom', 2,  [x(noeval,eager,[list])], x(noeval,eager,[list])).
'mc_1__decons-atom'([A|B],[A,B]).

%%%%%%%%%%%%%%%%%%%%% set

lazy_member(P,R2) :- as_p1_exec(R2,P).

transpiler_predicate_store(subtraction, 3, [x(doeval,lazy,[]),x(doeval,lazy,[])], x(doeval,eager,[])).
'mc_2__subtraction'(P1,P2,S) :- as_p1_exec(P1,S), \+ lazy_member(S,P2).

transpiler_predicate_store(union, 3, [x(doeval,lazy,[]),x(doeval,lazy,[])], x(doeval,eager,[])).
'mc_2__union'(U1,U2,R) :- 'mc_2__subtraction'(U1,U2,R) ; as_p1_exec(U2,R).

%%%%%%%%%%%%%%%%%%%%% superpose, collapse

transpiler_predicate_store(superpose, 2, [x(doeval,eager,[])], x(doeval,eager,[])).
'mc_1__superpose'(S,R) :- member(R,S).

transpiler_predicate_store(collapse, 2, [x(doeval,lazy,[])], x(doeval,eager,[])).
'mc_1__collapse'(ispu(X),[X]).
'mc_1__collapse'(ispuU(Ret,Code),R) :- fullvar(Ret),!,findall(Ret,Code,R).
'mc_1__collapse'(ispuU(X,true),[X]) :- !.
'mc_1__collapse'(ispuU(A,Code),X) :- atom(A),findall(_,Code,X),maplist(=(A),X).
'mc_1__collapse'(ispen(Ret,Code,_),R) :- fullvar(Ret),!,findall(Ret,Code,R).
'mc_1__collapse'(ispeEn(X,true,_),[X]) :- !.
'mc_1__collapse'(ispeEn(A,Code,_),X) :- atom(A),findall(_,Code,X),maplist(=(A),X).
'mc_1__collapse'(ispeEnN(Ret,Code,_,_),R) :- fullvar(Ret),!,findall(Ret,Code,R).
'mc_1__collapse'(ispeEnN(X,true,_,_),[X]) :- !.
'mc_1__collapse'(ispeEnN(A,Code,_,_),X) :- atom(A),findall(_,Code,X),maplist(=(A),X).
'mc_1__collapse'(ispeEnNC(Ret,Code,_,_,Common),R) :- fullvar(Ret),!,findall(Ret,(Common,Code),R).
'mc_1__collapse'(ispeEnNC(A,Code,_,_,Common),X) :- atom(A),findall(_,(Common,Code),X),maplist(=(A),X).
%'mc_1__collapse'(is_p1(_Type,_Expr,Code,Ret),R) :- fullvar(Ret),!,findall(Ret,Code,R).
%'mc_1__collapse'(is_p1(_Type,_Expr,true,X),[X]) :- !.
%'mc_1__collapse'(is_p1(_,Code,Ret),R) :- fullvar(Ret),!,findall(Ret,Code,R).
%'mc_1__collapse'(is_p1(_,true,X),[X]).
%'mc_1__collapse'(is_p1(Code,Ret),R) :- fullvar(Ret),!,findall(Ret,Code,R).
%'mc_1__collapse'(is_p1(true,X),[X]).

%%%%%%%%%%%%%%%%%%%%% spaces

transpiler_predicate_store('add-atom', 3, [x(doeval,eager,[]), x(noeval,eager,[])], x(doeval,eager,[])).
'mc_2__add-atom'(Space,PredDecl,[]) :- 'add-atom'(Space,PredDecl).

transpiler_predicate_store('remove-atom', 3, [x(doeval,eager,[]), x(noeval,eager,[])], x(doeval,eager,[])).
'mc_2__remove-atom'(Space,PredDecl,[]) :- 'remove-atom'(Space,PredDecl).

transpiler_predicate_store('get-atoms', 2, [x(noeval,eager,[])], x(noeval,eager,[])).
'mc_1__get-atoms'(Space,Atoms) :- metta_atom(Space, Atoms).

% This allows match to supply hits to the correct metta_atom/2 (Rather than sending a variable
match_pattern(Space, Pattern):-
    if_t(compound(Pattern),
       (functor(Pattern,F,A,Type), functor(Atom,F,A,Type))),
    metta_atom(Space, Atom), Atom=Pattern.

transpiler_predicate_store(match, 4, [x(doeval,eager,[]), x(doeval,eager,[]), x(doeval,lazy,[])], x(doeval,eager,[])).
'mc_3__match'(Space,[','|Patterns],P1,Ret) :- !,(maplist(match_aux(Space),Patterns) -> as_p1_exec(P1,Ret) ; fail).
'mc_3__match'(Space,Pattern,P1,Ret) :- match_pattern(Space, Atom),Atom=Pattern,as_p1_exec(P1,Ret).
%'mc_3__match'(Space,Pattern,P1,Ret) :- match_pattern(Space, Atom),format("match1 ~w: ~w:\n",[Pattern,Atom]),Atom=Pattern,as_p1_exec(P1,Ret),format("match2 ~w:\n",[Ret]),trace.
%transpiler_predicate_store(match, 4, [x(doeval,eager,[]), x(doeval,lazy,[]), x(doeval,lazy,[])], x(doeval,eager,[])).
%'mc_3__match'(Space,Pattern,P1,Ret) :- match_pattern(Space, Atom),as_p1_exec(Pattern,Atom),as_p1_exec(P1,Ret).

match_aux(Space,Pattern) :- 'mc_3__match'(Space,Pattern,ispu(true),true).

% unify calls pattern matching if arg1 is a space
unify_pattern(Space,Pattern):- is_metta_space(Space),!, match_pattern(Space, Pattern).
% otherwise calls prolog unification (with occurs check later)
unify_pattern(Atom, Pattern):- metta_unify(Atom, Pattern).

metta_unify(Atom, Pattern):- Atom=Pattern.

% TODO FIXME: sort out the difference between unify and match
transpiler_predicate_store(unify, 4, [x(doeval,eager,[]), x(doeval,eager,[]), x(doeval,lazy,[])], x(doeval,eager,[])).
'mc_3__unify'(Space,Pattern,P1,Ret) :- unify_pattern(Space, Atom),Atom=Pattern,as_p1_exec(P1,Ret).

transpiler_predicate_store(unify, 5, [x(doeval,eager,[]), x(doeval,eager,[]), x(doeval,lazy,[]), x(doeval,lazy,[])], x(doeval,eager,[])).
'mc_4__unify'(Space,Pattern,Psuccess,PFailure,RetVal) :-
    (unify_pattern(Space,Pattern) -> as_p1_exec(Psuccess,RetVal) ; as_p1_exec(PFailure,RetVal)).

%%%%%%%%%%%%%%%%%%%%% variable arity functions

transpiler_predicate_nary_store(progn, 0, [], x(doeval,eager,[]), x(doeval,eager,[])).
'mc_n_0__progn'(List,Ret) :- append(_,[Ret],List).

%%%%%%%%%%%%%%%%%%%%% misc

transpiler_predicate_store(time, 2, [x(doeval,lazy,[])], x(doeval,eager,[])).
'mc_1__time'(P,Ret) :- wtime_eval(as_p1_exec(P,Ret)).

transpiler_predicate_store(empty, 1, [], x(doeval,eager,[])).
'mc_0__empty'(_) :- fail.

transpiler_predicate_store('eval', 2, [x(noeval,eager,[])], x(doeval,eager,[])).
'mc_1__eval'(X,R) :- transpile_eval(X,R).

transpiler_predicate_store('get-metatype', 2, [x(noeval,eager,[])], x(doeval,eager,[])).
'mc_1__get-metatype'(X,Y) :- 'get-metatype'(X,Y). % use the code in the interpreter for now

transpiler_predicate_store('println!', 2, [x(doeval,eager,[])], x(doeval,eager,[])).
'mc_1__println!'(X,[]) :- println_impl(X).

transpiler_predicate_store('stringToChars', 2, [x(doeval,eager,[])], x(doeval,eager,[])).
'mc_1__stringToChars'(S,C) :- string_chars(S,C).

transpiler_predicate_store('charsToString', 2, [x(doeval,eager,[])], x(doeval,eager,[])).
'mc_1__charsToString'(C,S) :- string_chars(S,C).

transpiler_predicate_store('assertEqual', 3, [x(doeval,lazy,[]),x(noeval,lazy,[])], x(doeval,eager,[])).
'mc_2__assertEqual'(A,B,C) :-
   loonit_assert_source_tf_empty(
        ['assertEqual',A,B],AA,BB,
        ('mc_1__collapse'(A,AA),
         'mc_1__collapse'(B,BB)),
         equal_enough_for_test_renumbered_l(strict_equals_allow_vn,AA,BB), C).

transpiler_predicate_store('assertEqualToResult', 3, [x(doeval,lazy,[]),x(noeval,eager,[])], x(doeval,eager,[])).
'mc_2__assertEqualToResult'(A,B,C) :-
   loonit_assert_source_tf_empty(
        ['assertEqualToResult',A,B],AA,B,
        ('mc_1__collapse'(A,AA)),
         equal_enough_for_test_renumbered_l(strict_equals_allow_vn,AA,B), C).

%transpiler_predicate_store('assertEqualToResult', 3, [x(doeval,lazy,[]),x(doeval,eager,[])], x(doeval,eager,[])).
%'mc_2__assertEqualToResult'(A,B,C) :- 'mc_1__collapse'(A,A2),u_assign([assertEqualToResult,A2,[B]],C).

transpiler_predicate_store('prolog-trace', 1, [], x(doeval,eager,[])).
'mc_0__prolog-trace'([]) :- trace.

transpiler_predicate_store('quote', 2, [x(noeval,eager,[])], x(noeval,eager,[])).
'mc_1__quote'(A,['quote',A]).
compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyRetQuoted,Convert, QuotedCode1a, QuotedCode1N) :-
  Convert = ['quote',Quoted],!,
  f2p(HeadIs,LazyVars,QuotedResult,QuotedResultN,LazyRetQuoted,Quoted,QuotedCode,QuotedCodeN),
  lazy_impedance_match(LazyRetQuoted,x(noeval,eager,[]),QuotedResult,QuotedCode,QuotedResultN,QuotedCodeN,QuotedResult1,QuotedCode1),
  QuotedResult1a=['quote',QuotedResult1],
  lazy_impedance_match(x(noeval,eager,[]),LazyRetQuoted,QuotedResult1a,QuotedCode1,QuotedResult1a,QuotedCode1,QuotedResult2,QuotedCode2),
  assign_or_direct_var_only(QuotedCode2,RetResult,QuotedResult2,QuotedCode1a),
  assign_or_direct_var_only(QuotedCode2,RetResultN,QuotedResult2,QuotedCode1N).
