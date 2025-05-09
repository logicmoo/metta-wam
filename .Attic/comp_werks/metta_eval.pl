%
% post match modew
%:- style_check(-singleton).

self_eval0(X):- \+ callable(X),!.
self_eval0(X):- is_valid_nb_state(X),!.
%self_eval0(X):- string(X),!.
%self_eval0(X):- number(X),!.
%self_eval0([]).
self_eval0(X):- is_metta_declaration(X),!.
self_eval0([F|X]):- !, is_list(X),length(X,Len),!,nonvar(F), is_self_eval_l_fa(F,Len),!.
self_eval0(X):- typed_list(X,_,_),!.
%self_eval0(X):- compound(X),!.
%self_eval0(X):- is_ref(X),!,fail.
self_eval0('True'). self_eval0('False'). % self_eval0('F').
self_eval0('Empty').
self_eval0(X):- atom(X),!, \+ nb_current(X,_),!.

coerce(Type,Value,Result):- nonvar(Value),Value=[Echo|EValue], Echo == echo, EValue = [RValue],!,coerce(Type,RValue,Result).
coerce(Type,Value,Result):- var(Type), !, Value=Result, freeze(Type,coerce(Type,Value,Result)).
coerce('Atom',Value,Result):- !, Value=Result.
coerce('Bool',Value,Result):- var(Value), !, Value=Result, freeze(Value,coerce('Bool',Value,Result)).
coerce('Bool',Value,Result):- is_list(Value),!,as_tf(call_true(Value),Result),
set_list_value(Value,Result).
   
set_list_value(Value,Result):- nb_setarg(1,Value,echo),nb_setarg(1,Value,[Result]).

is_self_eval_l_fa('S',1).
% eval_20(Eq,RetType,Depth,Self,['quote',Eval],RetVal):- !, Eval = RetVal, check_returnval(Eq,RetType,RetVal).
is_self_eval_l_fa('quote',_).
is_self_eval_l_fa('{...}',_).
is_self_eval_l_fa('[...]',_).

self_eval(X):- notrace(self_eval0(X)).

:-  set_prolog_flag(access_level,system).
hyde(F/A):- functor(P,F,A), redefine_system_predicate(P),'$hide'(F/A), '$iso'(F/A).
:- 'hyde'(option_else/2).
:- 'hyde'(atom/1).
:- 'hyde'(quietly/1).
%:- 'hyde'(fake_notrace/1).
:- 'hyde'(var/1).
:- 'hyde'(is_list/1).
:- 'hyde'(copy_term/2).
:- 'hyde'(nonvar/1).
:- 'hyde'(quietly/1).
%:- 'hyde'(option_value/2).


is_metta_declaration([F|_]):- F == '->',!.
is_metta_declaration([F,H,_|T]):- T ==[], is_metta_declaration_f(F,H).

is_metta_declaration_f(F,H):- F == ':<', !, nonvar(H).
is_metta_declaration_f(F,H):- F == ':>', !, nonvar(H).
is_metta_declaration_f(F,H):- F == '=', !, is_list(H),  \+ (current_self(Space), is_user_defined_head_f(Space,F)).

% is_metta_declaration([F|T]):- is_list(T), is_user_defined_head([F]),!.

:- nb_setval(self_space, '&self').
evals_to(XX,Y):- Y=@=XX,!.
evals_to(XX,Y):- Y=='True',!, is_True(XX),!.

%current_self(Space):- nb_current(self_space,Space).

do_expander('=',_,X,X):-!.
do_expander(':',_,X,Y):- !, get_type(X,Y)*->X=Y.

'get_type'(Arg,Type):- 'get-type'(Arg,Type).


eval_true(X):- compound(X), !, call(X).
eval_true(X):- eval_args(X,Y), once(var(Y) ; \+ is_False(Y)).

eval_args(X,Y):- current_self(Self), eval_args(100,Self,X,Y).
eval_args(Depth,Self,X,Y):- eval_args('=',_,Depth,Self,X,Y).
eval_args(Eq,RetType,Depth,Self,X,Y):- eval(Eq,RetType,Depth,Self,X,Y).
/*
eval_args(Eq,RetTyp e,Depth,Self,X,Y):-
   locally(set_prolog_flag(gc,true),
      rtrace_on_existence_error(
     eval(Eq,RetType,Depth,Self,X,Y))).
*/


%eval(Eq,RetType,Depth,_Self,X,_Y):- forall(between(6,Depth,_),write(' ')),writeqln(eval(Eq,RetType,X)),fail.
eval(Depth,Self,X,Y):- eval('=',_RetType,Depth,Self,X,Y).

%eval(_Eq,_RetType,_Dpth,_Slf,X,Y):- var(X),nonvar(Y),!,X=Y.
eval(_Eq,_RetType,_Dpth,_Slf,X,Y):- notrace(self_eval(X)),!,Y=X.
eval(Eq,RetType,Depth,Self,X,Y):- notrace(nonvar(Y)), var(RetType), 
   get_type(Depth,Self,Y,RetType), !,
	eval(Eq,RetType,Depth,Self,X,Y).
eval(Eq,RetType,Depth,Self,X,Y):- notrace(nonvar(Y)),!,
   eval(Eq,RetType,Depth,Self,X,XX),evals_to(XX,Y).


eval(Eq,RetType,_Dpth,_Slf,[X|T],Y):- T==[], number(X),!, do_expander(Eq,RetType,X,YY),Y=[YY].

/*
eval(Eq,RetType,Depth,Self,[F|X],Y):-
  (F=='superpose' ; ( option_value(no_repeats,false))),
  fake_notrace((D1 is Depth-1)),!,
  eval_11(Eq,RetType,D1,Self,[F|X],Y).
*/

eval(Eq,RetType,Depth,Self,X,Y):- atom(Eq),  ( Eq \== ('='),  Eq \== ('match')) ,!,
   call(Eq,'=',RetType,Depth,Self,X,Y).



eval(Eq,RetType,Depth,Self,X,Y):-
  %fake_notrace(allow_repeats_eval_(X)),
  !,
  eval_11(Eq,RetType,Depth,Self,X,Y).
eval(Eq,RetType,Depth,Self,X,Y):-
  nop(notrace((no_repeats_var(YY)),
  D1 is Depth-1)),!,
  eval_11(Eq,RetType,D1,Self,X,Y),
   notrace(( \+ (Y\=YY))).

allow_repeats_eval_(_):- !.
allow_repeats_eval_(_):- option_value(no_repeats,false),!.
allow_repeats_eval_(X):- \+ is_list(X),!,fail.
allow_repeats_eval_([F|_]):- atom(F),allow_repeats_eval_f(F).
allow_repeats_eval_f('superpose').
allow_repeats_eval_f('collapse').

debugging_metta(G):- fake_notrace((is_debugging((eval))->ignore(G);true)).


:- nodebug(metta(eval)).


w_indent(Depth,Goal):- \+ \+ notrace(
    ignore(((
    format('~N'),
    setup_call_cleanup(forall(between(Depth,101,_),write('  ')),Goal, format('~N')))))).

indentq(Depth,Term):-
  \+ \+ fake_notrace(ignore(((
    format('~N'),
    setup_call_cleanup(forall(between(Depth,101,_),write('  ')),format('~q',[Term]),
    format('~N')))))).


indentq(DR,EX,AR,retval(Term)):-nonvar(Term),!,indentq(DR,EX,AR,Term).
indentq(DR,EX,AR,Term):-
  \+ \+
   color_g_mesg('#2f2f2f',
      fake_notrace(ignore((( format('~N;'),
      format('~` t~d~5|:', [EX]),
      format('~` t~d~8|', [DR]),
      forall(between(1,DR,_),write('     |')),write('-'),write(AR),with_indents(false,write_src(Term)),
      format('~N')))))).


with_debug(Flag,Goal):- is_debugging(Flag),!, call(Goal).
with_debug(Flag,Goal):- flag(eval_num,_,0),
  setup_call_cleanup(set_debug(Flag,true),call(Goal),set_debug(Flag,false)).

flag_to_var(Flag,Var):- atom(Flag), \+ atom_concat('trace-on-',_,Flag),!,atom_concat('trace-on-',Flag,Var).
flag_to_var(metta(Flag),Var):- !, nonvar(Flag), flag_to_var(Flag,Var).
flag_to_var(Flag,Var):- Flag=Var.

set_debug(Flag,Val):- \+ atom(Flag), flag_to_var(Flag,Var), atom(Var),!,set_debug(Var,Val).
set_debug(Flag,true):- !, debug(metta(Flag)),flag_to_var(Flag,Var),set_option_value(Var,true).
set_debug(Flag,false):- nodebug(metta(Flag)),flag_to_var(Flag,Var),set_option_value(Var,false).
if_trace((Flag;true),Goal):- !, real_notrace(( catch_err(ignore((Goal)),E,fbug(E-->if_trace((Flag;true),Goal))))).
if_trace(Flag,Goal):- real_notrace((catch_err(ignore((is_debugging(Flag),Goal)),E,fbug(E-->if_trace(Flag,Goal))))).


%maybe_efbug(SS,G):- efbug(SS,G)*-> if_trace(eval,fbug(SS=G)) ; fail.
maybe_efbug(_,G):- call(G).
%efbug(P1,G):- call(P1,G).
efbug(_,G):- call(G).



is_debugging(Flag):- var(Flag),!,fail.
is_debugging((A;B)):- !, (is_debugging(A) ; is_debugging(B) ).
is_debugging((A,B)):- !, (is_debugging(A) , is_debugging(B) ).
is_debugging(not(Flag)):- !,  \+ is_debugging(Flag).
is_debugging(Flag):- Flag== false,!,fail.
is_debugging(Flag):- Flag== true,!.
is_debugging(Flag):- debugging(metta(Flag),TF),!,TF==true.
is_debugging(Flag):- debugging(Flag,TF),!,TF==true.
is_debugging(Flag):- flag_to_var(Flag,Var),
   (option_value(Var,true)->true;(Flag\==Var -> is_debugging(Var))).

:- nodebug(metta(overflow)).


eval_00(_Eq,_RetType,_Dpth,_Slf,X,Y):- self_eval(X),!,Y=X.
eval_00(_Eq,_RetType,Depth,_Slf,X,Y):- Depth<1,!,X=Y, (\+ trace_on_overflow-> true; flag(eval_num,_,0),
    debug(metta(eval))).
eval_00(Eq,RetType,Depth,Self,X,YO):-
  Depth2 is Depth-1,
  copy_term(X, XX),
  eval_20(Eq,RetType,Depth,Self,X,M),
  ((M\=@=XX,  \+ self_eval(M))->
      eval_00(Eq,RetType,Depth2,Self,M,Y);Y=M),
  once(if_or_else((subst_args(Eq,RetType,Depth2,Self,Y,YO)),
     if_or_else(finish_eval(Depth2,Self,Y,YO),
          Y=YO))).


eval_11(_Eq,_RetType,_Dpth,_Slf,X,Y):- self_eval(X),!,Y=X.
eval_11(Eq,RetType,Depth,Self,X,Y):- fail, \+ is_debugging((eval)),!,
  D1 is Depth-1,
  eval_00(Eq,RetType,D1,Self,X,Y).
eval_11(Eq,RetType,Depth,Self,X,Y):-
  ((

  fake_notrace((flag(eval_num,EX0,EX0+1),
  EX is EX0 mod 500,
  D1 is Depth-1,
  DR is 99-D1,
  PrintRet = _)),
  option_else('trace-length',Max,100),
  option_else('trace-depth',DMax,30),
  quietly((if_t((nop(stop_rtrace),EX>Max), (set_debug(eval,false),MaxP1 is Max+1, %set_debug(overflow,false),
      nop(format('; Switched off tracing. For a longer trace: !(pragma! trace-length ~w)',[MaxP1])),nop((start_rtrace,rtrace)))))),
  nop(notrace(no_repeats_var(YY))),

  if_t(DR<DMax,if_trace((eval),(PrintRet=1, indentq(DR,EX, '-->',eval(X))))),
  Ret=retval(fail))),

  call_cleanup((
    (eval_00(Eq,RetType,D1,Self,X,Y)*->true;(fail,trace,(eval_00(Eq,RetType,D1,Self,X,Y)))),
    fake_notrace(( \+ (Y\=YY), nb_setarg(1,Ret,Y)))),

    (PrintRet==1 -> indentq(DR,EX,'<--',Ret) ;
    fake_notrace(ignore(((Y\=@=X,
      if_t(DR<DMax,if_trace((eval),indentq(DR,EX,'<--',Ret))))))))),

  (Ret\=@=retval(fail)->true;(fail,trace,(eval_00(Eq,RetType,D1,Self,X,Y)),fail)).



% eval_15(Eq,RetType,Depth,Self,X,Y):- !, eval_20(Eq,RetType,Depth,Self,X,Y).

eval_15(Eq,RetType,Depth,Self,X,Y):- ((eval_20(Eq,RetType,Depth,Self,X,Y),
   if_t(var(Y),fbug((eval_20(Eq,RetType,Depth,Self,X,Y),var(Y)))),
   nonvar(Y))*->true;(eval_failed(Depth,Self,X,Y),fail)).








:- discontiguous eval_20/6.
:- discontiguous eval_40/6.
%:- discontiguous eval_30fz/5.
%:- discontiguous eval_31/5.
%:- discontiguous eval_60/5.

eval_20(Eq,RetType,_Dpth,_Slf,Name,Y):- atom(Name), !,
      (nb_current(Name,X)->do_expander(Eq,RetType,X,Y); Y = Name).


eval_20(Eq,RetType,_Dpth,_Slf,X,Y):- self_eval(X),!,do_expander(Eq,RetType,X,Y).

% =================================================================
% =================================================================
% =================================================================
%  VAR HEADS/ NON-LISTS
% =================================================================
% =================================================================
% =================================================================

eval_20(Eq,RetType,_Dpth,_Slf,[X|T],Y):- T==[], \+ callable(X),!, do_expander(Eq,RetType,X,YY),Y=[YY].
%eval_20(Eq,RetType,_Dpth,Self,[X|T],Y):- T==[],  atom(X),
%   \+ is_user_defined_head_f(Self,X),
%   do_expander(Eq,RetType,X,YY),!,Y=[YY].

eval_20(Eq,RetType,Depth,Self,X,Y):- atom(Eq),  ( Eq \== ('=')) ,!,
   call(Eq,'=',RetType,Depth,Self,X,Y).


eval_20(Eq,RetType,Depth,Self,[V|VI],VVO):-  \+ is_list(VI),!,
 eval(Eq,RetType,Depth,Self,VI,VM),
  ( VM\==VI -> eval(Eq,RetType,Depth,Self,[V|VM],VVO) ;
    (eval(Eq,RetType,Depth,Self,V,VV), (V\==VV -> eval(Eq,RetType,Depth,Self,[VV|VI],VVO) ; VVO = [V|VI]))).

eval_20(Eq,RetType,_Dpth,_Slf,X,Y):- \+ is_list(X),!,do_expander(Eq,RetType,X,Y).

eval_20(Eq,_RetType,Depth,Self,[V|VI],[V|VO]):- var(V),is_list(VI),!,maplist(eval(Eq,_ArgRetType,Depth,Self),VI,VO).

eval_20(_,_,_,_,['echo',Value],Value):- !.
eval_20(=,Type,_,_,['coerce',Type,Value],Result):- !, coerce(Type,Value,Result).

% =================================================================
% =================================================================
% =================================================================
%  TRACE/PRINT
% =================================================================
% =================================================================
% =================================================================

eval_20(Eq,RetType,_Dpth,_Slf,['repl!'],Y):- !,  repl,check_returnval(Eq,RetType,Y).
%eval_20(Eq,RetType,Depth,Self,['enforce',Cond],Res):- !, enforce_true(Eq,RetType,Depth,Self,Cond,Res).
eval_20(Eq,RetType,Depth,Self,['!',Cond],Res):- !, call(eval(Eq,RetType,Depth,Self,Cond,Res)).
eval_20(Eq,RetType,Depth,Self,['rtrace!',Cond],Res):- !, rtrace(eval(Eq,RetType,Depth,Self,Cond,Res)).
eval_20(Eq,RetType,Depth,Self,['trace',Cond],Res):- !, with_debug(eval,eval(Eq,RetType,Depth,Self,Cond,Res)).
eval_20(Eq,RetType,Depth,Self,['time',Cond],Res):- !, time_eval(eval(Cond),eval(Eq,RetType,Depth,Self,Cond,Res)).
eval_20(Eq,RetType,Depth,Self,['print',Cond],Res):- !, eval(Eq,RetType,Depth,Self,Cond,Res),format('~N'),print(Res),format('~N').
% !(println! $1)
eval_20(Eq,RetType,Depth,Self,['println!'|Cond],Res):- !, maplist(eval(Eq,RetType,Depth,Self),Cond,[Res|Out]),
   format('~N'),maplist(write_src,[Res|Out]),format('~N').
eval_20(Eq,RetType,Depth,Self,['trace!',A|Cond],Res):- !, maplist(eval(Eq,RetType,Depth,Self),[A|Cond],[AA|Result]),
   last(Result,Res), format('~N'),maplist(write_src,[AA]),format('~N').

%eval_20(Eq,RetType,Depth,Self,['trace!',A,B],C):- !,eval(Eq,RetType,Depth,Self,B,C),format('~N'),fbug(['trace!',A,B]=C),format('~N').
%eval_20(Eq,RetType,_Dpth,_Slf,['trace!',A],A):- !, format('~N'),fbug(A),format('~N').

eval_20(Eq,RetType,_Dpth,_Slf,List,YY):- is_list(List),maplist(self_eval,List),List=[H|_], \+ atom(H), !,Y=List,do_expander(Eq,RetType,Y,YY).

eval_20(Eq,_ListOfRetType,Depth,Self,['TupleConcat',A,B],OO):- fail, !,
    eval(Eq,RetType,Depth,Self,A,AA),
    eval(Eq,RetType,Depth,Self,B,BB),
    append(AA,BB,OO).
eval_20(Eq,OuterRetType,Depth,Self,['range',A,B],OO):- (is_list(A);is_list(B)),
  ((eval(Eq,RetType,Depth,Self,A,AA),
    eval(Eq,RetType,Depth,Self,B,BB))),
    ((AA+BB)\=@=(A+B)),
    eval_20(Eq,OuterRetType,Depth,Self,['range',AA,BB],OO),!.


%eval_20(Eq,RetType,Depth,Self,['colapse'|List], Flat):- !, maplist(eval(Eq,RetType,Depth,Self),List,Res),flatten(Res,Flat).

eval_20(_Eq,_OuterRetType,_Depth,_Self,[P,_,B],_):-P=='/',B==0,!,fail.


% =================================================================
% =================================================================
% =================================================================
%  UNIT TESTING/assert<STAR>
% =================================================================
% =================================================================
% =================================================================


eval_20(Eq,RetType,Depth,Self,['assertTrue', X],TF):- !, eval(Eq,RetType,Depth,Self,['assertEqual',X,'True'],TF).
eval_20(Eq,RetType,Depth,Self,['assertFalse',X],TF):- !, eval(Eq,RetType,Depth,Self,['assertEqual',X,'False'],TF).

eval_20(Eq,RetType,Depth,Self,['assertEqual',X,Y],RetVal):- !,
   loonit_assert_source_tf(
        ['assertEqual',X,Y],
        (bagof_eval(Eq,RetType,Depth,Self,X,XX), bagof_eval(Eq,RetType,Depth,Self,Y,YY)),
         equal_enough_for_test(XX,YY), TF),
  (TF=='True'->return_empty(RetVal);RetVal=[got,XX,[expected,YY]]).

eval_20(Eq,RetType,Depth,Self,['assertNotEqual',X,Y],RetVal):- !,
   loonit_assert_source_tf(
        ['assertEqual',X,Y],
        (bagof_eval(Eq,RetType,Depth,Self,X,XX), bagof_eval(Eq,RetType,Depth,Self,Y,YY)),
         \+ equal_enough(XX,YY), TF),
  (TF=='True'->return_empty(RetVal);RetVal=[got,XX,expected,YY]).

eval_20(Eq,RetType,Depth,Self,['assertEqualToResult',X,Y],RetVal):- !,
   loonit_assert_source_tf(
        ['assertEqualToResult',X,Y],
        (bagof_eval(Eq,RetType,Depth,Self,X,XX), sort(Y,YY)),
         equal_enough_for_test(XX,YY), TF),
  (TF=='True'->return_empty(RetVal);RetVal=[got,XX,expected,YY]).


loonit_assert_source_tf(Src,Goal,Check,TF):-
   copy_term(Goal,OrigGoal),
   flag(eval_num,_,0),
   loonit_asserts(Src, time_eval('\n; EVAL TEST\n;',Goal), Check),
   as_tf(Check,TF),!,
  ignore((
          once((TF='True', trace_on_pass);(TF='False', trace_on_fail)),
     with_debug(metta(eval),time_eval('Trace',OrigGoal)))).

sort_result(Res,Res):- \+ compound(Res),!.
sort_result([And|Res1],Res):- is_and(And),!,sort_result(Res1,Res).
sort_result([T,And|Res1],Res):- is_and(And),!,sort_result([T|Res1],Res).
sort_result([H|T],[HH|TT]):- !, sort_result(H,HH),sort_result(T,TT).
sort_result(Res,Res).

unify_enough(L,L).
unify_enough(L,C):- into_list_args(L,LL),into_list_args(C,CC),unify_lists(CC,LL).

%unify_lists(C,L):- \+ compound(C),!,L=C.
%unify_lists(L,C):- \+ compound(C),!,L=C.
unify_lists(L,L):-!.
unify_lists([C|CC],[L|LL]):- unify_enough(L,C),!,unify_lists(CC,LL).

equal_enough(R,V):- is_list(R),is_list(V),sort(R,RR),sort(V,VV),!,equal_enouf(RR,VV),!.
equal_enough(R,V):- copy_term(R,RR),copy_term(V,VV),equal_enouf(R,V),!,R=@=RR,V=@=VV.

%s_empty(X):- var(X),!.
s_empty(X):- var(X),!,fail.
is_empty('Empty').
is_empty([]). %
is_empty([X]):-!,is_empty(X).
has_let_star(Y):- sub_var('let*',Y).

equal_enough_for_test(X,Y):- is_empty(X),!,is_empty(Y).
equal_enough_for_test(X,Y):- has_let_star(Y),!,\+ is_empty(X).
equal_enough_for_test(X,Y):- must_det_ll((subst_vars(X,XX),subst_vars(Y,YY))),!,equal_enough_for_test2(XX,YY),!.
equal_enough_for_test2(X,Y):- equal_enough(X,Y).

equal_enouf(R,V):- is_ftVar(R), is_ftVar(V), R=V,!.
equal_enouf(X,Y):- is_empty(X),!,is_empty(Y).
equal_enouf(X,Y):- symbol(X),symbol(Y),atom_concat('&',_,X),atom_concat('Grounding',_,Y).
equal_enouf(R,V):- R=@=V, R=V, !.
equal_enouf(_,V):- V=@='...',!.
equal_enouf(L,C):- is_list(L),into_list_args(C,CC),!,equal_enouf_l(CC,L).
equal_enouf(C,L):- is_list(L),into_list_args(C,CC),!,equal_enouf_l(CC,L).
%equal_enouf(R,V):- (var(R),var(V)),!, R=V.
equal_enouf(R,V):- (var(R);var(V)),!, R==V.
equal_enouf(R,V):- number(R),number(V),!, RV is abs(R-V), RV < 0.03 .
equal_enouf(R,V):- atom(R),!,atom(V), has_unicode(R),has_unicode(V).
equal_enouf(R,V):- (\+ compound(R) ; \+ compound(V)),!, R==V.
equal_enouf(L,C):- into_list_args(L,LL),into_list_args(C,CC),!,equal_enouf_l(CC,LL).

equal_enouf_l([S1,V1|_],[S2,V2|_]):- S1 == 'State',S2 == 'State',!, equal_enouf(V1,V2).
equal_enouf_l(C,L):- \+ compound(C),!,L=@=C.
equal_enouf_l(L,C):- \+ compound(C),!,L=@=C.
equal_enouf_l([C|CC],[L|LL]):- !, equal_enouf(L,C),!,equal_enouf_l(CC,LL).


has_unicode(A):- atom_codes(A,Cs),member(N,Cs),N>127,!.

set_last_error(_).

% =================================================================
% =================================================================
% =================================================================
%  SPACE EDITING
% =================================================================
% =================================================================
% =================================================================

eval_20(Eq,RetType,_Dpth,_Slf,['new-space'],Space):- !, 'new-space'(Space),check_returnval(Eq,RetType,Space).

eval_20(Eq,RetType,Depth,Self,[Op,Space|Args],Res):- is_space_op(Op),!,
  eval_space_start(Eq,RetType,Depth,Self,[Op,Space|Args],Res).


eval_space_start(Eq,RetType,_Depth,_Self,[_Op,_Other,Atom],Res):-
  (Atom == [] ;  Atom =='Empty';  Atom =='Nil'),!,return_empty('False',Res),check_returnval(Eq,RetType,Res).

eval_space_start(Eq,RetType,Depth,Self,[Op,Other|Args],Res):-
  into_space(Depth,Self,Other,Space),
  eval_space(Eq,RetType,Depth,Self,[Op,Space|Args],Res).


eval_space(Eq,RetType,_Dpth,_Slf,['add-atom',Space,PredDecl],Res):- !,
   do_metta(python,load,Space,PredDecl,TF),return_empty(TF,Res),check_returnval(Eq,RetType,Res).

eval_space(Eq,RetType,_Dpth,_Slf,['remove-atom',Space,PredDecl],Res):- !,
   do_metta(python,unload,Space,PredDecl,TF),return_empty(TF,Res),check_returnval(Eq,RetType,Res).

eval_space(Eq,RetType,_Dpth,_Slf,['atom-count',Space],Count):- !,
    ignore(RetType='Number'),ignore(Eq='='),
    findall(Atom, get_metta_atom_from(Space, Atom),Atoms),
    length(Atoms,Count).

eval_space(Eq,RetType,_Dpth,_Slf,['atom-replace',Space,Rem,Add],TF):- !,
   copy_term(Rem,RCopy), as_tf((metta_atom_iter_ref(Space,RCopy,Ref), RCopy=@=Rem,erase(Ref), do_metta(Space,load,Add)),TF),
 check_returnval(Eq,RetType,TF).

eval_space(Eq,RetType,_Dpth,_Slf,['get-atoms',Space],Atom):- !,
  ignore(RetType='Atom'), get_metta_atom_from(Space, Atom), check_returnval(Eq,RetType,Atom).

% Match-ELSE
eval_space(Eq,RetType,Depth,Self,['match',Other,Goal,Template,Else],Template):- !,
  ((eval_space(Eq,RetType,Depth,Self,['match',Other,Goal,Template],Template),
       \+ return_empty([],Template))*->true;Template=Else).
% Match-TEMPLATE

eval_space(Eq,_RetType,Depth,Self,['match',Other,Goal,Template],Res):- !,
   metta_atom_iter(Eq,Depth,Self,Other,Goal),
   Template=Res.

metta_atom_iter(Eq,_Depth,_Slf,Other,[Equal,[F|H],B]):- Eq == Equal,!,  % trace,
   metta_defn(Eq,Other,[F|H],B).

/*
metta_atom_iter(Eq,Depth,Self,Other,[Equal,[F|H],B]):- Eq == Equal,!,  % trace,
   metta_defn(Eq,Other,[F|H],BB),
   eval_sometimes(Eq,_RetType,Depth,Self,B,BB).
*/

metta_atom_iter(_Eq,Depth,_,_,_):- Depth<3,!,fail.
metta_atom_iter(Eq,Depth,Self,Other,[And|Y]):- atom(And), is_and(And),!,
  (Y==[] -> true ;
    ( D2 is Depth -1, Y = [H|T],
       metta_atom_iter(Eq,D2,Self,Other,H),metta_atom_iter(Eq,D2,Self,Other,[And|T]))).

%metta_atom_iter(Eq,Depth,_Slf,Other,X):- dcall0000000000(eval_args_true(Eq,_RetType,Depth,Other,X)).
metta_atom_iter(Eq,Depth,_Slf,Other,X):-
  %copy_term(X,XX),
  dcall0000000000(eval_args_true(Eq,_RetType,Depth,Other,XX)), X=XX.


eval_args_true_r(Eq,RetType,Depth,Self,X,TF1):-
  ((eval_ne(Eq,RetType,Depth,Self,X,TF1),  \+  is_False(TF1));
     ( \+  is_False(TF1),metta_atom_true(Eq,Depth,Self,Self,X))).

eval_args_true(Eq,RetType,Depth,Self,X):-
  metta_atom_true(Eq,Depth,Self,Self,X);
   (nonvar(X),eval_ne(Eq,RetType,Depth,Self,X,TF1),  \+  is_False(TF1)).

metta_atom_true(Eq,_Dpth,_Slf,Other,H):- get_metta_atom(Eq,Other,H).
% is this OK?
metta_atom_true(Eq,Depth,Self,Other,H):- nonvar(H), metta_defn(Eq,Other,H,B), D2 is Depth -1, eval_args_true(Eq,_,D2,Self,B).
% is this OK?
metta_atom_true(Eq,Depth,Self,Other,H):- Other\==Self, nonvar(H), metta_defn(Eq,Other,H,B), D2 is Depth -1, eval_args_true(Eq,_,D2,Other,B).



metta_atom_iter_ref(Other,H,Ref):-clause(asserted_metta_atom(Other,H),true,Ref).


% =================================================================
% =================================================================
% =================================================================
%  CASE/SWITCH
% =================================================================
% =================================================================
% =================================================================
% Macro: case
:- nodebug(metta(case)).

eval_20(Eq,RetType,Depth,Self,[P,X|More],YY):- is_list(X),X=[_,_,_],simple_math(X),
   eval_selfless_2(X,XX),X\=@=XX,!, eval_20(Eq,RetType,Depth,Self,[P,XX|More],YY).
% if there is only a void then always return nothing for each Case
eval_20(Eq,_RetType,Depth,Self,['case',A,[[Void,_]]],Res):-
   '%void%' == Void,
   eval(Eq,_UnkRetType,Depth,Self,A,_),!,Res =[].

% if there is nothing for case just treat like a collapse
eval_20(Eq,_RetType,Depth,Self,['case',A,[]],Empty):- !,
  %forall(eval(Eq,_RetType2,Depth,Self,Expr,_),true),
  once(eval(Eq,_RetType2,Depth,Self,A,_)),
  return_empty([],Empty).

% Macro: case
eval_20(Eq,RetType,Depth,Self,['case',A,CL|T],Res):- !,
   must_det_ll(T==[]),
   into_case_list(CL,CASES),
   findall(Key-Value,
     (nth0(Nth,CASES,Case0),
       (is_case(Key,Case0,Value),
        if_trace(metta(case),(format('~N'),writeqln(c(Nth,Key)=Value))))),KVs),!,
   eval_case(Eq,RetType,Depth,Self,A,KVs,Res).

eval_case(Eq,CaseRetType,Depth,Self,A,KVs,Res):-
   ((eval(Eq,_UnkRetType,Depth,Self,A,AA),
         if_trace((case),(writeqln('case'=A))),
         if_trace(metta(case),writeqln('switch'=AA)),
    (select_case(Depth,Self,AA,KVs,Value)->true;(member(Void -Value,KVs),Void=='%void%')))
     *->true;(member(Void -Value,KVs),Void=='%void%')),
    eval(Eq,CaseRetType,Depth,Self,Value,Res).

  select_case(Depth,Self,AA,Cases,Value):-
     (best_key(AA,Cases,Value) -> true ;
      (maybe_special_keys(Depth,Self,Cases,CasES),
       (best_key(AA,CasES,Value) -> true ;
        (member(Void -Value,CasES),Void=='%void%')))).

  best_key(AA,Cases,Value):-
     ((member(Match-Value,Cases),AA ==Match)->true;
      ((member(Match-Value,Cases),AA=@=Match)->true;
        (member(Match-Value,Cases),AA = Match))).

	into_case_list(CASES,CASES):- is_list(CASES),!.
		is_case(AA,[AA,Value],Value):-!.
		is_case(AA,[AA|Value],Value).

   maybe_special_keys(Depth,Self,[K-V|KVI],[AK-V|KVO]):-
     eval(Depth,Self,K,AK), K\=@=AK,!,
     maybe_special_keys(Depth,Self,KVI,KVO).
   maybe_special_keys(Depth,Self,[_|KVI],KVO):-
     maybe_special_keys(Depth,Self,KVI,KVO).
   maybe_special_keys(_Depth,_Self,[],[]).


% =================================================================
% =================================================================
% =================================================================
%  COLLAPSE/SUPERPOSE
% =================================================================
% =================================================================
% =================================================================



%[collapse,[1,2,3]]
eval_20(Eq,RetType,Depth,Self,['collapse',List],Res):-!,
 bagof_eval(Eq,RetType,Depth,Self,List,Res).

eval_20(Eq,RetType,Depth,Self,PredDecl,Res):-
  Do_more_defs = do_more_defs(true),
  clause(eval_21(Eq,RetType,Depth,Self,PredDecl,Res),Body),
  Do_more_defs == do_more_defs(true),
  call_ndet(Body,DET),
  nb_setarg(1,Do_more_defs,false),
 (DET==true -> ! ; true).


eval_21(Eq,RetType,Depth,Self,['CollapseCardinality',List],Len):-!,
 bagof_eval(Eq,RetType,Depth,Self,List,Res),
 length(Res,Len).
/*
eval_21(_Eq,_RetType,_Depth,_Self,['TupleCount', [N]],N):- number(N),!.


eval_21(Eq,RetType,Depth,Self,['TupleCount',List],Len):-!,
 bagof_eval(Eq,RetType,Depth,Self,List,Res),
 length(Res,Len).
*/

%[superpose,[1,2,3]]
eval_20(Eq,RetType,Depth,Self,['superpose',List],Res):- !,
  (((is_user_defined_head(Eq,Self,List) ,eval(Eq,RetType,Depth,Self,List,UList), List\=@=UList)
    *->  eval_20(Eq,RetType,Depth,Self,['superpose',UList],Res)
       ; ((member(E,List),eval(Eq,RetType,Depth,Self,E,Res))*->true;return_empty([],Res)))),
  \+ Res = 'Empty'.

%[sequential,[1,2,3]]
eval_20(Eq,RetType,Depth,Self,['sequential',List],Res):- !,
  (((fail,is_user_defined_head(Eq,Self,List) ,eval(Eq,RetType,Depth,Self,List,UList), List\=@=UList)
    *->  eval_20(Eq,RetType,Depth,Self,['sequential',UList],Res)
       ; ((member(E,List),eval_ne(Eq,RetType,Depth,Self,E,Res))*->true;return_empty([],Res)))).


get_sa_p1(P3,E,Cmpd,SA):-  compound(Cmpd), get_sa_p2(P3,E,Cmpd,SA).
get_sa_p2(P3,E,Cmpd,call(P3,N1,Cmpd)):- arg(N1,Cmpd,E).
get_sa_p2(P3,E,Cmpd,SA):- arg(_,Cmpd,Arg),get_sa_p1(P3,E,Arg,SA).
eval20_failed(Eq,RetType,Depth,Self, Term, Res):-
  fake_notrace(( get_sa_p1(setarg,ST,Term,P1), % ST\==Term,
   compound(ST), ST = [F,List],F=='superpose',nonvar(List), %maplist(atomic,List),
   call(P1,Var))), !,
   %max_counting(F,20),
   member(Var,List),
   eval(Eq,RetType,Depth,Self, Term, Res).


sub_sterm(Sub,Sub).
sub_sterm(Sub,Term):- sub_sterm1(Sub,Term).
sub_sterm1(_  ,List):- \+ compound(List),!,fail.
sub_sterm1(Sub,List):- is_list(List),!,member(SL,List),sub_sterm(Sub,SL).
sub_sterm1(_  ,[_|_]):-!,fail.
sub_sterm1(Sub,Term):- arg(_,Term,SL),sub_sterm(Sub,SL).
eval20_failed_2(Eq,RetType,Depth,Self, Term, Res):-
   fake_notrace(( get_sa_p1(setarg,ST,Term,P1),
   compound(ST), ST = [F,List],F=='collapse',nonvar(List), %maplist(atomic,List),
   call(P1,Var))), !, bagof_eval(Eq,RetType,Depth,Self,List,Var),
   eval(Eq,RetType,Depth,Self, Term, Res).


% =================================================================
% =================================================================
% =================================================================
%  NOP/EQUALITU/DO
% =================================================================
% =================================================================
% ================================================================
eval_20(_Eq,_RetType,_Depth,_Self,['nop'],                 _ ):- !, fail.
eval_20(_Eq,_RetType,_Depth,_Self,['empty'],                 _ ):- !, fail.
eval_20(_Eq,_RetType1,Depth,Self,['nop',Expr], Empty):- !,
  ignore(eval('=',_RetType2,Depth,Self,Expr,_)),
  return_empty([], Empty).

eval_20(Eq,_RetType1,Depth,Self,['do',Expr], Empty):- !,
  forall(eval(Eq,_RetType2,Depth,Self,Expr,_),true),
  %eval_ne(Eq,_RetType2,Depth,Self,Expr,_),!,
  return_empty([],Empty).

eval_20(_Eq,_RetType1,_Depth,_Self,['call',S], TF):- !, eval_call(S,TF).

max_counting(F,Max):- flag(F,X,X+1),  X<Max ->  true; (flag(F,_,10),!,fail).
% =================================================================
% =================================================================
% =================================================================
%  if/If
% =================================================================
% =================================================================
% =================================================================



eval_20(Eq,RetType,Depth,Self,['if',Cond,Then,Else],Res):- !,
   eval(Eq,'Bool',Depth,Self,Cond,TF),
   (is_True(TF)
     -> eval(Eq,RetType,Depth,Self,Then,Res)
     ;  eval(Eq,RetType,Depth,Self,Else,Res)).

eval_20(Eq,RetType,Depth,Self,['If',Cond,Then,Else],Res):- !,
   eval(Eq,'Bool',Depth,Self,Cond,TF),
   (is_True(TF)
     -> eval(Eq,RetType,Depth,Self,Then,Res)
     ;  eval(Eq,RetType,Depth,Self,Else,Res)).

eval_20(Eq,RetType,Depth,Self,['If',Cond,Then],Res):- !,
   eval(Eq,'Bool',Depth,Self,Cond,TF),
   (is_True(TF) -> eval(Eq,RetType,Depth,Self,Then,Res) ;
      (!, fail,Res = [],!)).

eval_20(Eq,RetType,Depth,Self,['if',Cond,Then],Res):- !,
   eval(Eq,'Bool',Depth,Self,Cond,TF),
   (is_True(TF) -> eval(Eq,RetType,Depth,Self,Then,Res) ;
      (!, fail,Res = [],!)).


eval_20(Eq,RetType,_Dpth,_Slf,[_,Nothing],NothingO):-
   'Nothing'==Nothing,!,do_expander(Eq,RetType,Nothing,NothingO).

% =================================================================
% =================================================================
% =================================================================
%  LET/LET*
% =================================================================
% =================================================================
% =================================================================



eval_until_unify(_Eq,_RetType,_Dpth,_Slf,X,X):- !.
eval_until_unify(Eq,RetType,Depth,Self,X,Y):- eval_until_eq(Eq,RetType,Depth,Self,X,Y),!.

eval_until_eq(Eq,RetType,_Dpth,_Slf,X,Y):-  X=Y,check_returnval(Eq,RetType,Y).
%eval_until_eq(Eq,RetType,Depth,Self,X,Y):- var(Y),!,eval_in_steps_or_same(Eq,RetType,Depth,Self,X,XX),Y=XX.
%eval_until_eq(Eq,RetType,Depth,Self,Y,X):- var(Y),!,eval_in_steps_or_same(Eq,RetType,Depth,Self,X,XX),Y=XX.
eval_until_eq(Eq,RetType,Depth,Self,X,Y):- \+is_list(Y),!,eval_in_steps_some_change(Eq,RetType,Depth,Self,X,XX),Y=XX.
eval_until_eq(Eq,RetType,Depth,Self,Y,X):- \+is_list(Y),!,eval_in_steps_some_change(Eq,RetType,Depth,Self,X,XX),Y=XX.
eval_until_eq(Eq,RetType,Depth,Self,X,Y):- eval_in_steps_some_change(Eq,RetType,Depth,Self,X,XX),eval_until_eq(Eq,RetType,Depth,Self,Y,XX).
eval_until_eq(_Eq,_RetType,_Dpth,_Slf,X,Y):- length(X,Len), \+ length(Y,Len),!,fail.
eval_until_eq(Eq,RetType,Depth,Self,X,Y):-  nth1(N,X,EX,RX), nth1(N,Y,EY,RY),
  EX=EY,!, maplist(eval_until_eq(Eq,RetType,Depth,Self),RX,RY).
eval_until_eq(Eq,RetType,Depth,Self,X,Y):-  nth1(N,X,EX,RX), nth1(N,Y,EY,RY),
  ((var(EX);var(EY)),eval_until_eq(Eq,RetType,Depth,Self,EX,EY)),
  maplist(eval_until_eq(Eq,RetType,Depth,Self),RX,RY).
eval_until_eq(Eq,RetType,Depth,Self,X,Y):-  nth1(N,X,EX,RX), nth1(N,Y,EY,RY),
  h((is_list(EX);is_list(EY)),eval_until_eq(Eq,RetType,Depth,Self,EX,EY)),
  maplist(eval_until_eq(Eq,RetType,Depth,Self),RX,RY).

 eval_1change(Eq,RetType,Depth,Self,EX,EXX):-
    eval_20(Eq,RetType,Depth,Self,EX,EXX),  EX \=@= EXX.

eval_complete_change(Eq,RetType,Depth,Self,EX,EXX):-
   eval(Eq,RetType,Depth,Self,EX,EXX),  EX \=@= EXX.

eval_in_steps_some_change(_Eq,_RetType,_Dpth,_Slf,EX,_):- \+ is_list(EX),!,fail.
eval_in_steps_some_change(Eq,RetType,Depth,Self,EX,EXX):- eval_1change(Eq,RetType,Depth,Self,EX,EXX).
eval_in_steps_some_change(Eq,RetType,Depth,Self,X,Y):- append(L,[EX|R],X),is_list(EX),
    eval_in_steps_some_change(Eq,RetType,Depth,Self,EX,EXX), EX\=@=EXX,
    append(L,[EXX|R],XX),eval_in_steps_or_same(Eq,RetType,Depth,Self,XX,Y).

eval_in_steps_or_same(Eq,RetType,Depth,Self,X,Y):-eval_in_steps_some_change(Eq,RetType,Depth,Self,X,Y).
eval_in_steps_or_same(Eq,RetType,_Dpth,_Slf,X,Y):- X=Y,check_returnval(Eq,RetType,Y).

  % (fail,return_empty([],Template))).


eval_20(Eq,RetType,Depth,Self,['let',A,A5,AA],OO):- !,
  %(var(A)->true;trace),
  eval(Eq,_RetTypeV,Depth,Self,A5,AR),
  A=AR,
  eval(Eq,RetType,Depth,Self,AA,OO).

%eval_20(Eq,RetType,Depth,Self,['let',A,A5,AA],AAO):- !,eval(Eq,RetType,Depth,Self,A5,A),eval(Eq,RetType,Depth,Self,AA,AAO).
eval_20(Eq,RetType,Depth,Self,['let*',[],Body],RetVal):- !, eval(Eq,RetType,Depth,Self,Body,RetVal).
%eval_20(Eq,RetType,Depth,Self,['let*',[[Var,Val]|LetRest],Body],RetVal):- !,
%   eval_until_unify(Eq,_RetTypeV,Depth,Self,Val,Var),
%   eval_20(Eq,RetType,Depth,Self,['let*',LetRest,Body],RetVal).
eval_20(Eq,RetType,Depth,Self,['let*',[[Var,Val]|LetRest],Body],RetVal):- !,
    eval_20(Eq,RetType,Depth,Self,['let',Var,Val,['let*',LetRest,Body]],RetVal).


% =================================================================
% =================================================================
% =================================================================
%  CONS/CAR/CDR
% =================================================================
% =================================================================
% =================================================================



into_pl_list(Var,Var):- var(Var),!.
into_pl_list(Nil,[]):- Nil == 'Nil',!.
into_pl_list([Cons,H,T],[HH|TT]):- Cons == 'Cons', !, into_pl_list(H,HH),into_pl_list(T,TT),!.
into_pl_list(X,X).

into_metta_cons(Var,Var):- var(Var),!.
into_metta_cons([],'Nil'):-!.
into_metta_cons([Cons, A, B ],['Cons', AA, BB]):- 'Cons'==Cons, no_cons_reduce, !,
  into_metta_cons(A,AA), into_metta_cons(B,BB).
into_metta_cons([H|T],['Cons',HH,TT]):- into_metta_cons(H,HH),into_metta_cons(T,TT),!.
into_metta_cons(X,X).

into_listoid(AtomC,Atom):- AtomC = [Cons,H,T],Cons=='Cons',!, Atom=[H,[T]].
into_listoid(AtomC,Atom):- is_list(AtomC),!,Atom=AtomC.
into_listoid(AtomC,Atom):- typed_list(AtomC,_,Atom),!.

:- if( \+  current_predicate( typed_list / 3 )).
typed_list(Cmpd,Type,List):-  compound(Cmpd), Cmpd\=[_|_], compound_name_arguments(Cmpd,Type,[List|_]),is_list(List).
:- endif.

%eval_20(Eq,RetType,Depth,Self,['colapse'|List], Flat):- !, maplist(eval(Eq,RetType,Depth,Self),List,Res),flatten(Res,Flat).

%eval_20(Eq,RetType,Depth,Self,['flatten'|List], Flat):- !, maplist(eval(Eq,RetType,Depth,Self),List,Res),flatten(Res,Flat).


eval_20(Eq,RetType,_Dpth,_Slf,['car-atom',Atom],CAR_Y):- !, Atom=[CAR|_],!,do_expander(Eq,RetType,CAR,CAR_Y).
eval_20(Eq,RetType,_Dpth,_Slf,['cdr-atom',Atom],CDR_Y):- !, Atom=[_|CDR],!,do_expander(Eq,RetType,CDR,CDR_Y).

eval_20(Eq,RetType,Depth,Self,['Cons', A, B ],['Cons', AA, BB]):- no_cons_reduce, !,
  eval(Eq,RetType,Depth,Self,A,AA), eval(Eq,RetType,Depth,Self,B,BB).

%eval_20(_Eq,_RetType,Depth,Self,['::'|PL],Prolog):-  maplist(as_prolog(Depth,Self),PL,Prolog),!.
%eval_20(_Eq,_RetType,Depth,Self,['@'|PL],Prolog):- as_prolog(Depth,Self,['@'|PL],Prolog),!.

eval_20(Eq,RetType,Depth,Self,['Cons', A, B ],[AA|BB]):- \+ no_cons_reduce, !,
   eval(Eq,RetType,Depth,Self,A,AA), eval(Eq,RetType,Depth,Self,B,BB).



% =================================================================
% =================================================================
% =================================================================
%  STATE EDITING
% =================================================================
% =================================================================
% =================================================================

eval_20(Eq,RetType,Depth,Self,['change-state!',StateExpr, UpdatedValue], Ret):- !,
 call_in_shared_space(((eval(Eq,RetType,Depth,Self,StateExpr,StateMonad),
  eval(Eq,RetType,Depth,Self,UpdatedValue,Value),  'change-state!'(Depth,Self,StateMonad, Value, Ret)))).
eval_20(Eq,RetType,Depth,Self,['new-state',UpdatedValue],StateMonad):- !,
  call_in_shared_space(((eval(Eq,RetType,Depth,Self,UpdatedValue,Value),  'new-state'(Depth,Self,Value,StateMonad)))).
eval_20(Eq,RetType,Depth,Self,['get-state',StateExpr],Value):- !,
  call_in_shared_space((eval(Eq,RetType,Depth,Self,StateExpr,StateMonad), 'get-state'(StateMonad,Value))).

call_in_shared_space(G):- call_in_thread(main,G).

% eval_20(Eq,RetType,Depth,Self,['get-state',Expr],Value):- !, eval(Eq,RetType,Depth,Self,Expr,State), arg(1,State,Value).



check_type:- option_else(typecheck,TF,'False'), TF=='True'.

:- dynamic is_registered_state/1.
:- flush_output.
:- setenv('RUST_BACKTRACE',full).

% Function to check if an value is registered as a state name
:- dynamic(is_registered_state/1).
is_nb_state(G):- is_valid_nb_state(G) -> true ;
                 is_registered_state(G),nb_current(G,S),is_valid_nb_state(S).


:- multifile(state_type_method/3).
:- dynamic(state_type_method/3).
state_type_method(is_nb_state,new_state,init_state).
state_type_method(is_nb_state,clear_state,clear_nb_values).
state_type_method(is_nb_state,add_value,add_nb_value).
state_type_method(is_nb_state,remove_value,'change-state!').
state_type_method(is_nb_state,replace_value,replace_nb_value).
state_type_method(is_nb_state,value_count,value_nb_count).
state_type_method(is_nb_state,'get-state','get-state').
state_type_method(is_nb_state,value_iter,value_nb_iter).
%state_type_method(is_nb_state,query,state_nb_query).

% Clear all values from a state
clear_nb_values(StateNameOrInstance) :-
    fetch_or_create_state(StateNameOrInstance, State),
    nb_setarg(1, State, []).



% Function to confirm if a term represents a state
is_valid_nb_state(State):- compound(State),functor(State,'State',_).

% Find the original name of a given state
state_original_name(State, Name) :-
    is_registered_state(Name),
    call_in_shared_space(nb_current(Name, State)).

% Register and initialize a new state
init_state(Name) :-
    State = 'State'(_,_),
    asserta(is_registered_state(Name)),
    call_in_shared_space(nb_setval(Name, State)).

% Change a value in a state
'change-state!'(Depth,Self,StateNameOrInstance, UpdatedValue, Out) :-
    fetch_or_create_state(StateNameOrInstance, State),
    arg(2, State, Type),
    ( (check_type,\+ get_type(Depth,Self,UpdatedValue,Type))
     -> (Out = ['Error', UpdatedValue, 'BadType'])
     ; (nb_setarg(1, State, UpdatedValue), Out = State) ).

% Fetch all values from a state
'get-state'(StateNameOrInstance, Values) :-
    fetch_or_create_state(StateNameOrInstance, State),
    arg(1, State, Values).

'new-state'(Depth,Self,Init,'State'(Init, Type)):- check_type->get_type(Depth,Self,Init,Type);true.

'new-state'(Init,'State'(Init, Type)):- check_type->get_type(10,'&self',Init,Type);true.

fetch_or_create_state(Name):- fetch_or_create_state(Name,_).
% Fetch an existing state or create a new one

fetch_or_create_state(State, State) :- is_valid_nb_state(State),!.
fetch_or_create_state(NameOrInstance, State) :-
    (   atom(NameOrInstance)
    ->  (is_registered_state(NameOrInstance)
        ->  nb_current(NameOrInstance, State)
        ;   init_state(NameOrInstance),
            nb_current(NameOrInstance, State))
    ;   is_valid_nb_state(NameOrInstance)
    ->  State = NameOrInstance
    ;   writeln('Error: Invalid input.')
    ),
    is_valid_nb_state(State).

% =================================================================
% =================================================================
% =================================================================
%  GET-TYPE
% =================================================================
% =================================================================
% =================================================================

eval_20(Eq,RetType,Depth,Self,['get-type',Val],TypeO):- !,
  eval_get_type(Eq,RetType,Depth,Self,Val,TypeO).


eval_get_type(Eq,RetType,Depth,Self,Val,TypeO):- 
  get_type(Depth,Self,Val,Type),ground(Type),Type\==[], Type\==Val,!,
  do_expander(Eq,RetType,Type,TypeO).



eval_20(Eq,RetType,Depth,Self,['length',L],Res):- !, eval(Eq,RetType,Depth,Self,L,LL), !, (is_list(LL)->length(LL,Res);Res=1).
eval_20(Eq,RetType,Depth,Self,['CountElement',L],Res):- !, eval(Eq,RetType,Depth,Self,L,LL), !, (is_list(LL)->length(LL,Res);Res=1).

eval_20(_Eq,_RetType,_Depth,_Self,['get-metatype',Val],TypeO):- !,
  get_metatype(Val,TypeO).

get_metatype(Val,Want):- get_metatype0(Val,Was),!,Want=Was.
get_metatype0(Val,'Variable'):- var(Val).
get_metatype0(Val,'Symbol'):- symbol(Val).
get_metatype0(Val,'Expression'):- is_list(Val).
get_metatype0(_Val,'Grounded').





% =================================================================
% =================================================================
% =================================================================
%  IMPORT/BIND
% =================================================================
% =================================================================
% =================================================================
nb_bind(Name,Value):- nb_current(Name,Was),same_term(Value,Was),!.
nb_bind(Name,Value):- call_in_shared_space(nb_setval(Name,Value)),!.
eval_20(Eq,RetType,Depth,Self,['import!',Other,File],RetVal):- !,
     (( into_space(Depth,Self,Other,Space), include_metta(Space,File),!,return_empty(Space,RetVal))),
     check_returnval(Eq,RetType,RetVal). %RetVal=[].
eval_20(Eq,RetType,_Depth,_Slf,['bind!',Other,['new-space']],RetVal):- atom(Other),!,assert(was_asserted_space(Other)),
  return_empty([],RetVal), check_returnval(Eq,RetType,RetVal).
eval_20(Eq,RetType,Depth,Self,['bind!',Other,Expr],RetVal):- !,
   must_det_ll((into_name(Self,Other,Name),!,eval(Eq,RetType,Depth,Self,Expr,Value),
    nb_bind(Name,Value),  return_empty(Value,RetVal))),
   check_returnval(Eq,RetType,RetVal).
eval_20(Eq,RetType,Depth,Self,['pragma!',Other,Expr],RetVal):- !,
   must_det_ll((into_name(Self,Other,Name),nd_ignore((eval(Eq,RetType,Depth,Self,Expr,Value),
   set_option_value_interp(Name,Value))),  return_empty(Value,RetVal),
    check_returnval(Eq,RetType,RetVal))).
eval_20(Eq,RetType,_Dpth,Self,['transfer!',File],RetVal):- !, must_det_ll((include_metta(Self,File),
   return_empty(Self,RetVal),check_returnval(Eq,RetType,RetVal))).


fromNumber(Var1,Var2):- var(Var1),var(Var2),!,freeze(Var1,fromNumber(Var1,Var2)),freeze(Var2,fromNumber(Var1,Var2)).
fromNumber(0,'Z'):-!.
fromNumber(N,['S',Nat]):- integer(N), M is N -1,!,fromNumber(M,Nat).

eval_20(Eq,RetType,Depth,Self,['fromNumber',NE],RetVal):- !,
   eval('=','Number',Depth,Self,NE,N),
	fromNumber(N,RetVal), check_returnval(Eq,RetType,RetVal).

eval_20(Eq,RetType,Depth,Self,['dedup!',Eval],RetVal):- !,
   term_variables(Eval+RetVal,Vars),
   no_repeats_var(YY),!,
   eval_20(Eq,RetType,Depth,Self,Eval,RetVal),YY=Vars.


nd_ignore(Goal):- call(Goal)*->true;true.









% =================================================================
% =================================================================
% =================================================================
%  AND/OR
% =================================================================
% =================================================================
% =================================================================

is_True(T):- atomic(T), T\=='False', T\==0.

is_and(S):- \+ atom(S),!,fail.
is_and(',').
is_and(S):- is_and(S,_).

is_and(S,_):- \+ atom(S),!,fail.
is_and('and','True').
is_and('and2','True').
is_and('#COMMA','True'). is_and(',','True').  % is_and('And').

is_comma(C):- var(C),!,fail.
is_comma(',').
is_comma('{}').

eval_20(Eq,RetType,Depth,Self,[And,X],True):- is_comma(And),!, eval_args(Eq,RetType,Depth,Self,X,True).
eval_20(Eq,RetType,Depth,Self,[And,X,Y],TF):-  is_comma(And),!, eval_args(Eq,RetType,Depth,Self,X,_),eval_args(Eq,RetType,Depth,Self,Y,TF).
eval_20(Eq,RetType,Depth,Self,[And,X|Y],TF):- is_comma(And),!, eval_args(Eq,RetType,Depth,Self,X,_), eval_args(Eq,RetType,Depth,Self,[And|Y],TF).


eval_20(Eq,RetType,_Dpth,_Slf,[And],True):- is_and(And,True),!,check_returnval(Eq,RetType,True).
%eval_20(Eq,RetType,Depth,Self,[And,X,Y],TF):-  is_and(And,True),!,
% as_tf(( eval_args(Eq,RetType,Depth,Self,X,True),eval_args(Eq,RetType,Depth,Self,Y,True)),TF).
eval_20(Eq,RetType,Depth,Self,[And,X],TF):- is_and(And,True),!, as_tf(eval_args(Eq,RetType,Depth,Self,X,True),TF).
eval_20(Eq,RetType,Depth,Self,[And,X|Y],TF):- is_and(And,True),!, as_tf(eval_args(Eq,RetType,Depth,Self,X,True),TF1),
  (TF1=='False' -> TF=TF1 ; eval_args(Eq,RetType,Depth,Self,[And|Y],TF)).

eval_20(Eq,RetType,Depth,Self,['or',X,Y],TF):- !,
   as_tf((eval_args_true(Eq,RetType,Depth,Self,X);eval_args_true(Eq,RetType,Depth,Self,Y)),TF).

eval_20(Eq,RetType,Depth,Self,['not',X],TF):- !,
   as_tf(( \+ eval_args_true(Eq,RetType,Depth,Self,X)), TF).

eval_20(Eq,RetType,Depth,Self,['number-of',X],N):- !,
   bagof_eval(Eq,RetType,Depth,Self,X,ResL),
   length(ResL,N), ignore(RetType='Number').

eval_20(Eq,RetType,Depth,Self,['number-of',X,N],TF):- !,
   bagof_eval(Eq,RetType,Depth,Self,X,ResL),
   length(ResL,N), true_type(Eq,RetType,TF).


eval_20(Eq,RetType,Depth,Self,['limit!',N,E],R):- !, eval_20(Eq,RetType,Depth,Self,['limit',N,E],R).
eval_20(Eq,RetType,Depth,Self,['limit',NE,E],R):-  !,
   eval('=','Number',Depth,Self,NE,N),
   limit(N,eval_ne(Eq,RetType,Depth,Self,E,R)).

eval_20(Eq,RetType,Depth,Self,['max-time!',N,E],R):- !, eval_20(Eq,RetType,Depth,Self,['max-time',N,E],R).
eval_20(Eq,RetType,Depth,Self,['max-time',NE,E],R):-  !,
   eval('=','Number',Depth,Self,NE,N),
   cwtl(N,eval_ne(Eq,RetType,Depth,Self,E,R)).


% =================================================================
% =================================================================
% =================================================================
%  DATA FUNCTOR
% =================================================================
% =================================================================
% =================================================================
eval20_failked(Eq,RetType,Depth,Self,[V|VI],[V|VO]):-
    nonvar(V),is_metta_data_functor(V),is_list(VI),!,
    maplist(eval(Eq,RetType,Depth,Self),VI,VO).


% =================================================================
% =================================================================
% =================================================================
%  EVAL FAILED
% =================================================================
% =================================================================
% =================================================================

eval_failed(Depth,Self,T,TT):-
  finish_eval(Depth,Self,T,TT).

%finish_eval(_,_,X,X):-!.

finish_eval(_Dpth,_Slf,T,TT):- var(T),!,TT=T.
finish_eval(_Dpth,_Slf,[],[]):-!.
finish_eval(_Dpth,_Slf,[F|LESS],Res):- once(eval_selfless([F|LESS],Res)),fake_notrace([F|LESS]\==Res),!.
%finish_eval(Depth,Self,[V|Nil],[O]):- Nil==[], once(eval(Eq,RetType,Depth,Self,V,O)),V\=@=O,!.
finish_eval(Depth,Self,[H|T],[HH|TT]):- !, eval(Depth,Self,H,HH), finish_eval(Depth,Self,T,TT).
finish_eval(Depth,Self,T,TT):- eval(Depth,Self,T,TT).

   %eval(Eq,RetType,Depth,Self,X,Y):- eval_20(Eq,RetType,Depth,Self,X,Y)*->true;Y=[].

%eval_20(Eq,RetType,Depth,_,_,_):- Depth<1,!,fail.
%eval_20(Eq,RetType,Depth,_,X,Y):- Depth<3, !, ground(X), (Y=X).
%eval_20(Eq,RetType,_Dpth,_Slf,X,Y):- self_eval(X),!,Y=X.

% Kills zero arity functions eval_20(Eq,RetType,Depth,Self,[X|Nil],[Y]):- Nil ==[],!,eval(Eq,RetType,Depth,Self,X,Y).



% =================================================================
% =================================================================
% =================================================================
%  METTLOG PREDEFS
% =================================================================
% =================================================================
% =================================================================


eval_20(Eq,RetType,_Dpth,_Slf,['arity',F,A],TF):- !,as_tf(current_predicate(F/A),TF),check_returnval(Eq,RetType,TF).
eval_20(Eq,RetType,Depth,Self,['CountElement',L],Res):- !, eval(Eq,RetType,Depth,Self,L,LL), !, (is_list(LL)->length(LL,Res);Res=1),check_returnval(Eq,RetType,Res).
eval_20(Eq,RetType,_Dpth,_Slf,['make_list',List],MettaList):- !, into_metta_cons(List,MettaList),check_returnval(Eq,RetType,MettaList).


eval_20(Eq,RetType,Depth,Self,['maplist!',Pred,ArgL1],ResL):- !,
      maplist(eval_pred(Eq,RetType,Depth,Self,Pred),ArgL1,ResL).
eval_20(Eq,RetType,Depth,Self,['maplist!',Pred,ArgL1,ArgL2],ResL):- !,
      maplist(eval_pred(Eq,RetType,Depth,Self,Pred),ArgL1,ArgL2,ResL).
eval_20(Eq,RetType,Depth,Self,['maplist!',Pred,ArgL1,ArgL2,ArgL3],ResL):- !,
      maplist(eval_pred(Eq,RetType,Depth,Self,Pred),ArgL1,ArgL2,ArgL3,ResL).

  eval_pred(Eq,RetType,Depth,Self,Pred,Arg1,Res):-
      eval(Eq,RetType,Depth,Self,[Pred,Arg1],Res).
  eval_pred(Eq,RetType,Depth,Self,Pred,Arg1,Arg2,Res):-
      eval(Eq,RetType,Depth,Self,[Pred,Arg1,Arg2],Res).
  eval_pred(Eq,RetType,Depth,Self,Pred,Arg1,Arg2,Arg3,Res):-
      eval(Eq,RetType,Depth,Self,[Pred,Arg1,Arg2,Arg3],Res).

eval_20(Eq,RetType,Depth,Self,['concurrent-maplist!',Pred,ArgL1],ResL):- !,
      metta_concurrent_maplist(eval_pred(Eq,RetType,Depth,Self,Pred),ArgL1,ResL).
eval_20(Eq,RetType,Depth,Self,['concurrent-maplist!',Pred,ArgL1,ArgL2],ResL):- !,
      concurrent_maplist(eval_pred(Eq,RetType,Depth,Self,Pred),ArgL1,ArgL2,ResL).
eval_20(Eq,RetType,Depth,Self,['concurrent-maplist!',Pred,ArgL1,ArgL2,ArgL3],ResL):- !,
      concurrent_maplist(eval_pred(Eq,RetType,Depth,Self,Pred),ArgL1,ArgL2,ArgL3,ResL).
eval_20(Eq,RetType,Depth,Self,['concurrent-forall!',Gen,Test|Options],Empty):- !,
      maplist(s2p,Options,POptions),
      call(thread:concurrent_forall(
            user:eval_ne(Eq,RetType,Depth,Self,Gen,_),
            user:forall(eval(Eq,RetType,Depth,Self,Test,_),true),
            POptions)),
     return_empty([],Empty).

eval_20(Eq,RetType,Depth,Self,['hyperpose',ArgL],Res):- !, metta_hyperpose(Eq,RetType,Depth,Self,ArgL,Res).


simple_math(Var):- attvar(Var),!,fail.
simple_math([F|XY]):- !, atom(F),atom_length(F,1), is_list(XY),maplist(simple_math,XY).
simple_math(X):- number(X),!.


eval_20(Eq,RetType,Depth,Self,X,Y):-
  (eval_40(Eq,RetType,Depth,Self,X,M)*-> M=Y ;
     % finish_eval(Depth,Self,M,Y);
    (eval_failed(Depth,Self,X,Y)*->true;X=Y)).

eval_40(_Eq,_RetType,_Dpth,_Slf,['extend-py!',Module],Res):-  !, 'extend-py!'(Module,Res).

/*
into_values(List,Many):- List==[],!,Many=[].
into_values([X|List],Many):- List==[],is_list(X),!,Many=X.
into_values(Many,Many).
eval_40(Eq,RetType,_Dpth,_Slf,Name,Value):- atom(Name), nb_current(Name,Value),!.
*/
% Macro Functions
%eval_20(Eq,RetType,Depth,_,_,_):- Depth<1,!,fail.
eval_40(_Eq,_RetType,Depth,_,X,Y):- Depth<3, !, fail, ground(X), (Y=X).
eval_40(Eq,RetType,Depth,Self,[F|PredDecl],Res):- 
   fail,
   Depth>1,
   fake_notrace((sub_sterm1(SSub,PredDecl), ground(SSub),SSub=[_|Sub], is_list(Sub), maplist(atomic,SSub))),
   eval(Eq,RetType,Depth,Self,SSub,Repl),
   fake_notrace((SSub\=Repl, subst(PredDecl,SSub,Repl,Temp))),
   eval(Eq,RetType,Depth,Self,[F|Temp],Res).

% =================================================================
% =================================================================
% =================================================================
%  PLUS/MINUS
% =================================================================
% =================================================================
% =================================================================
eval_40(_Eq,_RetType,_Dpth,_Slf,LESS,Res):-
   ((((eval_selfless(LESS,Res),fake_notrace(LESS\==Res))))),!.

eval_40(Eq,RetType,Depth,Self,['+',N1,N2],N):- number(N1),!,
   eval(Eq,RetType,Depth,Self,N2,N2Res), fake_notrace(catch_err(N is N1+N2Res,_E,(set_last_error(['Error',N2Res,'Number']),fail))).
eval_40(Eq,RetType,Depth,Self,['-',N1,N2],N):- number(N1),!,
   eval(Eq,RetType,Depth,Self,N2,N2Res), fake_notrace(catch_err(N is N1-N2Res,_E,(set_last_error(['Error',N2Res,'Number']),fail))).
eval_40(Eq,RetType,Depth,Self,['*',N1,N2],N):- number(N1),!,
   eval(Eq,RetType,Depth,Self,N2,N2Res), fake_notrace(catch_err(N is N1*N2Res,_E,(set_last_error(['Error',N2Res,'Number']),fail))).

eval_40(Eq,RetType,Depth,Self,['length',L],Res):- !, eval(Depth,Self,L,LL),
   (is_list(LL)->length(LL,Res);Res=1),
   check_returnval(Eq,RetType,Res).



eval_40(Eq,RetType,Depth,Self,[P,A,X|More],YY):- is_list(X),X=[_,_,_],simple_math(X),
   eval_selfless_2(X,XX),X\=@=XX,!,
   eval_40(Eq,RetType,Depth,Self,[P,A,XX|More],YY).

eval_40(Eq,RetType,_Dpth,_Slf,['==',X,Y],Res):-  !,
    suggest_type(RetType,'Bool'),
    eq_unify(Eq,_SharedType, X, Y, Res).

eq_unify(_Eq,_SharedType, X, Y, TF):- as_tf(X=:=Y,TF),!.
eq_unify(_Eq,_SharedType, X, Y, TF):- as_tf( '#='(X,Y),TF),!.
eq_unify( Eq,  SharedType, X, Y, TF):- as_tf(eval_until_unify(Eq,SharedType, X, Y), TF).


suggest_type(_RetType,_Bool).

eval_40(Eq,RetType,Depth,Self,[AE|More],Res):- fail, %is_special_op(AE),!,
  eval_70(Eq,RetType,Depth,Self,[AE|More],Res),
  check_returnval(Eq,RetType,Res).

eval_40(Eq,RetType,Depth,Self,[AE|More],Res):- % fail,
  maplist(must_eval_args(Eq,_,Depth,Self),More,Adjusted),
  eval_70(Eq,RetType,Depth,Self,[AE|Adjusted],Res),
  check_returnval(Eq,RetType,Res).


must_eval_args(Eq,RetType,Depth,Self,More,Adjusted):-
   (eval_args(Eq,RetType,Depth,Self,More,Adjusted)*->true;
      (with_debug(eval,eval_args(Eq,RetType,Depth,Self,More,Adjusted))*-> true;
         (
           nl,writeq(eval_args(Eq,RetType,Depth,Self,More,Adjusted)),writeln('.'),
             (More=Adjusted -> true ;
                (trace, throw(must_eval_args(Eq,RetType,Depth,Self,More,Adjusted))))))).



eval_70(Eq,RetType,Depth,Self,PredDecl,Res):-
  Do_more_defs = do_more_defs(true),
  clause(eval_80(Eq,RetType,Depth,Self,PredDecl,Res),Body),
  Do_more_defs == do_more_defs(true),
  call_ndet(Body,DET),
  nb_setarg(1,Do_more_defs,false),
 (DET==true -> ! ; true).

% =================================================================
% =================================================================
% =================================================================
% inherited by system
% =================================================================
% =================================================================
% =================================================================
is_system_pred(S):- atom(S),atom_concat(_,'!',S).
is_system_pred(S):- atom(S),atom_concat(_,'-fn',S).
is_system_pred(S):- atom(S),atom_concat(_,'-p',S).

% eval_80/6: Evaluates a Python function call within MeTTa.
% Parameters:
% - Eq: denotes get-type, match, or interpret call.
% - RetType: Expected return type of the MeTTa function.
% - Depth: Recursion depth or complexity control.
% - Self: Context or environment for the evaluation.
% - [MyFun|More]: List with MeTTa function and additional arguments.
% - RetVal: Variable to store the result of the Python function call.
eval_80(Eq, RetType, Depth, Self, [MyFun|More], RetVal) :-
    % MyFun as a registered Python function with its module and function name.
    metta_atom(Self, ['registered-python-function', PyModule, PyFun, MyFun]),
    % Tries to fetch the type definition for MyFun, ignoring failures.
    ((  get_operator_typedef(Self, MyFun, Params, RetType),
        try_adjust_arg_types(RetType, Depth, Self, [RetType|Params], [RetVal|More], [MVal|Adjusted])
    )->true; (maplist(as_prolog, More , Adjusted), MVal=RetVal)),
    % Constructs a compound term for the Python function call with adjusted arguments.
    compound_name_arguments(Call, PyFun, Adjusted),
    % Optionally prints a debug tree of the Python call if tracing is enabled.
    if_trace(host;python, print_tree(py_call(PyModule:Call, RetVal))),
    % Executes the Python function call and captures the result in MVal which propagates to RetVal.
    py_call(PyModule:Call, MVal),
    % Checks the return value against the expected type and criteria.
    check_returnval(Eq, RetType, RetVal).



%eval_80(_Eq,_RetType,_Dpth,_Slf,LESS,Res):- fake_notrace((once((eval_selfless(LESS,Res),fake_notrace(LESS\==Res))))),!.

% predicate inherited by system
eval_80(Eq,RetType,_Depth,_Self,[AE|More],TF):-
  once((is_system_pred(AE),
  length(More,Len),
  is_syspred(AE,Len,Pred))),
  \+ (atom(AE),   atom_concat(_,'-fn',AE)),
  current_predicate(Pred/Len),
  %fake_notrace( \+ is_user_defined_goal(Self,[AE|More])),!,
  %adjust_args(Depth,Self,AE,More,Adjusted),
  maplist(as_prolog, More , Adjusted),
  if_trace(host;prolog,print_tree(apply(Pred,Adjusted))),
  catch_warn(efbug(show_call,eval_call(apply(Pred,Adjusted),TF))),
  check_returnval(Eq,RetType,TF).

show_ndet(G):- call(G).
%show_ndet(G):- call_ndet(G,DET),(DET==true -> ! ; fbug(show_ndet(G))).

:- if( \+  current_predicate( adjust_args / 2 )).

   :- discontiguous eval_80/6.

is_user_defined_goal(Self,Head):-
  is_user_defined_head(Self,Head).

:- endif.

adjust_args_mp(_Eq,_RetType,Res,Res,_Depth,_Self,_Pred,_Len,_AE,Args,Adjusted):- Args==[],!,Adjusted=Args.
adjust_args_mp(Eq,RetType,Res,NewRes,Depth,Self,Pred,Len,AE,Args,Adjusted):-
   functor(P,Pred,Len), predicate_property(P,meta_predicate(Needs)),
   account_needs(1,Needs,Args,More),!,
   adjust_args(Eq,RetType,Res,NewRes,Depth,Self,AE,More,Adjusted).
adjust_args_mp(Eq,RetType,Res,NewRes,Depth,Self,_Pred,_Len,AE,Args,Adjusted):-
   adjust_args(Eq,RetType,Res,NewRes,Depth,Self,AE,Args,Adjusted).

acct(0,A,call(eval(A,_))).
acct(':',A,call(eval(A,_))).
acct(_,A,A).
account_needs(_,_,[],[]).
account_needs(N,Needs,[A|Args],[M|More]):- arg(N,Needs,What),!,
   acct(What,A,M),plus(1,N,NP1),
   account_needs(NP1,Needs,Args,More).

:- nodebug(metta(call)).

s2ps(S,P):- S=='Nil',!,P=[].
s2ps(S,P):- \+ is_list(S),!,P=S.
s2ps([F|S],P):- atom(F),maplist(s2ps,S,SS),join_s2ps(F,SS,P),!.
s2ps(S,S):-!.
join_s2ps('Cons',[H,T],[H|T]):-!.
join_s2ps(F,Args,P):-atom(F),P=..[F|Args].

eval_call(S,TF):-
  s2ps(S,P), !,
  fbug(eval_call(P,'$VAR'('TF'))),as_tf(P,TF).

eval_80(Eq,RetType,_Depth,_Self,[AE|More],Res):-
  is_system_pred(AE),
  length([AE|More],Len),
  is_syspred(AE,Len,Pred),
  \+ (atom(AE), atom_concat(_,'-p',AE)),
  %fake_notrace( \+ is_user_defined_goal(Self,[AE|More])),!,
  %adjust_args(Depth,Self,AE,More,Adjusted),!,
  Len1 is Len+1,
  current_predicate(Pred/Len1),
  maplist(as_prolog,More,Adjusted),
  append(Adjusted,[Res],Args),!,  
  if_trace(host;prolog,print_tree(apply(Pred,Args))),
  efbug(show_call,catch_warn(apply(Pred,Args))),
  check_returnval(Eq,RetType,Res).

:- if( \+  current_predicate( check_returnval / 3 )).
check_returnval(_,_RetType,_TF).
:- endif.

:- if( \+  current_predicate( adjust_args / 5 )).
adjust_args(_Depth,_Self,_V,VI,VI).
:- endif.

% user defined function
%eval_40(Eq,RetType,Depth,Self,[H|PredDecl],Res):-
 %  fake_notrace(is_user_defined_head(Self,H)),!,
 %  eval_60(Eq,RetType,Depth,Self,[H|PredDecl],Res).

eval_80(Eq,RetType,Depth,Self,PredDecl,Res):-
    eval_60(Eq,RetType,Depth,Self,PredDecl,Res).


last_element(T,E):- \+ compound(T),!,E=T.
last_element(T,E):- is_list(T),last(T,L),last_element(L,E),!.
last_element(T,E):- compound_name_arguments(T,_,List),last_element(List,E),!.




catch_warn(G):- quietly(catch_err(G,E,(fbug(catch_warn(G)-->E),fail))).
catch_nowarn(G):- quietly(catch_err(G,error(_,_),fail)).


% less Macro-ey Functions


as_tf(G,TF):-  G\=[_|_], catch_nowarn((call(G)*->TF='True';TF='False')).
%eval_selfless_1(['==',X,Y],TF):- as_tf(X=:=Y,TF),!.
%eval_selfless_1(['==',X,Y],TF):- as_tf(X=@=Y,TF),!.

is_assignment(V):- \+ atom(V),!, fail.
is_assignment('is'). is_assignment('is!').
is_assignment('='). is_assignment('==').
is_assignment('=:=').  is_assignment(':=').

eval_selfless(E,R):-  eval_selfless_0(E,R).

eval_selfless_0([F,X,XY],TF):- is_assignment(F),  fake_notrace(args_to_mathlib([X,XY],Lib)),!,eval_selfless3(Lib,['=',X,XY],TF).
eval_selfless_0([F|XY],TF):- eval_selfless_1([F|XY],TF),!.
eval_selfless_0(E,R):- eval_selfless_2(E,R).

eval_selfless_1([F|XY],TF):- \+ ground(XY),!,fake_notrace(args_to_mathlib(XY,Lib)),!,eval_selfless3(Lib,[F|XY],TF).
eval_selfless_1(['>',X,Y],TF):-!,as_tf(X>Y,TF).
eval_selfless_1(['<',X,Y],TF):-!,as_tf(X<Y,TF).
eval_selfless_1(['=>',X,Y],TF):-!,as_tf(X>=Y,TF).
eval_selfless_1(['<=',X,Y],TF):-!,as_tf(X=<Y,TF).
eval_selfless_1(['\\=',X,Y],TF):-!,as_tf(dif(X,Y),TF).

eval_selfless_2(['%',X,Y],TF):-!,eval_selfless_2(['mod',X,Y],TF).
eval_selfless_2(LIS,Y):-  fake_notrace(( ground(LIS),
   LIS=[F,_,_], atom(F), catch_warn(current_op(_,yfx,F)),
   LIS\=[_], s2ps(LIS,IS))), fake_notrace(catch((Y is IS),_,fail)),!.


eval_selfless3(Lib,FArgs,TF):- maplist(s2ps,FArgs,Next),!,compare_selfless0(Lib,Next,TF).

:- use_module(library(clpfd)).
:- clpq:use_module(library(clpq)).
:- clpr:use_module(library(clpr)).

compare_selfless0(_,[F|_],_TF):- \+ atom(F),!,fail.
compare_selfless0(cplfd,['=',X,Y],TF):-!,as_tf(X#=Y,TF).
compare_selfless0(cplfd,['\\=',X,Y],TF):-!,as_tf(X #\=Y,TF).
compare_selfless0(cplfd,['>',X,Y],TF):-!,as_tf(X#>Y,TF).
compare_selfless0(cplfd,['<',X,Y],TF):-!,as_tf(X#<Y,TF).
compare_selfless0(cplfd,['=>',X,Y],TF):-!,as_tf(X#>=Y,TF).
compare_selfless0(cplfd,['<=',X,Y],TF):-!,as_tf(X#=<Y,TF).
compare_selfless0(cplfd,[F|Stuff],TF):- !,atom_concat('#',F,SharpF),P=..[SharpF|Stuff],!,as_tf(P,TF).
compare_selfless0(Lib,['\\=',X,Y],TF):-!,as_tf(Lib:{X \=Y}, TF).
compare_selfless0(Lib,['=',X,Y],TF):-!,as_tf(Lib:{X =Y}, TF).
compare_selfless0(Lib,['>',X,Y],TF):-!,as_tf(Lib:{X>Y},TF).
compare_selfless0(Lib,['<',X,Y],TF):-!,as_tf(Lib:{X<Y},TF).
compare_selfless0(Lib,['=>',X,Y],TF):-!,as_tf(Lib:{X>=Y},TF).
compare_selfless0(Lib,['<=',X,Y],TF):-!,as_tf(Lib:{X=<Y},TF).
compare_selfless0(Lib,[F|Stuff],TF):- P=..[F|Stuff],!,as_tf(Lib:{P},TF).

args_to_mathlib(XY,Lib):- sub_term(T,XY), var(T),get_attrs(T,XX),get_attrlib(XX,Lib).
args_to_mathlib(XY,clpr):- once((sub_term(T,XY), float(T))). % Reals
args_to_mathlib(XY,clpq):- once((sub_term(Rat,XY),compound(Rat),Rat='/'(_,_))).
args_to_mathlib(_,clpfd).


get_attrlib(XX,clpfd):- sub_var(clpfd,XX),!.
get_attrlib(XX,clpq):- sub_var(clpr,XX),!.
get_attrlib(XX,clpr):- sub_var(clpr,XX),!.

% =================================================================
% =================================================================
% =================================================================
%  USER DEFINED FUNCTIONS
% =================================================================
% =================================================================
% =================================================================

call_ndet(Goal,DET):- call(Goal),deterministic(DET),(DET==true->!;true).

/*
eval_60(Eq,_RetT,Depth,Self,[H|Args0],B):-
   \+ get_operator_typedef1(Self,H,_ParamTypes,_RType),!,
   maplist(eval_99(Eq,_,Depth,Self),Args0,Args),
   eval_65(Eq,RetType,Depth,Self,[H|Args],B),!.
*/
/*
eval_60(Eq,_RetT,Depth,Self,[H|Args0],B):- symbol(H),
  \+ fake_notrace((is_user_defined_head_f(Self,H))),
   \+ get_operator_typedef1(Self,H,_ParamTypes,_RType),!,
   maplist(eval_99(Eq,_,Depth,Self),Args0,Args),
   eval_65(Eq,RetType,Depth,Self,[H|Args],B),!.
*/
eval_60(Eq,RetType,Depth,Self,H,B):-
   (eval_64(Eq,RetType,Depth,Self,H,B)*->true;
     (fail,eval_67(Eq,RetType,Depth,Self,H,B))).


%eval_64(Eq,_RetType,_Dpth,Self,H,B):-  Eq='=',!, metta_defn(Eq,Self,H,B).
eval_64(Eq,_RetType,_Dpth,Self,H,B):-
   Eq=='match',!,call(metta_atom(Self,H)),B=H.


eval_64(Eq,RetType,Depth,Self,[[H|Start]|T1],Y):-
   fake_notrace((is_user_defined_head_f(Self,H),is_list(Start))),
   metta_defn(Eq,Self,[H|Start],Left),
   [Left|T1] \=@= [[H|Start]|T1],
   eval(Eq,RetType,Depth,Self,[Left|T1],Y).

eval_64(Eq,_RetType,Depth,Self,[H|Args],B):- % no weird template matchers
  % forall(metta_defn(Eq,Self,[H|Template],_),
  %    maplist(not_template_arg,Template)),
   Eq='=',
   (metta_defn(Eq,Self,[H|Args],B0)*->true;(fail,[H|Args]=B0)),
   light_eval(Depth,Self,B0,B).
    %(eval(Eq,RetType,Depth,Self,B,Y);metta_atom_iter(Depth,Self,Y)).
% Use the first template match
eval_65(Eq,_RetType,Depth,Self,[H|Args],B):-
   Eq='=',
  (metta_defn(Eq,Self,[H|Template],B0),Args=Template),
  light_eval(Depth,Self,B0,B).


light_eval(_Depth,_Self,B,B).

not_template_arg(TArg):- var(TArg), !, \+ attvar(TArg).
not_template_arg(TArg):- atomic(TArg),!.
%not_template_arg(TArg):- is_list(TArg),!,fail.


% Has argument that is headed by the same function
eval_67(Eq,RetType,Depth,Self,[H1|Args],Res):-
   fake_notrace((append(Left,[[H2|H2Args]|Rest],Args), H2==H1)),!,
   eval(Eq,RetType,Depth,Self,[H2|H2Args],ArgRes),
   fake_notrace((ArgRes\==[H2|H2Args], append(Left,[ArgRes|Rest],NewArgs))),
   eval_60(Eq,RetType,Depth,Self,[H1|NewArgs],Res).

eval_67(Eq,RetType,Depth,Self,[[H|Start]|T1],Y):-
   fake_notrace((is_user_defined_head_f(Self,H),is_list(Start))),
   metta_defn(Eq,Self,[H|Start],Left),
   eval(Eq,RetType,Depth,Self,[Left|T1],Y).

% Has subterm to eval
eval_67(Eq,RetType,Depth,Self,[F|PredDecl],Res):- fail,
   Depth>1,
   quietly(sub_sterm1(SSub,PredDecl)),
   fake_notrace((ground(SSub),SSub=[_|Sub], is_list(Sub),maplist(atomic,SSub))),
   eval(Eq,RetType,Depth,Self,SSub,Repl),
   fake_notrace((SSub\=Repl,subst(PredDecl,SSub,Repl,Temp))),
   eval_60(Eq,RetType,Depth,Self,[F|Temp],Res).



% =================================================================
% =================================================================
% =================================================================
%  AGREGATES
% =================================================================
% =================================================================
% =================================================================

cwdl(DL,Goal):- call_with_depth_limit(Goal,DL,R), (R==depth_limit_exceeded->(!,fail);true).

cwtl(DL,Goal):- catch(call_with_time_limit(DL,Goal),time_limit_exceeded(_),fail).

%bagof_eval(Eq,RetType,Depth,Self,X,L):- bagof_eval(Eq,RetType,_RT,Depth,Self,X,L).


%bagof_eval(Eq,RetType,Depth,Self,X,S):- bagof(E,eval_ne(Eq,RetType,Depth,Self,X,E),S)*->true;S=[].
bagof_eval(_Eq,_RetType,_Dpth,_Slf,X,L):- typed_list(X,_Type,L),!.
bagof_eval(Eq,RetType,Depth,Self,X,L):-
   findall(E,eval_ne(Eq,RetType,Depth,Self,X,E),L).

setof_eval(Depth,Self,X,L):- setof_eval('=',_RT,Depth,Self,X,L).
setof_eval(Eq,RetType,Depth,Self,X,S):- bagof_eval(Eq,RetType,Depth,Self,X,L),
   sort(L,S).


eval_ne(Eq,RetType,Depth,Self,X,E):-
  eval(Eq,RetType,Depth,Self,X,E), \+ var(E), \+ is_empty(E).


:- ensure_loaded(metta_subst).

solve_quadratic(A, B, I, J, K) :-
    %X in -1000..1000,  % Define a domain for X
     (X + A) * (X + B) #= I*X*X + J*X + K.  % Define the quadratic equation
    %label([X]).  % Find solutions for X

