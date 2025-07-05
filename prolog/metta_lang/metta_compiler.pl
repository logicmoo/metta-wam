﻿/*
 * Project: MeTTaLog - A MeTTa to Prolog Transpiler/Interpreter
 * Description: This file is part of the source code for a transpiler designed to convert
 *              MeTTa language programs into Prolog, utilizing the SWI-Prolog compiler for
 *              optimizing and transforming function/logic programs. It handles different
 *              logical constructs and performs conversions between functions and predicates.
 *
 * Author: Douglas R. Miles
 * Contact: logicmoo@gmail.com / dmiles@logicmoo.org
 * License: LGPL
 * Repository: https://github.com/trueagi-io/metta-wam
 *             https://github.com/logicmoo/hyperon-wam
 * Created Date: 8/23/2023
 * Last Modified: $LastChangedDate$  # You will replace this with Git automation
 *
 * Usage: This file is a part of the transpiler that transforms MeTTa programs into Prolog. For details
 *        on how to contribute or use this project, please refer to the repository README or the project documentation.
 *
 * Contribution: Contributions are welcome! For contributing guidelines, please check the CONTRIBUTING.md
 *               file in the repository.
 *
 * Notes:
 * - Ensure you have SWI-Prolog installed and properly configured to use this transpiler.
 * - This project is under active development, and we welcome feedback and contributions.
 *
 * Acknowledgments: Special thanks to all contributors and the open source community for their support and contributions.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

% ==============================
% Prolog to MeTTa transpilation (which uses the Host SWI-Prolog compiler)
% This Prolog code block is mainly aimed at compiling/optimizing and transforming
% Prolog predicates to functional equivalents and vice versa, with special attention
% to handling different logical constructs and performing conversions between
% functions and predicates.
% ==============================

% Setting the file encoding to ISO-Latin-1
%:- encoding(iso_latin_1).
% Flushing the current output
:- flush_output.
% Setting the Rust backtrace to Full
:- setenv('RUST_BACKTRACE',full).
% Loading various library files
:- ensure_loaded(swi_support).
:- ensure_loaded(metta_testing).
:- ensure_loaded(metta_utils).
%:- ensure_loaded(metta_reader).
:- ensure_loaded(metta_interp).
:- ensure_loaded(metta_space).
:- ensure_loaded(metta_compiler_print).
:- dynamic(transpiler_clause_store/9).
:- multifile(transpiler_predicate_store/7).
:- dynamic(transpiler_predicate_store/7).
:- dynamic(transpiler_predicate_nary_store/9).
:- discontiguous transpiler_predicate_nary_store/9.
:- discontiguous(compile_flow_control/8).
:- multifile(compile_flow_control/8).
:- ensure_loaded(metta_compiler_lib).
%:- ensure_loaded(metta_compiler_lib_stdlib).

non_arg_violation(_,_,_).

% ==============================
% MeTTa to Prolog transpilation (which uses the Host SWI-Prolog compiler)
% Aimed at compiling/optimizing and transforming
% Prolog predicates to functional equivalents and vice versa, with special attention
% to handling different logical constructs and performing conversions between
% functions and predicates.
% ==============================
:- dynamic(metta_compiled_predicate/3).
:- multifile(metta_compiled_predicate/3).

builtin_metta_function(F/A):- integer(A),atom(F),!,compound_name_arity(P,F,A),builtin_metta_function(P).
%builtin_metta_function(Hc):- predicate_property(Hc,static),!.
builtin_metta_function(Hc):- source_file(Hc,File),(source_file(this_is_in_compiler_lib,File);source_file(scan_exists_in_interp,File)),!.

%in_to_out(FnName,_,[I],[O],cva(FnName,0,I,O)):-!.
in_to_out(_,_,[],[],true):-!.
in_to_out(FnName,N,[I|ArgsIn],[O|ArgsOut],Out):- succ(N,M),
   in_to_out(FnName,M,ArgsIn,ArgsOut,More),
   combine_code(cva(FnName,N,I,O),More,Out).

cva(_,_,IO,IO).

%setup_mi_me(FnName,LenArgs,_InternalTypeArgs,_InternalTypeResult) :- !.
setup_mi_me(FnName,LenArgs,InternalTypeArgs,InternalTypeResult) :-
 must_det_lls((
    sum_list(LenArgs,LenArgsTotal),
    LenArgsTotalPlus1 is LenArgsTotal+1,
    create_prefixed_name('mc_',LenArgs,FnName,FnNameWPrefix),
    current_compiler_context(WasCompCtx),
    if_t(builtin_metta_function(FnName/LenArgsTotalPlus1),
      (set_option_value(compiler_context,builtin))),
    current_compiler_context(NowCompCtx),
    debug_info(always(setup_mi_me),setup_mi_me(NowCompCtx,FnName,LenArgs,InternalTypeArgs,InternalTypeResult)),
    length(AtomList0,LenArgsTotalPlus1),
    length(AtomList1,LenArgsTotalPlus1),
    append(ArgsIn,[RetValO],AtomList1),
    append(ArgsOut,[RetVal],AtomList0),
    in_to_out(FnName,1,ArgsIn,ArgsOut,HeToHi),!,

    %findall(Atom0, (between(1, LenArgsTotalPlus1, I0) ,Atom0='$VAR'(I0)), AtomList0),

    Hc =.. [FnNameWPrefix|AtomList0],
    create_prefixed_name('mi_',LenArgs,FnName,FnNameWMiPrefix),
    Hi =.. [FnNameWMiPrefix|AtomList0],
    create_prefixed_name('me_',LenArgs,FnName,FnNameWMePrefix),
    He =.. [FnNameWMePrefix|AtomList1],
    append(Eval,[RetVal],[FnName|AtomList0]),
    Bi = ci(true,FnName,LenArgsTotal,Eval,RetVal,true,Goal),
    % Bi =.. [ci,true,[],true,Goal],
    compiler_assertz(Hi:- ((Goal=Hc), Bi)),
    compiler_assertz(He:- ( HeToHi, Hi, cva(FnName,0,RetVal,RetValO))))),
    set_option_value(compiler_context,WasCompCtx).

setup_library_call(Source,FnName,LenArgs,MettaTypeArgs,MettaTypeResult,InternalTypeArgs,InternalTypeResult) :-
    (transpiler_predicate_store(_,FnName,LenArgs,_,_,_,_) -> true ;
      compiler_assertz(transpiler_predicate_store(Source,FnName,LenArgs,MettaTypeArgs,MettaTypeResult,InternalTypeArgs,InternalTypeResult))),
    setup_mi_me(FnName,LenArgs,InternalTypeArgs,InternalTypeResult)
    .


% =======================================
% TODO move non flybase specific code between here and the compiler
%:- ensure_loaded(flybase_main).
% =======================================
%:- set_option_value(encoding,utf8).

:- if(prolog_load_context(reloading,false)).
:- initialization(mutex_create(transpiler_mutex_lock)).
:- at_halt(mutex_destroy(transpiler_mutex_lock)).
:- endif.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% Global transpiler flags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%transpiler_enable_interpreter_calls.
transpiler_enable_interpreter_calls :- fail.

debug_format(Fmt,Args):- transpiler_debug(1,format_e(Fmt,Args)).

% format to go out the visable error console since stdout can be sometimes redirected like in the case of the LSP server
format_e(Fmt,Args):- stream_property(StdErr, file_no(2)), format(StdErr,Fmt,Args),flush_output(StdErr).

transpiler_debug(Level,Code) :- (option_value('debug-level',DLevel),DLevel>=Level -> call(Code) ; true).
%transpiler_debug(_Level,Code) :- call(Code).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% Debugging only: Flags to allow tracing of particular functions (may not be currently working)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- dynamic(transpiler_trace/1).
%transpiler_trace('backward-chain-q2').

:- dynamic(transpiler_trace_compile/1).
%transpiler_trace_compile('backward-chain-q2').

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% The predicates used to store the information and meta-information about transpiled code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:-dynamic(transpiler_stub_created/3).
% just so the transpiler_stub_created predicate always exists
% transpiler_stub_created(space,dummy,0).

:- dynamic(transpiler_stub_created/2).
% just so the transpiler_stub_created predicate always exists
% transpiler_stub_created(dummy,0).

:- dynamic(transpiler_depends_on/4).
% just so the transpiler_depends_on predicate always exists
% transpiler_depends_on(dummy1,0,dummy2,0).

% just so the transpiler_clause_store predicate always exists
% transpiler_clause_store(f,arity,clause_number,types,rettype,lazy,retlazy,head,body)
% transpiler_clause_store(dummy,0,0,[],'Any',[],x(doeval,eager,[]),dummy,dummy).

% just so the transpiler_predicate_store predicate always exists
% transpiler_predicate_store(source,f,arity,types,rettype,lazy,retlazy)
% transpiler_predicate_store(dummy,0,[],'Any',[],x(doeval,eager,[])).

% just so the transpiler_predicate_nary_store predicate always exists
% transpiler_predicate_nary_store(source,f,arity,types_fixed,type_variable,lazy_fixed,lazy_variable,retlazy)
% transpiler_predicate_nary_store(dummy,0,[],x(doeval,eager,[]),x(doeval,eager,[])).

:- dynamic(transpiler_stored_eval/3).
transpiler_stored_eval([],true,0).

'~..'(A,B):- a_f_args(A,B), cmpd4lst(A,B),!.
:- op(700,xfx,'~..').

a_f_args(_,B):- is_list(B),!.
a_f_args(A,_):- compound(A),!.
a_f_args(A,_):- atom(A),!.
a_f_args(_A,_B):- bt,!,ds,break,trace.


:- op(700,xfx,'@..').

A @.. B:- a_f_args(A,B), A=..B.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% Put any type definitions here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

arg_eval_props(Var,x(doeval,eager,[])):- fullvar(Var),!.
arg_eval_props(N,x(doeval,eager,[number])) :- atom(N),N='Number',!.
arg_eval_props(N,x(doeval,eager,[boolean])) :- atom(N),N='Bool',!.
arg_eval_props(N,x(doeval,lazy,[boolean])) :- atom(N),N='LazyBool',!.
arg_eval_props(N,x(doeval,eager,[])) :- atom(N),N='Any',!.
arg_eval_props(N,x(noeval,lazy,[])) :- atom(N),N='Atom',!.
arg_eval_props(N,x(noeval,eager,[])) :- atom(N),N='Expression',!.
arg_eval_props(['->'|ParamsFull],x(noeval,eager,[[predicate_call,[LenArgs],ParamProps,RetProps]])) :- !,
   append(Params,[Ret],ParamsFull),
   maplist(arg_eval_props,Params,ParamProps),
   arg_eval_props(Ret,RetProps),
   length(Params,LenArgs).
arg_eval_props(N,x(doeval,eager,[N])).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Infrastructure for dealing with lazy evaluation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Key (where expr is a non-evaluated expression corresponding to 'noeval',
% and exec is an expression to be evaluted corresponding to 'doeval'):
%  u = exec and expr combined result (universal)
%  U = exec and expr combined code
%  e = exec result (eval)
%  E = exec code
%  n = expr result (noeval)
%  N = expr code
%  C = common code tp be called before both the exec and expr cases


as_p1_exec(X,X) :- \+ compound(X), !.
% as_p1_exec(X,Y) :- as_p1_expr(X,S),eval(S,Y).
as_p1_exec(ispu(URet),URet) :- !.
as_p1_exec(ispuU(URet,UCode),URet) :- !, call(UCode).
as_p1_exec(ispeEn(ERet,ECode,_),ERet) :- !, call(ECode).
as_p1_exec(ispeEnN(ERet,ECode,_,_),ERet) :- !, call(ECode).
as_p1_exec(ispeEnNC(ERet,ECode,_,_,CCode),ERet) :- !, call(CCode),call(ECode).
as_p1_exec(rtrace(T),TRet) :- !, rtrace(as_p1_exec(T,TRet)).
as_p1_exec(call(P1,T),TRet) :- !, call(P1,as_p1_exec(T,TRet)).
%as_p1_exec(X,Y) :- as_p1_expr(X,S),eval(S,Y).
as_p1_exec(X,X) :- !.

as_p1_expr(X,X) :- \+ compound(X), !.
as_p1_expr(ispu(URet),URet) :- !.
as_p1_expr(ispuU(URet,UCode),URet) :- !, call(UCode).
as_p1_expr(ispeEn(_,_,NRet),NRet).
as_p1_expr(ispeEnN(_,_,NRet,NCode),NRet) :- !, call(NCode).
as_p1_expr(ispeEnNC(_,_,NRet,NCode,CCode),NRet) :- !,call(CCode),call(NCode).
as_p1_expr(rtrace(T),TRet) :- !, rtrace(as_p1_expr(T,TRet)).
as_p1_expr(call(P1,T),TRet) :- !, call(P1,as_p1_expr(T,TRet)).
as_p1_expr(X,X) :- !.

create_p1(URet,[],[ispu,URet]) :- !.
create_p1(URet,UCode,[ispuU,URet,UCode]) :- !.
create_p1(ERet,[],NRet,[],[ispu,ERet]) :- ERet==NRet,!.
create_p1(ERet,ECode,NRet,NCode,[ispuU,ERet,ECode]) :- [ERet,ECode]=[NRet,NCode],!.
create_p1(ERet,ECode,NRet,[],[ispeEn,ERet,ECode,NRet]) :- debug_format("0 ~q ~q\n",[ERet,ECode]),!.
create_p1(ERet,ECode,NRet,NCode,R) :- % try and combine code to prevent combinatorial explosion
   debug_format("1 ~q ~q\n",[ERet,ECode]),
   ((fullvar(ERet);ECode=@=true) -> true; trace),
   partial_combine_lists(ECode,NCode,CCode,ECode1,NCode1),
   (CCode=[] ->
      R=[ispeEnN,ERet,ECode,NRet,NCode]
   ;
      R=[ispeEnNC,ERet,ECode1,NRet,NCode1,CCode]).
%create_p1(ERet,ECode,NRet,NCode,[ispeEnN,ERet,ECode,NRet,NCode]).

% Combine code so that ispX clauses are not so large. NOTE: this is necessary to avoid combinatorial explosions
% partial_combine_lists(L1,L2,Lcomb,L1a,L2a)
partial_combine_lists([H1|L1],[H2|L2],[H1|Lcomb],L1a,L2a) :- H1==H2,!,
   partial_combine_lists(L1,L2,Lcomb,L1a,L2a).
partial_combine_lists(L1,L2,[],L1,L2).

is_proper_arg(O):- compound(O),iz_conz(O), \+ is_list(O),!,bt, trace.
is_proper_arg(_).
% This hook is called when an attributed var is unified
proper_list_attr:attr_unify_hook(_, Value) :- \+ compound(Value),!.
proper_list_attr:attr_unify_hook(_, Value) :- is_list(Value),!.
proper_list_attr:attr_unify_hook(_, Value) :- iz_conz(Value),!,trace.
proper_list_attr:attr_unify_hook(_, _Value).
% Attach the attribute if not already present and not already a proper list
ensure_proper_list_var(Var) :- var(Var),!, put_attr(Var, proper_list_attr, is_proper_arg).
ensure_proper_list_var(Var) :- is_proper_arg(Var),!.


eval_at(_Fn,Where):- nb_current('eval_in_only',NonNil),NonNil\==[],!,Where=NonNil.
eval_at( Fn,Where):- use_evaluator(fa(Fn, _), Only, only),!,Only=Where.
eval_at(_Fn,Where):- option_value(compile,false),!,Where=interp.
eval_at( Fn,Where):- use_evaluator(fa(Fn, _), Where, enabled),!.
eval_at( Fn,Where):- nb_current(disable_compiler,WasDC),member(Fn,WasDC), Where==compiler,!,fail.
eval_at( Fn,Where):- nb_current(disable_interp,WasDC),member(Fn,WasDC), Where==interp,!,fail.
eval_at(_Fn,Where):- option_value(compile,full),!,Where=compiler.
eval_at(_Fn, _Any):- !.

must_use_interp(Fn, only_interp(Fn), true):- use_evaluator(fa(Fn, _), interp, only).
must_use_interp(_ , eval_in_only(compiler), never):- nb_current('eval_in_only',compiler).
must_use_interp(_ , eval_in_only(interp), true):- nb_current('eval_in_only',interp).
must_use_interp(Fn, disable_compiler(Fn), true):- nb_current(disable_compiler,WasDC), member(Fn,WasDC).
must_use_interp(Fn,compiler_disabled(Fn), true):- use_evaluator(fa(Fn, _), compiler, disabled).
must_use_interp(Fn,unknown(Fn), unknown).

must_use_compiler(_ ,eval_in_only(compiler)):- nb_current('eval_in_only',compiler).
must_use_compiler(_ ,eval_in_only(interp)):- nb_current('eval_in_only',interp), fail.
must_use_compiler(Fn,only_compiler(Fn)):- use_evaluator(fa(Fn, _), compiler, only).
must_use_compiler(Fn,disable_interp(Fn)):- nb_current(disable_interp,WasDC), member(Fn,WasDC).
must_use_compiler(Fn,interp_disabled(Fn)):- use_evaluator(fa(Fn, _), interp, disabled).

ci(_,_,_,G):- call(G).
ci(_,_,_, _,_,_,G):- !, call(G).
% Compiler is Disabled for Fn
ci(PreInterp,Fn,Len,Eval,RetVal,_PreComp,_Compiled):- fail,
    once(must_use_interp(Fn,Why,TF)),
    TF \== unknown, TF \== never,
    debug_info(must_use_interp,why(Why,Fn=TF)),
    TF == true, !,

    % \+ nb_current(disable_interp,WasDI),member(Fn,WasDI),
    call(PreInterp),
    maplist(lazy_eval_to_src,Eval,Src),
    if_t(Eval\=@=Src,
       debug_info(lazy_eval_to_src,ci(Fn,Len,Eval,RetVal))),
    %eval_fn_disable(Fn,disable_compiler,interp,((call(PreComp),call(Compiled)))),
    debug_info(Why,eval_args(Src,RetVal)),!,
    eval_args(Src,RetVal).

ci(_PreInterp,Fn,Len,_Eval,_RetVal,PreComp,Compiled):-
    %(nb_current(disable_interp,WasDI),member(Fn,WasDI);
    %\+ nb_current(disable_compiler,WasDC),member(Fn,WasDC)),!,
    %\+ \+ (maplist(lazy_eval_to_src,Eval,Src),
    %       if_t(Eval\=@=Src, debug_info(lazy_eval_to_src,ci(Fn,Len,Eval,RetVal)))),
    if_t(false,debug_info(call_in_only_compiler,ci(Fn,Len,Compiled))),!,
    % eval_fn_disable(Fn,disable_compiler,eval_args(EvalM,Ret))
    %show_eval_into_src(PreInterp,Eval,_EvalM),
    (call(PreComp),call(Compiled)),
    %eval_fn_disable(Fn,disable_compiler,(call(PreComp),call(Compiled))),
    true.

eval_fn_disable(Fn,DisableCompiler,Call):-
   (nb_current(DisableCompiler,Was)->true;Was=[]),
   (New = [Fn|Was]),
   Setup = nb_setval(DisableCompiler,New),
   Restore = nb_setval(DisableCompiler,Was),
   redo_call_cleanup(Setup,Call,Restore).


lazy_eval_to_src(A,O):- nonvar(O),trace,A=O.
%lazy_eval_to_src(A,O):- var(A),!,O=A,ensure_proper_list_var(A).
lazy_eval_to_src(A,O):- \+ compound(A),!,O=A.
%lazy_eval_to_src(A,P):- is_list(A), maplist(lazy_eval_to_src,A,P),!.
lazy_eval_to_src(A,P):- [H|T] = A, lazy_eval_to_src(H,HH),lazy_eval_to_src(T,TT),!,P= [HH|TT].
lazy_eval_to_src(A,P):- as_p1_expr(A,P),!.

delistify(L,D):- is_list(L),L=[D],!.
delistify(L,L).

create_prefixed_name(Prefix,LenArgs,FnName,String) :-
   %(sub_string(FnName, 0, _, _, "f") -> break ; true),
   length(LenArgs,L),
   append([Prefix,L|LenArgs],[FnName],Parts),
   atomic_list_concat(Parts,'_',String).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Evaluation (!)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% !(compile-body! (+ 1 $x) )
% !(compile-body! (assertEqualToResult (Add (S (S Z)) (S (S (S Z)))) ((S (S (S (S (S Z))))))) )
compile_body(Body, Output):-
 must_det_lls((
  term_variables(Body,BodyVars),
  maplist(cname_var('In_'),BodyVars),
  compile_for_exec(Ret, Body, Code),
  %create_p1(Ret,Code,Body,true,Output),
  create_p1(Ret,Code,Body,_Type,Output),
  cname_var('Out_',Ret),
  %transpile_eval(Body,Output),
  guess_varnames(Output,PrintCode),
  ppt(out(Ret):-(PrintCode)))).

on_compile_for_exec.

% ?- compile_for_exec(RetResult, is(pi+pi), Converted).
compile_for_exec(Res,I,O):-
 on_compile_for_exec,
   %ignore(Res='$VAR'('RetResult')),
 must_det_lls((
   compile_for_exec0(Res,I,O))).

compile_for_exec0(Res,I,eval_args(I,Res)):- is_ftVar(I),!.
compile_for_exec0(Res,(:- I),O):- !, compile_for_exec0(Res,I,O).

compile_for_exec0(Converted,I, PrologCode):- !,
  must_det_lls((transpile_eval(I,Converted, PrologCode))).

compile_for_exec0(Res,I,BB):-
   compile_for_exec1(I, H:-BB),
   arg(1,H,Res).

%compile_for_exec0(Res,I,BB):- fail,
%   %ignore(Res='$VAR'('RetResult')),
%   compile_flow_control(exec(),Res,I,O),
%   head_preconds_into_body(exec(Res),O,_,BB).
%compile_for_exec0(Res,I,O):- f2p(exec(),Res,I,O).

compile_for_exec1(AsBodyFn, Converted) :-
 must_det_lls((
   Converted = (HeadC :- NextBodyC),  % Create a rule with Head as the converted AsFunction and NextBody as the converted AsBodyFn
   f2p([exec0],[],HResult,RetLazy,AsBodyFn,NextBody),
   lazy_impedance_match(RetLazy,x(doeval,eager,_),HResult,[],HResult,[],HHResult,HCode),
   %optimize_head_and_body(x_assign([exec0],HResult),NextBody,HeadC,NextBodyB),
   ast_to_prolog_aux(no_caller,[],[native(exec0),HHResult],HeadC),
   %ast_to_prolog(no_caller,[],[[native(trace)]|NextBody],NextBodyC).
   append(NextBody,HCode,Code),
   debug_info(pre_ast,t(Code)),
   ast_to_prolog(no_caller,[],Code,NextBodyC))).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% Compiling a definition (=)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

combine_transpiler_clause_store_aux(ArgsN-RetN,Args0-Ret0,Args1-Ret1) :-
   maplist(arg_properties_widen,ArgsN,Args0,Args1),
   arg_properties_widen(RetN,Ret0,Ret1).

combine_transpiler_clause_store_and_maybe_recompile(FnName,LenArgs,FinalLazyArgsAdj,FinalLazyRetAdj) :-
   findall(ArgsLazy-RetLazy,transpiler_clause_store(FnName,LenArgs,_,_,_,ArgsLazy,RetLazy,_,_),[H|T]),
   foldl(combine_transpiler_clause_store_aux,T,H,FinalLazyArgsAdj-FinalLazyRetAdj),
   (transpiler_predicate_store(_Source,FnName,LenArgs,_Types,_RetType,FinalLazyArgsOld,FinalLazyRetOld) ->
      (FinalLazyArgsAdj=FinalLazyArgsOld,FinalLazyRetAdj=FinalLazyRetOld ->
         % already there in current form, nothing to see here
         true
      ;
         % signature is changed, need to do a recompile
         transpiler_debug(2,format_e("~q/~q signature is changed, need to do a recompile",FnName,LenArgs)),
         recompile_from_depends(FnName,LenArgs)
      )
   ;
      % new, insert clause
      current_compiler_context(CompCtx), % where expected to be stored (builtin,user,etc)
      setup_library_call(CompCtx,FnName,LenArgs,todo,todo,FinalLazyArgsAdj,FinalLazyRetAdj),
      recompile_from_depends(FnName,LenArgs)
   ).

create_mc_name(LenArgs,FnName,String) :-
   length(LenArgs,L),
   append(['mc_',L|LenArgs],[FnName],Parts),
   atomic_list_concat(Parts,'_',String).

current_compiler_context(Self):- current_self(Self), Self\=='&top', Self\==[], !. % atom(Self),
current_compiler_context(Filename):- option_value(loading_file, Filename), Filename\==[], !.
current_compiler_context(CompCtx):- option_value(compiler_context, CompCtx),!.
current_compiler_context(user).

get_curried_name_structure(null,'',[],[]) :- !. % special null case
get_curried_name_structure([],[],[],[]) :- !.
get_curried_name_structure([FnList|Args],Fn,TotalArgs,[L|LenArgs]) :- is_list(FnList),!,
   append(SplitArgs,[Args],TotalArgs),
   get_curried_name_structure(FnList,Fn,SplitArgs,LenArgs),
   length(Args,L), !.
get_curried_name_structure([Fn|Args],Fn,[Args],[LenArgs]) :- length(Args,LenArgs).

% Base case: When list length matches N, return the list itself.
split_last_n(N, List, First, LastN) :-
    length(List, Len),
    Start is Len - N,
    Start >= 0, % Ensure N is not greater than list length
    length(LastN, N),
    append(First, LastN, List).

invert_curried_structure(F,[],[],F).
invert_curried_structure(F,[L|LenArgs],Args,[Result|ArgsLast]) :-
   split_last_n(L,Args,ArgsFirst,ArgsLast),
   invert_curried_structure(F,LenArgs,ArgsFirst,Result).


recompile_from_depends(FnName,LenArgs) :- skip_redef_fa(FnName,LenArgs),!,debug_info(recompile_code_from_depends,skip_redef_fa(FnName,LenArgs)),!.
recompile_from_depends(FnName,LenArgs) :-
   transpiler_debug(2,(format_e("recompile_from_depends ~w/~w\n",[FnName,LenArgs]))),
   %LenArgs is LenArgsPlus1-1,
   %create_prefixed_name('mc_',LenArgs,,FnName,FnNameWPrefix),
   %findall(Atom0, (between(1, LenArgsPlus1, I0) ,Atom0='$VAR'(I0)), AtomList0),
   %H @.. [FnNameWPrefix|AtomList0],
   %transpiler_debug(2,format_e("Retracting stub: ~q\n",[H]) ; true),
   %retractall(H),
   findall(FnD/ArityD,transpiler_depends_on(FnD,ArityD,FnName,LenArgs),List),
   transpiler_debug(2,(format_e("recompile_from_depends list ~w\n",[List]))),
   debug_info(recompile_from_depends, fa(FnName,LenArgs)=List),
   maplist(recompile_from_depends_child(FnName/LenArgs),List).

unnumbervars_wco(X,XXX):- compound(X),
   sub_term_safely(E, X), compound(E), E = '$VAR'(_),!,
   subst001(X,E,_,XX),unnumbervars_wco(XX,XXX).
unnumbervars_wco(X,X).

% max_var_integer_in_term(+Term, -Max)
max_var_integer_in_term(Term, Start, Max) :-
        Box = box(Start),  % Correct initialization
        forall( ( sub_term_safely(CmpdVar, Term), compound(CmpdVar), CmpdVar = '$VAR'(Int), integer(Int), ( box(Int) @> Box )),
            nb_setarg(1, Box, Int)),
        arg(1, Box, Max),!.

number_vars_wo_conficts(X,XX):-
   copy_term(X,XX),
   woct(max_var_integer_in_term(XX,0,N)),
   succ(N,N2),
   numbervars(XX,N2,_,[attvar(skip)]).


recompile_from_depends_child(ParentFA,FnName/LenArgs) :- skip_redef_fa(FnName,LenArgs),!,
    debug_info(recompile_from_depends,skip_child(ParentFA,FnName/LenArgs)),!.
recompile_from_depends_child(_ParentFA,Fn/Arity) :-
   %format_e("recompile_from_depends_child ~w/~w\n",[Fn,Arity]),flush_output(user_output),
   ArityP1 is Arity+1,
   %retract(transpiler_predicate_store(_,Fn,Arity,_,_,_,_)),
   create_prefixed_name('mc_',Arity,Fn,FnWPrefix),
   abolish(FnWPrefix/ArityP1),
 %  create_prefixed_name('mi_',Arity,Fn,FnWMiPrefix),
 %  abolish(FnWMiPrefix/ArityP1),
 %  create_prefixed_name('me_',Arity,Fn,FnWMePrefix),
 %  abolish(FnWMePrefix/ArityP1),
   % retract(transpiler_stub_created(Fn,Arity)),
   % create an ordered list of integers to make sure to do them in order
   findall(ClauseIDt,transpiler_clause_store(Fn,Arity,ClauseIDt,_,_,_,_,_,_),ClauseIdList),
   sort(ClauseIdList,SortedClauseIdList),
   maplist(extract_info_and_remove_transpiler_clause_store(Fn,Arity),SortedClauseIdList,Clause),
   %leash(-all),trace,
   %format_e("X: ~w\n",[Clause]),flush_output(user_output),
   number_vars_wo_conficts(Clause,Clause2),!,
   maplist(compile_for_assert_with_add,Clause2).

compile_for_assert_with_add(Head-Body) :-
   compile_for_assert(Head,Body,Converted),
   compiler_assertz(Converted).

extract_info_and_remove_transpiler_clause_store(Fn,Arity,ClauseIDt,Head-Body) :-
   transpiler_clause_store(Fn,Arity,ClauseIDt,_,_,_,_,Head,Body),
   %format_e("Extracted clause: ~w:~w:-~w\n",[Fn,Head,Body]),
   retract(transpiler_clause_store(Fn,Arity,ClauseIDt,_,_,_,_,_,_)).

% !(compile-for-assert (plus1 $x) (+ 1 $x) )
compile_for_assert(HeadIsIn, AsBodyFnIn, Converted) :-
  compile_for_assert_2(HeadIsIn, AsBodyFnIn, Converted).

compile_for_assert_2(HeadIsIn, AsBodyFnIn, Converted) :-
  must_det_lls((
  IN = ['=',HeadIsIn, AsBodyFnIn],
  metta_to_metta_macro_recurse(IN, OUT),
  OUT = ['=',HeadIs, AsBodyFn],
  compile_for_assert_3(HeadIs, AsBodyFn, Converted))).

compile_for_assert_3(HeadIsIn, AsBodyFnIn, Converted) :-
   %must_det_lls((
   current_self(Space),
   subst_varnames(HeadIsIn+AsBodyFnIn,HeadIs+AsBodyFn),
   %leash(-all),trace,
   get_curried_name_structure(HeadIs,FnName,Args,LenArgs),
   %ensure_callee_site(Space,FnName,LenArgs),
   remove_stub(Space,FnName,LenArgs),
   sum_list(LenArgs,LenArgsTotal),
   LenArgsTotalPlus1 is LenArgsTotal+1,
   % retract any stubs

   (transpiler_stub_created(FnName,LenArgs) ->
      retract(transpiler_stub_created(FnName,LenArgs)),
      findall(Atom0, (between(1, LenArgsTotalPlus1, I0) ,Atom0='$VAR'(I0)), AtomList0),
      create_prefixed_name('mc_',LenArgs,FnName,FnNameWPrefix),
      H @.. [FnNameWPrefix|AtomList0],
      transpiler_debug(2,format_e("Retracting stub: ~q\n",[H]) ; true),
      retractall(H),
      create_prefixed_name('mi_',LenArgs,FnName,FnNameWMiPrefix),
      H1 @.. [FnNameWMiPrefix|AtomList0],
      retractall(H1),
      create_prefixed_name('me_',LenArgs,FnName,FnNameWMePrefix),
      H2 @.. [FnNameWMePrefix|AtomList0],
      retractall(H2)
   ; true),

   %AsFunction = HeadIs,
   %must_det_lls((
      %leash(-all),trace(f2p/8),
      Converted = (HeadC :- NextBodyC),  % Create a rule with Head as the converted AsFunction and NextBody as the converted AsBodyFn
      get_operator_typedef_props(_,FnName,LenArgsTotal,Types0,RetType0),
      maplist(arg_eval_props,Types0,TypeProps),
      arg_eval_props(RetType0,RetProps),
      determine_eager_vars(lazy,ResultEager,AsBodyFn,EagerArgList),
      %EagerArgList=[],
      append(Args,FlattenedArgs),
      maplist(set_eager_or_lazy(EagerArgList),FlattenedArgs,EagerLazyList),
      % EagerLazyList: eager/lazy
      % TypeProps: x(doeval/noeval,eager/lazy, typeinfo)
      % FinalLazyArgs: x(doeval/noeval,eager/lazy, typeinfo)
      maplist(combine_lazy_types_props,EagerLazyList,TypeProps,FinalLazyArgs),
      combine_lazy_types_props(ResultEager,RetProps,FinalLazyRet),

      findall(ClauseIDt,transpiler_clause_store(FnName,LenArgs,ClauseIDt,_,_,_,_,_,_),ClauseIdList),
      (ClauseIdList=[] -> ClauseId=0 ; max_list(ClauseIdList,ClauseIdm1),ClauseId is ClauseIdm1+1),
      compiler_assertz(transpiler_clause_store(FnName,LenArgs,ClauseId,Types0,RetType0,FinalLazyArgs,FinalLazyRet,HeadIs,AsBodyFn)),

      combine_transpiler_clause_store_and_maybe_recompile(FnName,LenArgs,FinalLazyArgsAdj,FinalLazyRetAdj0),
      %FinalLazyRetAdj=FinalLazyRetAdj0,
      FinalLazyRetAdj0=x(_,L,T),
      FinalLazyRetAdj=x(doeval,L,T),
      maplist(arrange_lazy_args,FlattenedArgs,FinalLazyArgsAdj,LazyArgsListAdj),
      %precompute_typeinfo(HResult,HeadIs,AsBodyFn,Ast,TypeInfo),

      %get_property_lazy(FinalLazyRet,FinalLazyOnlyRet),

        OldExpr = [defn,HeadIs,AsBodyFn],

        combine_transform_and_collect(OldExpr, Assignments, _NewExpr, VarMappings),

        %writeln("=== Original Expression ==="), print_ast(OldExpr),
        %writeln("=== Assignments (subcalls replaced) ==="), print_ast(Assignments),
        %writeln("=== New Expression ==="), print_ast(NewExpr),
        transpiler_debug(2,
            (writeln("=== Assignments / Var Mappings (underscore variables) ==="),
            append(Assignments,VarMappings,SM),sort(SM,S),
            group_pair_by_key(S,SK),
            print_ast(magenta, SK))),

      %output_prolog(magenta,TypeInfo),
      %print_ast( green, Ast),
      maplist(h2p(EagerArgList,LazyArgsListAdj),FinalLazyArgsAdj,FlattenedArgs,Args2,Code,NewLazyVars),
      append([LazyArgsListAdj|NewLazyVars],NewLazyVarsAggregate),
      f2p(HeadIs,NewLazyVarsAggregate,H0Result,H0ResultN,LazyRet,AsBodyFn,NextBody,NextBodyN),
      lazy_impedance_match(LazyRet,FinalLazyRetAdj,H0Result,NextBody,H0ResultN,NextBodyN,HResult,FullCode),

      LazyEagerInfo=[resultEager:ResultEager,retProps:RetProps,finalLazyRet:FinalLazyRetAdj,finalLazyOnlyRet:FinalLazyRetAdj,args_list:Args2,lazyArgsList:NewLazyVarsAggregate,eagerLazyList:EagerLazyList,typeProps:TypeProps,finalLazyArgs:FinalLazyArgsAdj],

      transpiler_debug(2,output_prolog(LazyEagerInfo)),

      %format_e("HeadIs:~q HResult:~q AsBodyFn:~q FullCode:~q\n",[HeadIs,HResult,AsBodyFn,FullCode]),
      %(var(HResult) -> (Result = HResult, HHead = Head) ;
      %   funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, _Nth, Head)),

      HeadAST=[assign,HResult,[hcall(FnName,LenArgs),Args2]],
      (transpiler_trace(FnName) -> Prefix=[[native(trace)]] ; Prefix=[]),
      append([Prefix|Code],CodeAppend),
      append(CodeAppend,FullCode,FullCode2),
      %ast_to_prolog(no_caller,HeadAST,HeadC),
      %append(Args,[HResult],HArgs),
      %HeadC @.. [FnNameWPrefix|HArgs],

      ast_to_prolog_aux(no_caller,[FnName/LenArgsPlus1],HeadAST,HeadC),
      %print_ast( yellow, [=,HeadAST,FullCode2]),
      debug_info(pre_ast,t(FullCode2)),
      ast_to_prolog(caller(FnName,LenArgs),[FnName/LenArgs],FullCode2,NextBodyC),

      %format_e("###########1 ~q",[Converted]),
      %numbervars(Converted,0,_),
      %format_e("###########2 ~q",[Converted]),
      extract_constraints(Converted,EC),
      try_optimize_prolog(fa,Converted,Optimized),
      transpiler_debug(2,output_prolog('#F08080',[EC])),!,
      transpiler_debug(1,output_prolog('#ADD8E6',[Converted])),!,
      if_t(Optimized\=@=Converted,
             transpiler_debug(1,output_prolog(green,Optimized))),

        transpiler_debug(2,tree_deps(Space,FnName,LenArgsPlus1)),

        transpiler_debug(2,show_recompile(Space,FnName,LenArgsPlus1)),
      true
   %))))
   .

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% type eval lazy utils
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

arrange_lazy_args(N,x(E,Y,T),N-x(E,Y,T)).

get_operator_typedef_nocache(X,FnName,LenArgs,Types,RetType) :-
   metta_type(X,FnName,['->'|Raw]),
   LenArgs1 is LenArgs+1,
   length(Raw,LenArgs1),
   append(Types,[RetType],Raw).

get_operator_typedef_props(X,FnName,LenArgs,Types,RetType) :-
   get_operator_typedef_nocache(X,FnName,LenArgs,Types,RetType).
get_operator_typedef_props(_,_,LenArgs,Types,'Any') :-
    length(Types,LenArgs),
    maplist(=('Any'), Types).

set_eager_or_lazy(_,V,eager) :- \+ fullvar(V), !.
set_eager_or_lazy(Vlist,V,R) :- (member_var(V,Vlist) -> R=eager ; R=lazy).

combine_lazy_types_props(eager,x(doeval,_,T),x(doeval,eager,T)) :- !.
%combine_lazy_types_props(eager,x(noeval,_,T),x(doeval,eager,T)) :- !.
combine_lazy_types_props(_,X,X).

transpiler_stored_eval_lookup(Convert,PrologCode0,Converted0):-
  transpiler_stored_eval(ConvertM,PrologCode0,Converted0),
  ConvertM =@= Convert,ConvertM = Convert,!.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% Determine eager vars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

member_var(X, [H|T]) :- X == H ; member_var(X, T).

intersect_var([],_,[]).
intersect_var([H|T],X,Y) :-
    intersect_var(T,X,Y0),
    (member_var(H,X) -> Y=[H|Y0] ; Y=Y0).

union_var([],X,X).
union_var([H|T],X,Y) :-
    union_var(T,X,Y0),
    (member_var(H,X) -> Y=Y0 ; Y=[H|Y0]).

get_property_lazy(x(_,L,_),L).

determine_eager_vars_case_aux(L,L,[],[]).
determine_eager_vars_case_aux(Lin,Lout,[[Match,Target]|Rest],EagerVars) :-
   determine_eager_vars(eager,_,Match,EagerVarsMatch),
   determine_eager_vars(Lin,LoutTarget,Target,EagerVarsTarget),
   determine_eager_vars_case_aux(Lin,LoutRest,Rest,EagerVarsRest),
   intersect_var(EagerVarsTarget,EagerVarsRest,EagerVars0),
   union_var(EagerVarsMatch,EagerVars0,EagerVars),
   (LoutTarget=eager,LoutRest=eager -> Lout=eager ; Lout=lazy).

determine_eager_vars(lazy,lazy,A,[]) :- fullvar(A),!.
determine_eager_vars(eager,eager,A,[A]) :- fullvar(A),!.
determine_eager_vars(_,eager,A,EagerVars) :- is_list(A),A=[Var|_],fullvar(Var),!,  % avoid binding free var to 'if'
   maplist(determine_eager_vars(eager),_,A,EagerVars0),foldl(union_var,EagerVars0,[],EagerVars).
determine_eager_vars(Lin,Lout,[IF,If,Then,Else],EagerVars) :- atom(IF), is_If(IF),!,
   determine_eager_vars(eager,_,If,EagerVarsIf),
   determine_eager_vars(Lin,LoutThen,Then,EagerVarsThen),
   determine_eager_vars(Lin,LoutElse,Else,EagerVarsElse),
   intersect_var(EagerVarsThen,EagerVarsElse,EagerVars0),
   union_var(EagerVarsIf,EagerVars0,EagerVars),
   (LoutThen=eager,LoutElse=eager -> Lout=eager ; Lout=lazy).
determine_eager_vars(Lin,Lout,[IF,If,Then],EagerVars) :- atom(IF),is_If(IF),!,
   determine_eager_vars(eager,_,If,EagerVars),
   determine_eager_vars(Lin,Lout,Then,_EagerVarsThen).
% for case, treat it as nested if then else
determine_eager_vars(Lin,Lout,[CASE,Val,Cases],EagerVars) :- atom(CASE),CASE='case',!,
   determine_eager_vars(eager,_,Val,EagerVarsVal),
   determine_eager_vars_case_aux(Lin,Lout,Cases,EagarVarsCases),
   union_var(EagerVarsVal,EagarVarsCases,EagerVars).
determine_eager_vars(Lin,Lout,[LET,V,Vbind,Body],EagerVars) :-  atom(LET),LET='let',!,
   determine_eager_vars(eager,_,Vbind,EagerVarsVbind),
   determine_eager_vars(Lin,Lout,Body,EagerVarsBody),
   (fullvar(V) -> union_var([V],EagerVarsVbind,EagerVars0) ; EagerVarsVbind=EagerVars0),
   union_var(EagerVars0,EagerVarsBody,EagerVars).
determine_eager_vars(Lin,Lout,[LETS,[],Body],EagerVars) :- atom(LETS),LETS='let*',!,determine_eager_vars(Lin,Lout,Body,EagerVars).
determine_eager_vars(Lin,Lout,[LETS,[[V,Vbind]|T],Body],EagerVars) :-  atom(LETS),LETS='let*',!,
   determine_eager_vars(eager,_,Vbind,EagerVarsVbind),
   determine_eager_vars(Lin,Lout,['let*',T,Body],EagerVarsBody),
   (fullvar(V) -> union_var([V],EagerVarsVbind,EagerVars0) ; EagerVarsVbind=EagerVars0),
   union_var(EagerVars0,EagerVarsBody,EagerVars).
determine_eager_vars(_,RetLazy,[Fn|Args],EagerVars) :- atom(Fn),!,
   length(Args,LenArgs),
   (transpiler_predicate_store(_,Fn,LenArgs,_,_,ArgsLazy0,RetLazy0) ->
      maplist(get_property_lazy,ArgsLazy0,ArgsLazy),
      get_property_lazy(RetLazy0,RetLazy)
   ; transpiler_predicate_nary_store(_,Fn,FixedLength,_,_,_,FixedArgsLazy0,VarArgsLazy0,RetLazy0),LenArgs>=FixedLength ->
      maplist(get_property_lazy,FixedArgsLazy0,FixedArgsLazy),
      VarCount is LenArgs-FixedLength,
      length(VarArgsLazyList, VarCount),
      get_property_lazy(VarArgsLazy0,VarArgsLazy),
      maplist(=(VarArgsLazy), VarArgsLazyList),
      append(FixedArgsLazy,VarArgsLazyList,ArgsLazy),
      get_property_lazy(RetLazy0,RetLazy)
   ;
      RetLazy=eager,
      length(ArgsLazy, LenArgs),
      maplist(=(eager), ArgsLazy)),
   maplist(determine_eager_vars,ArgsLazy,_,Args,EagerVars0),
   foldl(union_var,EagerVars0,[],EagerVars).
determine_eager_vars(_,eager,A,EagerVars) :- is_list(A),!,
   maplist(determine_eager_vars(eager),_,A,EagerVars0),foldl(union_var,EagerVars0,[],EagerVars).
determine_eager_vars(_,eager,_,[]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% lazy impendence match and other utils used by h2p and f2p
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

compile_maplist_p2(_,[],[],[]).
compile_maplist_p2(P2,[Var|Args],[Res|NewArgs],PreCode):- \+ fullvar(Var), call(P2,Var,Res), !,
  compile_maplist_p2(P2,Args,NewArgs,PreCode).
compile_maplist_p2(P2,[Var|Args],[Res|NewArgs],TheCode):-
  compile_maplist_p2(P2,Args,NewArgs,PreCode),
  append([[native(P2),Var,Res]],PreCode,TheCode).

var_prop_lookup(_,[],x(noeval,eager,[])).
var_prop_lookup(X,[H-R|T],S) :-
   X == H,!,S=R;  % Test if X and H are the same variable
   var_prop_lookup(X,T,S).  % Recursively check the tail of the list

assign_or_direct_var_only([],Value,Value,[]) :- var(Value),!.
assign_or_direct_var_only(CodeIn,Ret,Value,CodeOut) :- append(CodeIn,[[assign,Ret,Value]],CodeOut).

assign_or_direct([],Value,Value,[]) :- !.
assign_or_direct(CodeIn,Ret,Value,CodeOut) :- append(CodeIn,[[assign,Ret,Value]],CodeOut).

assign_only(CodeIn,Ret,Value,CodeOut) :- append(CodeIn,[[assign,Ret,Value]],CodeOut).

update_laziness(x(X,_,T),x(_,Y,_),x(X,Y,T)).

% eager -> eager, lazy -> lazy
lazy_impedance_match(x(_,eager,_),x(noeval,eager,_),_ValE,_CodeE,ValN,CodeN,ValN,CodeN).
lazy_impedance_match(x(_,eager,_),x(doeval,eager,_),ValE,CodeE,_ValN,_CodeN,ValE,CodeE).
lazy_impedance_match(x(_,lazy,_),x(noeval,lazy,_),_ValE,_CodeE,ValN,[],ValN,[]) :- !.
lazy_impedance_match(x(_,lazy,_),x(doeval,lazy,_),ValE,[],_ValN,_CodeN,ValE,[]) :- !.
lazy_impedance_match(x(_,lazy,_),x(_,lazy,_),ValE,CodeE,ValN,CodeN,Val,Code) :- !,
   append(CodeE,[[native(as_p1_exec),ValE,RetResultE]],CodeAE),
   append(CodeN,[[native(as_p1_expr),ValN,RetResultN]],CodeAN),
   %append(CodeN,[[assign,ValN,RetResultN]],CodeAN),
   create_p1(RetResultE,CodeAE,RetResultN,CodeAN,P1),Code=[[assign,Val,P1]].
%lazy_impedance_match(x(_,lazy,_),x(_,lazy,_),ValE,CodeE,ValN,CodeN,Val,Code) :- !,
%   append(CodeE,[[native(as_p1_exec),ValE,RetResultE]],CodeAE),
%   append(CodeN,[[native(as_p1_expr),RetResultN,ValN]],CodeAN),
%   create_p1(RetResultE,CodeAE,RetResultN,CodeAN,P1),Code=[[assign,Val,P1]].

% lazy -> eager
lazy_impedance_match(x(_,lazy,_),x(doeval,eager,_),ValE,CodeE,_ValN,_CodeN,RetResult,Code) :- append(CodeE,[[native(as_p1_exec),ValE,RetResult]],Code).
lazy_impedance_match(x(_,lazy,_),x(noeval,eager,_),_ValE,_CodeE,ValN,CodeN,RetResult,Code) :- append(CodeN,[[native(as_p1_expr),ValN,RetResult]],Code).
% eager -> lazy
lazy_impedance_match(x(_,eager,_),x(doeval,lazy,_),ValE,CodeE,ValN,CodeN,RetResult,Code) :- create_p1(ValE,CodeE,ValN,CodeN,P1),Code=[[assign,RetResult,P1]].
lazy_impedance_match(x(_,eager,_),x(noeval,lazy,_),ValE,CodeE,ValN,CodeN,RetResult,Code) :- create_p1(ValE,CodeE,ValN,CodeN,P1),Code=[[assign,RetResult,P1]].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% h2p
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

himpedance_match(_,_,Convert,Convert,[]).
%himpedance_match(x(_,L,_),x(_,L,_),Convert,Convert,[]).
%himpedance_match(x(_,eager,_),x(doeval,lazy,_),Convert,Converted,[[native(as_p1_exec),Converted,Convert]]).
%himpedance_match(x(_,eager,_),x(noeval,lazy,_),Convert,Converted,[[native(as_p1_expr),Converted,Convert]]).
%himpedance_match(x(_,lazy,_),x(doeval,eager,_),Convert,Converted,[[native(ispuU),Converted,Convert]]) :- trace.
%himpedance_match(x(_,lazy,_),x(noeval,eager,_),Convert,Converted,[[native(ispuU),Converted,Convert]]) :- trace.

h2p(EagerArgList,LazyVars,ArgType,Convert,Converted,CodeOut,TotalNewLazyVars) :-
      %trace,
      h2p_sub(EagerArgList,LazyVars,Convert,ConvertedInt,CodeOut1,TotalNewLazyVars),
      var_prop_lookup(Converted,LazyVars,Type),
      himpedance_match(Type,ArgType,ConvertedInt,Converted,CodeOut2),
      append(CodeOut1,CodeOut2,CodeOut).

h2p_sub(_EagerArgList,_LazyVars,Convert,Convert,[],[]) :- is_ftVar(Convert), !.

h2p_sub(_EagerArgList,_LazyVars,Convert,Convert,[],[]) :- (number(Convert) ; atom(Convert); atomic(Convert)), !.

h2p_sub(_EagerArgList,_LazyVars,'#\\'(Convert),Convert,[],[]) :- !.

h2p_sub(EagerArgList,LazyVars,Convert,Converted,CodeOut,TotalNewLazyVars) :-
   get_curried_name_structure(Convert,FnName,Args,LenArgs),
   append(Args,FlattenedArgs),
   atom(FnName),
   var_prop_lookup(Convert,LazyVars,x(_,eager,_)),!,
   (transpiler_predicate_store(_,FnName,LenArgs,_,_,TypeProps0,_) ->
      TypeProps=TypeProps0
   ;
      sum_list(LenArgs,LenArgsTotal),
      get_operator_typedef_props(_,FnName,LenArgsTotal,Types0,_RetType0),
      maplist(set_eager_or_lazy(EagerArgList),FlattenedArgs,EagerLazyList),
      maplist(arg_eval_props,Types0,TypeProps)
   ),
   maplist(combine_lazy_types_props,EagerLazyList,TypeProps,FinalLazyArgs),
   maplist(arrange_lazy_args,FlattenedArgs,FinalLazyArgs,ThisNewLazyVars),
   maplist(h2p_sub(EagerArgList,LazyVars),FlattenedArgs,QuoteContentsOut,Code,NewLazyVars),
   append(NewLazyVars,NewLazyVarsAggregate),
   append(ThisNewLazyVars,NewLazyVarsAggregate,TotalNewLazyVars),
   invert_curried_structure(FnName,LenArgs,QuoteContentsOut,Converted),
   append(Code,CodeOut).

h2p_sub(_EagerArgList,LazyVars,Convert,Converted,[[native(as_p1_expr),Converted,Convert]],[]) :-
   Convert=[Fn|_],atom(Fn),
   var_prop_lookup(Convert,LazyVars,x(_,lazy,_)),!.

h2p_sub(EagerArgList,LazyVars,Convert,Converted,CodeOut,NewLazyVarsAggregate) :-
   is_list(Convert),
   var_prop_lookup(Convert,LazyVars,x(_,eager,_)),!,
   maplist(h2p_sub(EagerArgList,LazyVars),Convert,Converted,Code,NewLazyVars),
   append(NewLazyVars,NewLazyVarsAggregate),
   append(Code,CodeOut).

h2p_sub(_EagerArgList,_ArgType,_LazyVars,X,X,[],[]) :-
   format_e("Error in h2p_sub: ~w",[X]),
   throw(0).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% transpile_interpret
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

transpile_interpret(Convert,Convert) :- \+ is_list(convert),!.

%transpile_interpret(Convert,Converted) :-


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% f2p
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- discontiguous f2p/8.

f2p(HeadIs, LazyVars, RetResult, RetResultN, ResultLazy, T, Converted, ConvertedN) :- compound(T),T=exec(X),!,
   f2p(HeadIs, LazyVars, RetResult, RetResultN, ResultLazy, [eval,X], Converted, ConvertedN).

f2p(HeadIs, LazyVars, RetResult, RetResultN, ResultLazy, Convert, Converted, ConvertedN) :-
   nb_bound(Convert,X),!, % TODO might need to look this up at evaluation time instead
   f2p(HeadIs, LazyVars, RetResult, RetResultN, ResultLazy, X, Converted, ConvertedN).

f2p(_HeadIs, LazyVars, Convert, Convert, EL, Convert, [], []) :-
   (is_ftVar(Convert)),!, % Check if Convert is a variable
   var_prop_lookup(Convert,LazyVars,EL).

f2p(_HeadIs, _LazyVars, Convert, Convert, x(doeval,eager,[]), Convert, [], []) :-
   (number(Convert)),!. % Check if Convert is a number

% BUG !(get-type 'a') -> returns Symbol needs to return Char
f2p(_HeadIs, _LazyVars, Convert, Convert, x(noeval,eager,[]), '#\\'(Convert), [], []) :- !.

% If Convert is a number or an atom, it is considered as already converted.
f2p(_HeadIs, _LazyVars, Convert, Convert, x(noeval,eager,[]), Convert, [], []) :- fail,
    once(number(Convert);atomic(Convert);\+compound(Convert);atomic(Convert)/*;data_term(Convert)*/),!. %CheckifConvertisanumberoranatom

% If Convert is a number or an atom, it is considered as already converted.
f2p(_HeadIs, _LazyVars, Convert, Convert, x(noeval,eager,[]), Convert, [], []) :-
    once(number(Convert); atom(Convert);atomic(Convert)),!.  % Check if Convert is a number or an atom

f2p(_HeadIs, _LazyVars, Convert, Convert, x(noeval,eager,[]), Convert, [], []) :- fail,
    once(self_eval(Convert)),!.

f2p(_HeadIs, _LazyVars, Convert, Convert, x(noeval,eager,[]), Convert, [], []) :- fail,
    once(data_term(Convert)),!.


f2p(_HeadIs, _LazyVars, AsIsNoConvert, AsIsNoConvert, x(doeval,eager,[]), AsIsNoConvert, [], []) :-
     as_is_data_term(AsIsNoConvert),!. % Check if Convert is kept AsIs

as_is_data_term(Var):- var(Var),!,fail.
as_is_data_term(Term):- py_is_py(Term),!.
as_is_data_term(Term):- is_valid_nb_state(Term),!.
as_is_data_term(Term):- \+ callable(Term),!.
as_is_data_term(Term):- compound(Term),!,compound_name_arity(Term,F,A),as_is_no_convert_f_a(F,A).
as_is_no_convert_f_a(rng,2).
as_is_no_convert_f_a('Evaluation',_).


/*
f2p(_HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :-
   is_ftVar(Convert),!, % Check if Convert is a variable
   var_prop_lookup(Convert,LazyVars,EL),
   lazy_impedance_match(EL,ResultLazy,Convert,[],RetResult,Converted).

f2p(_HeadIs, _LazyVars, RetResult, ResultLazy, '#\\'(Convert), Converted) :-
   (ResultLazy=x(_,eager,_) ->
      RetResult=Convert,
      Converted=[]
   ;  Converted=[assign,RetResult,[is_p1,['Char'],'#\\'(Convert),[],Convert]]).



% If Convert is a number or an atomic, it is considered as already converted.
f2p(_HeadIs, _LazyVars, RetResult, ResultLazy, Convert, Converted) :- % HeadIs\=@=Convert,
    once(number(Convert); atom(Convert); atomic(Convert) /*; data_term(Convert)*/ ),  % Check if Convert is a number or an atom
    (ResultLazy=x(_,eager,_) -> C2=Convert ; C2=[ispu,Convert]),
    Converted=[[assign,RetResult,C2]],
    % For OVER-REACHING categorization of dataobjs %
    % wdmsg(data_term(Convert)),
    %trace_break,
    !.  % Set RetResult to Convert as it is already in predicate form



% If Convert is not expected to be evaluatble, it is considered as already converted.
f2p(_HeadIs, _LazyVars, RetResult, ResultLazy, Convert, Converted) :- fail, % HeadIs\=@=Convert,
    %once(number(Convert); atom(Convert); data_term(Convert)),  % Check if Convert is a number or an atom
    once(number(Convert); atomic(Convert); \+compound(Convert); data_term(Convert)),
    must_det_lls(get_val_types(Convert,Types)->true;Types=['%NoValTypes%']),
    (ResultLazy=eager -> C2=Convert ; C2=[is_p1,[ResultLazy|Types],Convert,[],Convert]),
    Converted=[[assign,RetResult,C2]],
    % For OVER-REACHING categorization of dataobjs %
    % wdmsg(data_term(Convert)),
    %trace_break,
    !.  % Set RetResult to Convert as it is already in predicate form
*/

f2p(HeadIs, LazyVars, RetResult, RetResultN, ResultLazy, Convert, Converted, ConvertedN):-
   Convert=[Fn|_],
   atom(Fn),
   compile_flow_control(HeadIs,LazyVars,RetResult, RetResultN, ResultLazy, Convert, Converted, ConvertedN),!.


/*
% !(compile-body! (call-fn! compile_body (call-p writeln "666"))
f2p(HeadIs, _LazyVars, RetResult, ResultLazy, Convert, Converted) :- HeadIs\==Convert,
    Convert=[Fn,Native|Args],atom(Fn),unshebang(Fn,'call-p'),!,
   must_det_lls((
    compile_maplist_p2(as_prolog,Args,NewArgs,PreCode),
    %RetResult = 'True',
    compile_maplist_p2(from_prolog_args(ResultLazy),NewArgs,Args,PostCode),
    append([PreCode,[[native(Native),NewArgs],[assign,RetResult,'True']],PostCode],Converted))).
unshebang(S,US):- symbol(S),(symbol_concat(US,'!',S)->true;US=S).

compile_maplist_p2(_,[],[],[]).
compile_maplist_p2(P2,[Var|Args],[Res|NewArgs],PreCode):- \+ fullvar(Var), call(P2,Var,Res), !,
  compile_maplist_p2(P2,Args,NewArgs,PreCode).
compile_maplist_p2(P2,[Var|Args],[Res|NewArgs],TheCode):-
  compile_maplist_p2(P2,Args,NewArgs,PreCode),
  append([[native(P2),Var,Res]],PreCode,TheCode).

% !(compile-body! (call-fn length $list))
f2p(HeadIs, _LazyVars, RetResult, ResultLazy, Convert, Converted) :-  HeadIs\==Convert,
    Convert=[Fn,Native|Args],atom(Fn),unshebang(Fn,'call-fn'),!,
    compile_maplist_p2(as_prolog,Args,NewArgs,PreCode),
    append(NewArgs,[Result],CallArgs),
    compile_maplist_p2(from_prolog_args(maybe(ResultLazy)),[Result],[RetResult],PostCode),
    append([PreCode,[[native(Native),CallArgs]],PostCode],Converted).

% !(compile-body! (call-fn-nth 0 wots version))
f2p(HeadIs, _LazyVars, RetResult, ResultLazy, Convert, Converted) :- HeadIs\==Convert,
   Convert=[Fn,Nth,Native|SIn],atom(Fn),unshebang(Fn,'call-fn-nth'),integer(Nth),!,
   compile_maplist_p2(as_prolog,SIn,S,PreCode),
   length(Left,Nth),
   append(Left,Right,S),
   append(Left,[R|Right],Args),!,
    compile_maplist_p2(from_prolog_args(maybe(ResultLazy)),[R],[RetResult],PostCode),
    append([PreCode,[[native(Native),Args]],PostCode],Converted).

% !(compile-body! (length-p (a b c d) 4))
% !(compile-body! (format_e! "~q ~q ~q" (a b c)))
f2p(HeadIs, _LazyVars, RetResult, ResultLazy, Convert, Converted) :- HeadIs\==Convert,
    is_host_predicate(Convert,Native,_Len),!,Convert=[_|Args],
    compile_maplist_p2(as_prolog,Args,NewArgs,PreCode),
    %RetResult = 'True',
    compile_maplist_p2(from_prolog_args(maybe(ResultLazy)),NewArgs,Args,PostCode),
    append([PreCode,[[native(Native),NewArgs],[assign,RetResult,'True']],PostCode],Converted).


% !(compile-body! (length-fn (a b c d)))
f2p(HeadIs, _LazyVars, RetResult, ResultLazy, Convert, Converted) :-  HeadIs\==Convert,
    Convert=[Fn|Args],
    is_host_function([Fn|Args],Native,_Len),!,
    compile_maplist_p2(as_prolog,Args,NewArgs,PreCode),
    append(NewArgs,[Result],CallArgs),
    compile_maplist_p2(from_prolog_args(maybe(ResultLazy)),[Result],[RetResult],PostCode),
    append([PreCode,[[native(Native),CallArgs]],PostCode],Converted).
*/

f2p_do_group(LE, LazyResultParts, Convert, EvalRetResults, EvalCode, EvalCodeCollected) :-
    Args = Convert,
    length(Args, N),
    length(EvalArgs, N),
    maplist(=(LE), EvalArgs),
    maplist(lazy_impedance_match, LazyResultParts, EvalArgs, Convert, EvalCode, Convert, EvalCode, EvalRetResults, Code),
    append(Code,EvalCodeCollected).

/*
% prememptive flow contols
f2p(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted):- fail,
   Convert=[Fn|_],
   atom(Fn),
   compile_flow_control1(HeadIs,LazyVars,RetResult,ResultLazy, Convert, Converted),!.

% unsupported flow contols
f2p(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted):- fail,
   Convert=[Fn|_],
   atom(Fn),
   compile_flow_control2(HeadIs,LazyVars,RetResult,ResultLazy, Convert, Converted),!.
*/

/*
f2p(HeadIs, LazyVars, RetResult, RetResultN, ResultLazy, Convert, Converted, ConvertedN) :-
   Convert=[[py-atom Fn]|Args],
   maplist(f2p(HeadIs,LazyVars), RetResultsParts, RetResultsPartsN, LazyResultParts, Args, ConvertedParts, ConvertedNParts),
   f2p_do_group(x(doeval,eager,[]),LazyResultParts,RetResultsParts,DoEvalRetResults,ConvertedParts,DoEvalCodeCollected),
   f2p_do_group(x(noeval,eager,[]),LazyResultParts,RetResultsPartsN,NoEvalRetResults,ConvertedNParts,NoEvalCodeCollected),
   append(Args,[RetResult],Args1),
   append(DoEvalCodeCollected,[[native(py_atom),Fn,FnPy]],Converted),
   %assign_or_direct(DoEvalCodeCollected,RetResult,list(DoEvalRetResults),Converted),
   assign_or_direct(NoEvalCodeCollected,RetResultN,list([[py-atom Fn]|NoEvalRetResults]),ConvertedN).
*/

f2p(HeadIs, LazyVars, RetResult, RetResultN, ResultLazy, Convert, Converted, ConvertedN) :- %HeadIs\==Convert,
   get_curried_name_structure(Convert,Fn,Args,LenArgs),
   atom(Fn),!,
   get_curried_name_structure(HeadIs,FnHead,_,LenArgsHead),
   sum_list(LenArgs,LenArgsTotal),
   (transpiler_predicate_store(_,Fn,LenArgs,_,_,ArgsLazy0,RetLazy0) ->
      % use whatever signature is defined from the library or compiled code rather than get_operator_typedef_props
      EvalArgs=ArgsLazy0,
      ResultLazy=RetLazy0,
      Docall=yes
   ; transpiler_predicate_nary_store(_,Fn,FixedLength,_,_,_,FixedArgsLazy0,VarArgsLazy0,RetLazy0),LenArgsTotal>=FixedLength ->
      VarCount is LenArgsTotal-FixedLength,
      length(VarArgsLazyList, VarCount),
      maplist(=(VarArgsLazy0), VarArgsLazyList),
      append(FixedArgsLazy0,VarArgsLazyList,EvalArgs),
      ResultLazy=RetLazy0,
      Docall=varargs(FixedLength)
   ; (FnHead=Fn, LenArgsHead=LenArgs) ->
      EvalArgs=LazyVars,
      ResultLazy=x(noeval,eager,[]),
      Docall=yes
   ; transpiler_predicate_store(_,Fn,LenArgsFull,_,_,ArgsLazy0,RetLazy0),append(LenRest,LenArgs,LenArgsFull) ->
      % deal with curried case
      sum_list(LenArgs,LenArgsTotal),
      length(EvalArgs,LenArgsTotal),
      append(EvalArgs,EvalArgsCurried,ArgsLazy0),
      ResultLazy=RetLazy0,
      Docall=curried(EvalArgsCurried,LenRest)
   ; transpiler_predicate_store(_,Fn,_LenArgsBase,_,_,_,x(_,eager,[[predicate_call,LenArgsPart,ArgsLazy1,RetLazy1]])),
   append(LenArgsPart,[0],LenArgs) ->
      % deal calling the curried case
      EvalArgs=ArgsLazy1,
      ResultLazy=RetLazy1,
      Docall=call_curried([0])
   ; transpiler_predicate_store(_,Fn,LenArgsBase,_,_,_,x(_,eager,[[predicate_call,LenArgsPart,ArgsLazy1,RetLazy1]])),
   append(LenArgsBase,LenArgsPart,LenArgs) ->
   %trace,
      % deal calling the curried case
      EvalArgs=ArgsLazy1,
      ResultLazy=RetLazy1,
      Docall=call_curried([0])
   ;
      (transpiler_enable_interpreter_calls ->
         % create a stub to call the interpreter
         (create_prefixed_name('mc_',LenArgs,Fn,Fp),
         (current_predicate(Fp/LenArgs) -> true ;
            LenArgs1 is LenArgs+1,
            findall(Atom0, (between(1, LenArgs1, I0) ,Atom0='$VAR'(I0)), AtomList0),
            H @.. [Fp|AtomList0],
            findall(Atom1, (between(1, LenArgs, I1), Atom1='$VAR'(I1)), AtomList1),
            B=..[u_assign,[F|AtomList1],'$VAR'(LenArgs1)],
            compiler_assertz(transpiler_stub_created(F,LenArgs)),
            transpiler_debug(2,format_e("; % ######### warning: creating stub for:~q\n",[F])),
            create_and_consult_temp_file('&self',Fp/LenArgs1,[H:-(format_e("; % ######### warning: using stub for:~q\n",[F]),B)])
         ),
         ResultLazy=x(noeval,eager,[]),
         Docall=yes)
      ;
         % no inteprter calls, so make this inline
         ResultLazy=x(noeval,eager,[]),
         Docall=no
      ),
      length(UpToDateArgsLazy, LenArgsTotal),
      maplist(=(x(noeval,eager,[])), UpToDateArgsLazy),
      % get the evaluation/laziness based on the types, but then update from the actual signature using 'update_laziness'
      get_operator_typedef_props(_,Fn,LenArgsTotal,Types0,_RetType0),
      maplist(arg_eval_props,Types0,EvalArgs0),
      maplist(update_laziness,EvalArgs0,UpToDateArgsLazy,EvalArgs)
   ),
   % add transpiler_depends_on clause if not already there
   (((FnHead-LenArgsHead)=(Fn-LenArgs) ; FnHead='' ; transpiler_depends_on(FnHead,LenArgsHead,Fn,LenArgs)) ->
      true
   ;
      compiler_assertz(transpiler_depends_on(FnHead,LenArgsHead,Fn,LenArgs)),
      transpiler_debug(2,format_e("Asserting: transpiler_depends_on(~q,~q,~q,~q)\n",[FnHead,LenArgsHead,Fn,LenArgs]))
   ),
   append(Args,ArgsFlattened),
   (Docall=yes ->
      maplist(f2p(HeadIs,LazyVars), RetResultsParts, RetResultsPartsN, LazyResultParts, ArgsFlattened, ConvertedParts, ConvertedNParts),
      maplist(lazy_impedance_match, LazyResultParts, EvalArgs, RetResultsParts, ConvertedParts, RetResultsPartsN, ConvertedNParts, RetResults, Converteds),
      append(Converteds,Converteds2),
      assign_only(Converteds2,RetResult,[fcall(Fn,LenArgs),RetResults],Converted),
      invert_curried_structure(Fn,LenArgs,RetResults,RecurriedList),
      assign_or_direct_var_only(Converteds2,RetResultN,list(RecurriedList),ConvertedN)
   ; Docall=curried(EvalArgsC,LenArgsC) ->
      maplist(f2p(HeadIs,LazyVars), RetResultsParts, RetResultsPartsN, LazyResultParts, ArgsFlattened, ConvertedParts, ConvertedNParts),
      maplist(lazy_impedance_match, LazyResultParts, EvalArgs, RetResultsParts, ConvertedParts, RetResultsPartsN, ConvertedNParts, RetResults, Converteds),
      append(Converteds,Converteds2),
      assign_only(Converteds2,RetResult,[curried_fcall(Fn,LenArgs,LenArgsC,EvalArgsC),RetResults],Converted), %%% remove me
      invert_curried_structure(Fn,LenArgs,RetResults,RecurriedList),
      %assign_or_direct_var_only(Converteds2,RetResult,list(RecurriedList),Converted),
      assign_or_direct_var_only(Converteds2,RetResultN,list(RecurriedList),ConvertedN)
   ; Docall=varargs(FixedLength2) ->
      maplist(f2p(HeadIs,LazyVars), RetResultsParts, RetResultsPartsN, LazyResultParts, ArgsFlattened, ConvertedParts, ConvertedNParts),
      maplist(lazy_impedance_match, LazyResultParts, EvalArgs, RetResultsParts, ConvertedParts, RetResultsPartsN, ConvertedNParts, RetResults, Converteds),
      append(Converteds,Converteds2),
      assign_only(Converteds2,RetResult,[call_var(Fn,FixedLength2)|RetResults],Converted),
      invert_curried_structure(Fn,LenArgs,RetResults,RecurriedList),
      assign_or_direct_var_only(Converteds2,RetResultN,list(RecurriedList),ConvertedN)
   ; Docall=call_curried(LenArgsP) ->
   %trace,
      maplist(f2p(HeadIs,LazyVars), RetResultsParts, RetResultsPartsN, LazyResultParts, ArgsFlattened, ConvertedParts, ConvertedNParts),
      maplist(lazy_impedance_match, LazyResultParts, EvalArgs, RetResultsParts, ConvertedParts, RetResultsPartsN, ConvertedNParts, RetResults, Converteds),
      append(Converteds,Converteds2),
      assign_only(Converteds2,RetResult,[native_call,Fn,LenArgsP,RetResults],Converted),
      invert_curried_structure(Fn,LenArgs,RetResults,RecurriedList),
      assign_or_direct_var_only(Converteds2,RetResultN,list(RecurriedList),ConvertedN)
   ;
      maplist(f2p(HeadIs,LazyVars), RetResultsParts, RetResultsPartsN, LazyResultParts, Convert, ConvertedParts, ConvertedNParts),
      % do this twice so that RetResult and RetResultN are distinct
      f2p_do_group(x(doeval,eager,[]),LazyResultParts,RetResultsParts,DoEvalRetResults,ConvertedParts,DoEvalCodeCollected),
      f2p_do_group(x(noeval,eager,[]),LazyResultParts,RetResultsPartsN,NoEvalRetResults,ConvertedNParts,NoEvalCodeCollected),
      assign_or_direct_var_only(DoEvalCodeCollected,RetResult,list(DoEvalRetResults),Converted),
      assign_or_direct_var_only(NoEvalCodeCollected,RetResultN,list(NoEvalRetResults),ConvertedN)
   ).

f2p(HeadIs, LazyVars, RetResult, RetResultN, ResultLazy, Convert, Converted, ConvertedN) :-
   get_curried_name_structure(Convert,Fn,Args,LenArgs),
   fullvar(Fn),
   sum_list(LenArgs,LenArgsTotal),
   %var_prop_lookup(Fn,LazyVars,Sig) -> Sig=x(_,_,[[predicate_call|_]]),
   !,
   ResultLazy=x(noeval,eager,[]),
   length(UpToDateArgsLazy, LenArgsTotal),
   maplist(=(x(doeval,eager,[])), UpToDateArgsLazy),
   EvalArgs=UpToDateArgsLazy,
   append(Args,ArgsFlattened),
   maplist(f2p(HeadIs,LazyVars), RetResultsParts, RetResultsPartsN, LazyResultParts, ArgsFlattened, ConvertedParts, ConvertedNParts),
   maplist(lazy_impedance_match, LazyResultParts, EvalArgs, RetResultsParts, ConvertedParts, RetResultsPartsN, ConvertedNParts, RetResults, Converteds),
   append(Converteds,Converteds2),
   %append(RetResults,[RetResult],RetResults2),
   % BEER this is where to change the call to another function
   create_prefixed_name('mc_',LenArgs,'',Prefix),
   invert_curried_structure(Fn,LenArgs,RetResults,RecurriedList),
   append(Converteds2,[[transpiler_apply,Prefix,Fn,RecurriedList,RetResult,RetResultsParts, RetResultsPartsN, LazyResultParts,ConvertedParts, ConvertedNParts]],Converted),
   assign_or_direct_var_only(Converteds2,RetResultN,list(RecurriedList),ConvertedN).

%transpiler_apply(_,Prefix,Fn,RetResults,RetResult,RetResultsParts, RetResultsPartsN, LazyResultParts,ConvertedParts, ConvertedNParts) :-
transpiler_apply(Prefix,Fn,RetResults,RetResult,RetResultsParts, RetResultsPartsN, LazyResultParts,ConvertedParts, ConvertedNParts) :-
   (atom(Fn),transpiler_predicate_store(_,Fn,LenArgs,_,_,ArgTypes,_RetType),sum_list(LenArgs,L),length(RetResultsParts,L) ->
      atom_concat(Prefix,Fn,Fn2),
      % now do the evaluation and impedance matching
      maplist(runtime_lazy_impedance_match,LazyResultParts,ArgTypes,RetResultsParts,ConvertedParts,RetResultsPartsN,ConvertedNParts,AdjResults),
      append(AdjResults,[RetResult],RetResults2),
      apply(Fn2,RetResults2)
   ;
      RetResult=RetResults
   ).

% eager -> eager, lazy -> lazy
runtime_lazy_impedance_match(x(_,X,_),x(doeval,X,_),ValE,[],_ValN,_CodeN,ValE) :- !.
runtime_lazy_impedance_match(x(_,X,_),x(noeval,X,_),_ValE,_CodeE,ValN,[],ValN) :- !.
runtime_lazy_impedance_match(x(_,eager,_),x(doeval,eager,_),ValE,CodeE,_ValN,_CodeN,ValE) :- call(CodeE).
runtime_lazy_impedance_match(x(_,eager,_),x(noeval,eager,_),_ValE,_CodeE,ValN,CodeN,ValN) :- call(CodeN).
runtime_lazy_impedance_match(x(_,lazy,_),x(_,lazy,_),ValE,CodeE,ValN,CodeN,Code) :- !, Code=ispeEnN(ValE,CodeE,ValN,CodeN).
%lazy_impedance_match(x(_,lazy,_),x(_,lazy,_),ValE,CodeE,ValN,CodeN,Val,Code) :- !,
%   append(CodeE,[[native(as_p1_exec),ValE,RetResultE]],CodeAE),
%   append(CodeN,[[native(as_p1_expr),ValN,RetResultN]],CodeAN),
% lazy -> eager
runtime_lazy_impedance_match(x(_,lazy,_),x(doeval,eager,_),ValE,CodeE,_ValN,_CodeN,RetResult) :- !,call(CodeE),RetResult=ValE.
runtime_lazy_impedance_match(x(_,lazy,_),x(noeval,eager,_),_ValE,_CodeE,ValN,CodeN,RetResult) :- !,call(CodeN),RetResult=ValN.
% eager -> lazy
runtime_lazy_impedance_match(x(_,eager,_),x(doeval,lazy,_),ValE,CodeE,ValN,CodeN,Code) :- Code=ispeEnN(ValE,CodeE,ValN,CodeN).
runtime_lazy_impedance_match(x(_,eager,_),x(noeval,lazy,_),ValE,CodeE,ValN,CodeN,Code) :- Code=ispeEnN(ValE,CodeE,ValN,CodeN).


%-f2p(HeadIs, LazyVars, RetResult, RetResultN, ResultLazy, Convert, Converted, ConvertedN) :-
%-   Convert=[Fn|Args],
%-   fullvar(Fn),
%-   var_prop_lookup(Fn,LazyVars,x(_,_,[[predicate_call]])),!,
%-   length(Args,LenArgs),
%-   ResultLazy=x(noeval,eager,[]),
%-   length(UpToDateArgsLazy, LenArgs),
%-   maplist(=(x(noeval,eager,[])), UpToDateArgsLazy),
%-   EvalArgs=UpToDateArgsLazy,
%-   maplist(f2p(HeadIs,LazyVars), RetResultsParts, RetResultsPartsN, LazyResultParts, Args, ConvertedParts, ConvertedNParts),
%-   maplist(lazy_impedance_match, LazyResultParts, EvalArgs, RetResultsParts, ConvertedParts, RetResultsPartsN, ConvertedNParts, RetResults, Converteds),
%-   append(Converteds,Converteds2),
%-   append(RetResults,[RetResult],RetResults2),
%-   atomic_list_concat(['mc_',LenArgs,'__'],Prefix),
%-   append(Converteds2,[[native(atom_concat),Prefix,Fn,Fn2],[native(apply),Fn2,RetResults2]],Converted),
%-   assign_or_direct_var_only(Converteds2,RetResultN,list([Fn|RetResults]),ConvertedN).

f2p(HeadIs, LazyVars, RetResult, RetResultN, x(noeval,eager,[]), Convert, Converted, ConvertedN) :-
    Convert=[Fn|_], \+ atom(Fn),
    maplist(f2p(HeadIs,LazyVars), RetResultsParts, RetResultsPartsN, LazyResultParts, Convert, ConvertedParts, ConvertedNParts),
    f2p_do_group(x(doeval,eager,[]),LazyResultParts,RetResultsParts,DoEvalRetResults,ConvertedParts,DoEvalCodeCollected),
    f2p_do_group(x(noeval,eager,[]),LazyResultParts,RetResultsPartsN,NoEvalRetResults,ConvertedNParts,NoEvalCodeCollected),
    assign_or_direct_var_only(DoEvalCodeCollected,RetResult,list(DoEvalRetResults),Converted),
    assign_or_direct_var_only(NoEvalCodeCollected,RetResultN,list(NoEvalRetResults),ConvertedN), !.

/*
f2p(HeadIs,LazyVars,RetResult,ResultLazy,Convert,Converted):-fail,
   Convert=[Fn|_],
   atom(Fn),
   compile_flow_control3(HeadIs,LazyVars,RetResult,ResultLazy,Convert,Converted),!.
*/

% The catch-all If no specific case is matched, consider Convert as already converted.
%f2p(_HeadIs, LazyVars, _RetResult, ResultLazy, x_assign(Convert,Res), x_assign(Convert,Res)):- !.
%f2p(_HeadIs, LazyVars, RetResult, ResultLazy, Convert, Code):- into_x_assign(Convert,RetResult,Code).


/*%f2p(HeadIs, LazyVars,  list(Convert), ResultLazy,  Convert, []) :- trace,HeadIs\=@=Convert,
%   is_list(Convert),!.
f2p(HeadIs, LazyVars, list(Converted), _ResultLazy, Convert, Codes) :- %HeadIs\=@=Convert,
   is_list(Convert),!,
   length(Convert, N),
   % create an eval-args list. TODO FIXME revisit this after working out how lists handle evaluation
   % such as maplist(=(ResultLazy), EvalArgs),
   length(EvalArgs, N),
   maplist(=(eager), EvalArgs),
   maplist(f2p_skip_atom(HeadIs, LazyVars),Converted,EvalArgs,Convert,Allcodes),
   append(Allcodes,Codes).

f2p_skip_atom(_HeadIs, _LazyVars,Converted, _EvalArgs, Convert,true):-
  \+ compound(Convert), !, Converted = Convert.
f2p_skip_atom(HeadIs, LazyVars,Converted,EvalArgs,Convert,Allcodes):-
   f2p(HeadIs, LazyVars,Converted,EvalArgs,Convert,Allcodes).
*/

f2p(HeadIs, LazyVars, RetResult, RetResultN, x(noeval,eager,[]), Convert, Converted, ConvertedN) :-
    HeadIs\==Convert, is_list(Convert),
    maplist(f2p(HeadIs,LazyVars), RetResultsParts, RetResultsPartsN, LazyResultParts, Convert, ConvertedParts, ConvertedNParts),
    f2p_do_group(x(doeval,eager,[]),LazyResultParts,RetResultsParts,DoEvalRetResults,ConvertedParts,DoEvalCodeCollected),
    f2p_do_group(x(noeval,eager,[]),LazyResultParts,RetResultsPartsN,NoEvalRetResults,ConvertedNParts,NoEvalCodeCollected),
    assign_or_direct(DoEvalCodeCollected,RetResult,list(DoEvalRetResults),Converted),
    assign_or_direct(NoEvalCodeCollected,RetResultN,list(NoEvalRetResults),ConvertedN), !.

f2p(HeadIs,LazyVars,_,_,EvalArgs,Convert,_,_):-
   format_e("Error in f2p ~w ~w ~w ~w\n",[HeadIs,LazyVars,Convert,EvalArgs]), bt,
   throw(0).

/*
f2p(_HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :-
   (is_ftVar(Convert);number(Convert)),!, % Check if Convert is a variable
   var_prop_lookup(Convert,LazyVars,EL),
   lazy_impedance_match(EL,ResultLazy,Convert,[],RetResult,Converted).


% If Convert is not expected to be evaluatble, it is considered as already converted.
f2p(_HeadIs, _LazyVars, RetResult, ResultLazy, Convert, Converted) :- fail, % HeadIs\=@=Convert,
    %once(number(Convert); atom(Convert); data_term(Convert)),  % Check if Convert is a number or an atom
    once(number(Convert); atomic(Convert); \+compound(Convert); data_term(Convert)),
    must_det_lls(get_val_types(Convert,Types)->true;Types=['%NoValTypes%']),
    (ResultLazy=eager -> C2=Convert ; C2=[is_p1,[ResultLazy|Types],Convert,[],Convert]),
    Converted=[[assign,RetResult,C2]],
    % For OVER-REACHING categorization of dataobjs %
    % wdmsg(data_term(Convert)),
    %trace_break,
    !.  % Set RetResult to Convert as it is already in predicate form
*/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% ast to prolog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ast_to_prolog(Caller,DontStub,A,Result) :-
   maplist(ast_to_prolog_aux(Caller,DontStub),A,B),
   combine_code_list(B,Result),!.

ast_to_prolog_aux(_,_,A,A) :- fullvar(A),!.
ast_to_prolog_aux(_,_,H,H):- \+ compound(H),!.
ast_to_prolog_aux(_,_,inline(Code),Code) :- !.
ast_to_prolog_aux(Caller,DontStub,list(A),B) :- !,maplist(ast_to_prolog_aux(Caller,DontStub),A,B).
ast_to_prolog_aux(Caller,DontStub,list_with_tail(A,T),B) :- !,
   maplist(ast_to_prolog_aux(Caller,DontStub),A,A0),
   ast_to_prolog_aux(Caller,DontStub,T,T0),
   append(A0,T0,B).
ast_to_prolog_aux(_,_,[Var|Rest],[Var|Rest]):- fullvar(Var),!.
ast_to_prolog_aux(Caller,DontStub,[prolog_if,If,Then,Else],R) :- !,
   ast_to_prolog(Caller,DontStub,If,If2),
   ast_to_prolog(Caller,DontStub,Then,Then2),
   ast_to_prolog(Caller,DontStub,Else,Else2),
   R=((If2) *-> (Then2);(Else2)).
ast_to_prolog_aux(_,_,[assign,A,X0],(A=X0)) :- fullvar(X0),!.
ast_to_prolog_aux(Caller,DontStub,[native(FIn)|ArgsIn],A) :- !,
 must_det_lls((
   FIn @.. [F|Pre], % allow compound natives
   append(Pre,ArgsIn,Args0),
   %label_arg_types(F,1,Args0),
   maplist(ast_to_prolog_aux(Caller,DontStub),Args0,Args1),
   %label_arg_types(F,1,Args1),
   A ~.. [xxx(6),F|Args1]
   %notice_callee(Caller,A)
   )).
ast_to_prolog_aux(Caller,DontStub,[transpiler_apply,Prefix,Fn,RetResults,RetResult,RetResultsParts, RetResultsPartsN, LazyResultParts,ConvertedParts, ConvertedNParts],A) :- !,
 must_det_lls((
   %label_arg_types(F,1,ArgsIn),
   maplist(ast_to_prolog(Caller,DontStub),ConvertedParts,ConvertedPartsA),
   maplist(ast_to_prolog(Caller,DontStub),ConvertedNParts,ConvertedNPartsA),
   ast_to_prolog_aux(Caller,DontStub,Fn,FnA),
   ast_to_prolog_aux(Caller,DontStub,RetResults,RetResultsA),
   ast_to_prolog_aux(Caller,DontStub,RetResult,RetResultA),
   ast_to_prolog_aux(Caller,DontStub,RetResultsParts,RetResultsPartsA),
   ast_to_prolog_aux(Caller,DontStub,RetResultsPartsN,RetResultsPartsNA),
   ast_to_prolog_aux(Caller,DontStub,LazyResultParts,LazyResultPartsA),
   %label_arg_types(F,1,Args1),
   %random(0,1000,Rand),
   %A=..[transpiler_apply,Rand,Prefix,FnA,RetResultsA,RetResultA,RetResultsPartsA, RetResultsPartsNA, LazyResultPartsA,ConvertedPartsA, ConvertedNPartsA]
   A=..[transpiler_apply,Prefix,FnA,RetResultsA,RetResultA,RetResultsPartsA, RetResultsPartsNA, LazyResultPartsA,ConvertedPartsA, ConvertedNPartsA]
   %notice_callee(Caller,A)
   )).

% ORIG ast_to_prolog_aux(_,_,[ispu,R],ispu(R)) :- !.
ast_to_prolog_aux(_,_,[ispu,R],(R)) :- !.
ast_to_prolog_aux(Caller,DontStub,[ispuU,R,Code0],ispuU(R,Code1)) :- !,
   ast_to_prolog(Caller,DontStub,Code0,Code1).
ast_to_prolog_aux(Caller,DontStub,[ispeEn,R,Code0,Expr],ispeEn(R,Code1,Expr)) :- !,
   ast_to_prolog(Caller,DontStub,Code0,Code1).
ast_to_prolog_aux(Caller,DontStub,[ispeEnN,R,Code0,Expr,CodeN0],ispeEnN(R,Code1,Expr,CodeN1)) :- !,
   ast_to_prolog(Caller,DontStub,Code0,Code1),
   ast_to_prolog(Caller,DontStub,CodeN0,CodeN1).
ast_to_prolog_aux(Caller,DontStub,[ispeEnNC,R,Code0,Expr,CodeN0,CodeC0],ispeEnNC(R,Code1,Expr,CodeN1,CodeC1)) :- !,
   ast_to_prolog(Caller,DontStub,Code0,Code1),
   ast_to_prolog(Caller,DontStub,CodeN0,CodeN1),
   ast_to_prolog(Caller,DontStub,CodeC0,CodeC1).
ast_to_prolog_aux(Caller,DontStub,[assign,A,[fcall(FIn,LenArgs),ArgsIn]],R) :- (fullvar(A); \+ compound(A)),callable(FIn),!,
 must_det_lls((
   FIn @.. [F|Pre], % allow compound natives
   append(Pre,ArgsIn,Args00),
   maybe_lazy_list(Caller,F,1,Args00,Args0),
   %label_arg_types(F,1,Args0),
   maplist(ast_to_prolog_aux(Caller,DontStub),Args0,Args1),
   create_prefixed_name('mi_',LenArgs,F,Fp), % TODO
   %label_arg_types(F,0,[A|Args1]),
   %LenArgs1 is LenArgs+1,
   append(Args1,[A],Args2),
   R ~.. [f(FIn),Fp|Args2],
   (Caller=caller(CallerInt,CallerSz),(CallerInt-CallerSz)\=(F-LenArgs),\+ transpiler_depends_on(CallerInt,CallerSz,F,LenArgs) ->
      compiler_assertz(transpiler_depends_on(CallerInt,CallerSz,F,LenArgs)),
      transpiler_debug(2,format_e("Asserting: transpiler_depends_on(~q,~q,~q,~q)\n",[CallerInt,CallerSz,F,LenArgs]))
   ; true)
   %sum_list(LenArgs,LenArgsTotal),
   %LenArgsTotalPlus1 is LenArgsTotal+1,
   %((current_predicate(Fp/LenArgsTotalPlus1);member(F/LenArgs,DontStub)) ->
   %   true
   %; check_supporting_predicates('&self',F/LenArgs))
   %notice_callee(Caller,F/LenArgs)
   )).
ast_to_prolog_aux(Caller,DontStub,[assign,A,[hcall(FIn,LenArgs),ArgsIn]],R) :- (fullvar(A); \+ compound(A)),callable(FIn),!,
 must_det_lls((
   FIn @.. [F|Pre], % allow compound natives
   append(Pre,ArgsIn,Args00),
   maybe_lazy_list(Caller,F,1,Args00,Args0),
   %label_arg_types(F,1,Args0),
   maplist(ast_to_prolog_aux(Caller,DontStub),Args0,Args1),
   create_prefixed_name('mc_',LenArgs,F,Fp),
   %label_arg_types(F,0,[A|Args1]),
   %LenArgs1 is LenArgs+1,
   append(Args1,[A],Args2),
   R ~.. [f(FIn),Fp|Args2],
   (Caller=caller(CallerInt,CallerSz),(CallerInt-CallerSz)\=(F-LenArgs),\+ transpiler_depends_on(CallerInt,CallerSz,F,LenArgs) ->
      compiler_assertz(transpiler_depends_on(CallerInt,CallerSz,F,LenArgs)),
      transpiler_debug(2,format_e("Asserting: transpiler_depends_on(~q,~q,~q,~q)\n",[CallerInt,CallerSz,F,LenArgs]))
   ; true)
   %sum_list(LenArgs,LenArgsTotal),
   %LenArgsTotalPlus1 is LenArgsTotal+1,
   %((current_predicate(Fp/LenArgsTotalPlus1);member(F/LenArgs,DontStub)) ->
   %   true
   %; check_supporting_predicates('&self',F/LenArgs))
   %notice_callee(Caller,F/LenArgs)
   )).
ast_to_prolog_aux(Caller,DontStub,[assign,A,[native_call,F,LenArgs,ArgsIn]],R) :- (fullvar(A); \+ compound(A)),!,
 must_det_lls((
   maybe_lazy_list(Caller,F,1,ArgsIn,Args0),
   maplist(ast_to_prolog_aux(Caller,DontStub),Args0,Args1),
   create_prefixed_name('mc_',LenArgs,F,Fp),
   append(Args1,[A],Args2),
   R0 =..[Fp,XX],
   R1=..[apply_fn,XX,Args2],
   R=..[',',R0,R1],
   (Caller=caller(CallerInt,CallerSz),(CallerInt-CallerSz)\=(F-LenArgs),\+ transpiler_depends_on(CallerInt,CallerSz,F,LenArgs) ->
      compiler_assertz(transpiler_depends_on(CallerInt,CallerSz,F,LenArgs)),
      transpiler_debug(2,format_e("Asserting: transpiler_depends_on(~q,~q,~q,~q)\n",[CallerInt,CallerSz,F,LenArgs]))
   ; true)
   )).
ast_to_prolog_aux(Caller,DontStub,[curried_fcall(FIn,LenArgs,LenArgsRest,_SigRest),ArgsIn],R0) :- !,
 %must_det_lls((
   maybe_lazy_list(Caller,FIn,1,ArgsIn,Args0),
   %label_arg_types(FIn,1,Args0),
   maplist(ast_to_prolog_aux(Caller,DontStub),Args0,Args1),
   append(LenArgsRest,LenArgs,LenArgsAll),
   create_prefixed_name('mc_',LenArgsAll,FIn,Fp),
   %label_arg_types(FIn,0,[A|Args1]),
   %LenArgs1 is LenArgs+1,
   R0 ~.. [xxx(4),Fp|Args1],
   %R1=R0),
   (Caller=caller(CallerInt,CallerSz),(CallerInt-CallerSz)\=(FIn-LenArgs),\+ transpiler_depends_on(CallerInt,CallerSz,FIn,LenArgs) ->
      compiler_assertz(transpiler_depends_on(CallerInt,CallerSz,FIn,LenArgs)),
      transpiler_debug(2,format_e("Asserting: transpiler_depends_on(~q,~q,~q,~q)\n",[CallerInt,CallerSz,FIn,LenArgs]))
   ; true)
   %))
   .
ast_to_prolog_aux(Caller,DontStub,[assign,A,[call_var(FIn,FixedArity)|ArgsIn]],R) :- (fullvar(A); \+ compound(A)),callable(FIn),!,
 must_det_lls((
   FIn @.. [F|Pre], % allow compound natives
   append(Pre,ArgsIn,Args00),
   maybe_lazy_list(Caller,F,1,Args00,Args0),
   %label_arg_types(F,1,Args0),
   maplist(ast_to_prolog_aux(Caller,DontStub),Args0,Args1),
   atomic_list_concat(['mc_n_',FixedArity,'__',F],Fp),
   %label_arg_types(F,0,[A|Args1]),
   % bundle the variable arguments into a list
   length(FixedPart,FixedArity),
   append(FixedPart,VariablePart,Args1),
   append(FixedPart,[VariablePart],Args1a),
   append(Args1a,[A],Args2),
   R ~.. [xxx(3),Fp|Args2],
   (Caller=caller(CallerInt,CallerSz),(CallerInt-CallerSz)\=(F-0),\+ transpiler_depends_on(CallerInt,CallerSz,F,0) ->
      compiler_assertz(transpiler_depends_on(CallerInt,CallerSz,F,0)),
      transpiler_debug(2,format_e("Asserting: transpiler_depends_on(~q,~q,~q,~q)\n",[CallerInt,CallerSz,F,0]))
   ; true),
   ((current_predicate(Fp/LenArgs);member(F/LenArgs,DontStub)) ->
      true
   ; check_supporting_predicates('&self',F/LenArgs)))).
%ast_to_prolog_aux(Caller,DontStub,[native(F)|Args0],A) :- !,
%   label_arg_types(F,1,Args0),
%   maplist(ast_to_prolog_aux(Caller,DontStub),Args0,Args1),
%   label_arg_types(F,1,Args1),
%   A ~.. [xxx(2),F|Args1],
%   notice_callee(Caller,A))).
%ast_to_prolog_aux(Caller,DontStub,[assign,A,[call(FIn)|ArgsIn]],R) :- (fullvar(A); \+ compound(A)),callable(FIn),!,
% must_det_lls((
%   FIn @.. [F|Pre], % allow compound natives
%   append(Pre,ArgsIn,Args00),
%   maybe_lazy_list(Caller,F,1,Args00,Args0),
%   label_arg_types(F,1,Args0),
%   maplist(ast_to_prolog_aux(Caller,DontStub),Args0,Args1),
%   length(Args0,LenArgs),
%   create_prefixed_name('mc_',LenArgs,F,Fp),
%   label_arg_types(F,0,[A|Args1]),
%   %LenArgs1 is LenArgs+1,
%   append(Args1,[A],Args2),
%   R ~.. [xxx(1),Fp|Args2].
ast_to_prolog_aux(Caller,DontStub,[assign,A,X0],(A=X1)) :- ast_to_prolog_aux(Caller,DontStub,X0,X1),!.
ast_to_prolog_aux(Caller,DontStub,[assign,A,X0],(A=X1)) :-   must_det_lls(label_type_assignment(A,X0)), ast_to_prolog_aux(Caller,DontStub,X0,X1),label_type_assignment(A,X1),!.
ast_to_prolog_aux(Caller,DontStub,[prolog_match,A,X0],(A=X1)) :- ast_to_prolog_aux(Caller,DontStub,X0,X1),!.

ast_to_prolog_aux(Caller,DontStub,[native_disjunct,Disjuncts],NewFArgs) :- combine_code_list_disjunct(Caller,DontStub,Disjuncts,NewFArgs).

ast_to_prolog_aux(Caller,DontStub,[prolog_catch,Catch,Ex,Catcher],R) :-  ast_to_prolog(Caller,DontStub,Catch,Catch2), R=  catch(Catch2,Ex,Catcher).
ast_to_prolog_aux(_Caller,_DontStub,[prolog_inline,Prolog],R) :- !, R= Prolog.
ast_to_prolog_aux(Caller, DontStub, if_or_else(If,Else),R):-
  ast_to_prolog_aux(Caller, DontStub, (If*->true;Else),R).
ast_to_prolog_aux(Caller, DontStub, Smack,R):- fail,
               compound(Smack),
               Smack=..[NSF, _,_AnyRet, Six66,_Self, FArgs,Ret],
               (NSF = eval_args;NSF = eval_20),
               \+ atom_concat(find,_,NSF),
               \+ atom_concat(_,e,NSF),
               Six66 == 666,
    ast_to_prolog_aux(Caller,DontStub,eval(FArgs,Ret),R).
ast_to_prolog_aux(Caller,DontStub, eval([F|Args],Ret),R):- atom(F),is_list(Args),
   ast_to_prolog_aux(Caller,DontStub,[assign,Ret,[call(F),Args]],R), !.

ast_to_prolog_aux(_,_,'#\\'(A),A).

%ast_to_prolog_aux(_,_,A=B,A=B):- must_det_lls(label_type_assignment(A,B)).

ast_to_prolog_aux(Caller,DontStub,(True,T),R) :- True == true, ast_to_prolog_aux(Caller,DontStub,T,R).
ast_to_prolog_aux(Caller,DontStub,(T,True),R) :- True == true, ast_to_prolog_aux(Caller,DontStub,T,R).
ast_to_prolog_aux(Caller,DontStub,(H;T),(HH;TT)) :- ast_to_prolog_aux(Caller,DontStub,H,HH),ast_to_prolog_aux(Caller,DontStub,T,TT).
ast_to_prolog_aux(Caller,DontStub,(H,T),(HH,TT)) :- ast_to_prolog_aux(Caller,DontStub,H,HH),ast_to_prolog_aux(Caller,DontStub,T,TT).
ast_to_prolog_aux(Caller,DontStub,do_metta_runtime(T,G),do_metta_runtime(T,GGG)) :- !, ast_to_prolog_aux(Caller,DontStub,G,GG),combine_code(GG,GGG).
ast_to_prolog_aux(Caller,DontStub,loonit_assert_source_tf(T,G),loonit_assert_source_tf(T,GG)) :- !, ast_to_prolog_aux(Caller,DontStub,G,GG).
ast_to_prolog_aux(Caller,DontStub,findall(T,G,L),findall(T,GG,L)) :- !, ast_to_prolog_aux(Caller,DontStub,G,GG).
ast_to_prolog_aux(Caller,DontStub,FArgs,NewFArgs):-
   \+ is_list(FArgs),
   compound(FArgs),!,
   compound_name_arguments(FArgs, Name, Args),
   maplist(ast_to_prolog_aux(Caller,DontStub),Args,NewArgs),
   compound_name_arguments(NewCompound, Name, NewArgs),NewFArgs=NewCompound.


%ast_to_prolog_aux(Caller,DontStub,[H],HH) :- ast_to_prolog_aux(Caller,DontStub,H,HH).
%ast_to_prolog_aux(Caller,DontStub,[H|T],(HH,TT)) :- ast_to_prolog_aux(Caller,DontStub,H,HH),ast_to_prolog_aux(Caller,DontStub,T,TT).

ast_to_prolog_aux(_,_,A,A).


combine_code_list_disjunct(_Caller,_DontStub,[],false).
combine_code_list_disjunct(Caller,DontStub,[H],H0) :- !,ast_to_prolog(Caller,DontStub,H,H0).
combine_code_list_disjunct(Caller,DontStub,[H|T],R) :-
   ast_to_prolog(Caller,DontStub,H,H0),
   combine_code_list_disjunct(Caller,DontStub,T,T0),
   (H0=false->
      R=T0
   ;
      R=..[';',H0,T0]
   ).

combine_code_list(A,R) :- !,
   combine_code_list_aux(A,R0),
   (R0=[] -> R=true
   ; R0=[R1] -> R=R1
   ; R0=[H|T],
      combine_code_list(T,T0),
      R=..[',',H,T0]).

combine_code_list_aux([],[]).
combine_code_list_aux([true|T],R) :- !,combine_code_list_aux(T,R).
combine_code_list_aux([H|T],R) :- H=..[','|H0],!,append(H0,T,T0),combine_code_list_aux(T0,R).
combine_code_list_aux([H|T],[H|R]) :- combine_code_list_aux(T,R).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% writing out the result
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

create_and_consult_temp_file(_Space,F/A,PredClauses):- fail, !,
    abolish(F/A),maplist(compiler_assertz,PredClauses).

create_and_consult_temp_file(Space,F/A,PredClauses):-  fail, !,
        must_det_lls((
        %1)Createthememoryfilehandle
        new_memory_file(MemFile),

        %2)Openthememoryfileforwriting
        open_memory_file(MemFile,write,TempStream),

        %Writethetabledpredicatetothememoryfile
        format(TempStream,':-multifile((~q)/~q).~n',[metta_compiled_predicate,3]),
        format(TempStream,':-dynamic((~q)/~q).~n',[metta_compiled_predicate,3]),
        format(TempStream,'~N~q.~n',[metta_compiled_predicate(Space,F,A)]),

        format(TempStream,':-multifile((~q)/~q).~n',[F,A]),
        format(TempStream,':-dynamic((~q)/~q).~n',[F,A]),

        %Iftablingisturnedon:
        if_t(
        option_value('tabling','True'),
        format(TempStream,':-~q.~n',[table(F/A)])
    ),

    %Writeeachclause
    maplist(write_clause(TempStream),PredClauses),

    %Closethewritestream
    close(TempStream),

    %3)Openthememoryfileforreading
    open_memory_file(MemFile,read,ConsultStream),


    %4)Consultorloadtheclausesfromthememorystream
    %IfyourPrologsupportsconsult/1onastream,youcoulddo:
    %consult(ConsultStream).
    %Otherwise,useload_files/2withstream/1:
    load_files(user,[stream(ConsultStream)]),

    %Closethereadstream
    close(ConsultStream),

    %5)Freethememoryfile(noneedforon-diskcleanup)
    free_memory_file(MemFile),

    %Confirmthepredicateispresent
    current_predicate(F/A)
    )),!.

% Predicate to create a temporary file and write the tabled predicate
create_and_consult_temp_file(Space,F/A, PredClauses) :-
  must_det_lls((
    % Generate a unique temporary memory buffer
    tmp_file_stream(text, TempFileName, TempFileStream),
    % Write the tabled predicate to the temporary file
    make_multifile_dynamic(TempFileStream,metta_compiled_predicate, 3),
    write_clause(TempFileStream,metta_compiled_predicate(Space,F,A)),
    make_multifile_dynamic(TempFileStream,F, A),
    %if_t( \+ option_value('tabling',false),
    if_t(option_value('tabling','True'),write_clause(TempFileStream,(:- table(F/A)))),
    maplist(write_clause(TempFileStream), PredClauses),
    % Close the temporary file
    close(TempFileStream),
    % Consult the temporary file
    % abolish(F/A),
    /*'&self':*/
    % sformat(CAT,'cat ~w',[TempFileName]), shell(CAT),
    %consult(TempFileName),

    % listing(F/A),
    % Delete the temporary file after consulting
    delete_file(TempFileName),
    assertion(current_predicate(F/A)),
    %listing(metta_compiled_predicate/3),
    true)).


make_multifile_dynamic(TempFileStream,F, A):-
    write_clause(TempFileStream, (:- multifile(F/A))),
    write_clause(TempFileStream, (:- dynamic(F/A))),!.



write_to_streams(StreamList, Format, Args) :-
    % Write to each stream in the list
    forall(member(Stream, StreamList),
           format(Stream, Format, Args)),
    % Write to stdout
    format(user_output, Format, Args),
    flush_output(user_output). % Ensure output is displayed immediately


%metta_compiled_predicate(_,F,A):- metta_compiled_predicate(F,A).

% Helper predicate to write a clause to the file
write_clause(Stream, Clause) :-
    must_det_lls((subst_vars(Clause,Can),
    write_clause_can(Stream, Can),
    write_clause_mem(Can))).

write_clause_can(Stream, Can):-
    must_det_lls((write_canonical(Stream, Can),
    write(Stream, '.'),
    nl(Stream))).

write_clause_mem(:- (Can)):- !, forall(must_det_lls(Can),true).
write_clause_mem(Can):- compiler_assertz(Can).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STILL unsorted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Meta-predicate that ensures that for every instance where G1 holds, G2 also holds.
:- meta_predicate(for_all(0,0)).
for_all(G1,G2):- forall(G1,G2).

:- op(700,xfx,'=~').

compound_non_cons(B):-  compound(B),  \+ B = [_|_].
iz_conz(B):- compound(B), B=[_|_].

'=~'(A,B):- a_f_args(A,B), notrace('=~0'(A,B)).

'=~0'(A,B):- compound_non_cons(B),!,into_list_args(B,BB),!,'=~'(A,BB).
'=~0'(B,A):- compound_non_cons(B),!,into_list_args(B,BB),!,'=~'(A,BB).
'=~0'(A,B):- iz_conz(A),iz_conz(B),!,A=B.
'=~0'(A,B):- var(A),iz_conz(B),!,A=B.
'=~0'(A,B):- iz_conz(A),var(B),!,A=B.
'=~0'(A,B):- compound_non_cons(A),var(B),!,A @.. B.
'=~0'(A,B):- compound_non_cons(B),!,A=B.
'=~0'(A,B):- '=..'(A,B).


call_from_comp(FnComp,InterpFn,Args):- use_evaluator(fa(InterpFn,_A), compiler, enabled),!,apply(FnComp,Args).
call_from_comp(_FnComp,InterpFn,Args):- use_evaluator(fa(InterpFn,_A), interp, enabled), Right = [Y],
   peek_scope(Eq,RetType,Depth,Self), !, append(Left,Right,[InterpFn|Args]),eval_args(Eq,RetType,Depth,Self,Left,Y).
call_from_comp(_FnComp,InterpFn,Args):- use_evaluator(fa(InterpFn,_A), hyperon, enabled), !, Right = [Y],
  peek_scope(Eq,RetType,Depth,Self), !, append(Left,Right,[InterpFn|Args]),eval_args(Eq,RetType,Depth,Self,Left,Y).

call_from_comp(FnComp,InterpFn,Args):- use_evaluator(fa(InterpFn,_A), interp, disabled), !, apply(FnComp,Args).
call_from_comp(_FnComp,InterpFn,Args):- use_evaluator(fa(InterpFn,_A),compiler, disabled), Right = [Y],
   peek_scope(Eq,RetType,Depth,Self), !, append(Left,Right,[InterpFn|Args]),eval_args(Eq,RetType,Depth,Self,Left,Y).


call_from_comp(FnComp,InterpFn,Args):-
  \+ \+ ( member(E, Args), compound(E), \+ is_list(E) ),
  \+ use_evaluator(fa(InterpFn,_A), compiler, disabled), !, apply(FnComp,Args).



call_from_comp(FnComp,InterpFn,Args):- fail,
    FA = fa(InterpFn,_),
    \+ use_evaluator(FA, _, _),
    % peek_scope(Eq,RetType,Depth,Self),
    debug_info(compiled_version, writeq(apply(FnComp,Args))),

    Right = [Y], append(Left,Right,Args), X = [InterpFn|Left],

    debug_info(interp_version,( X -> Y)),

 % metta_compiled_predicate
    nl,nl,
    !, apply(FnComp,Args).

/*
    trace,
    compare_impls(
        only_interpreted_eval(FA, Eq, RetType, Depth, Self, X, Y1), Y1,
        only_compiled_eval(FA, Eq, RetType, Depth, Self, X, Y2), Y2,
        Answers, Status),
    ( Status == ok ->
        set_use_evaluator(FA, compiler, enabled)
    ;   set_use_evaluator(FA, interp, enabled)
    ),
    !, member(Y, Answers).
*/
call_from_comp(FnComp,_InterpFn,Args):- apply(FnComp,Args).

/*
call_from_comp(_FnComp,InterpFn,Args):- \+ use_evaluator(fa(InterpFn,_A), _, _),
    Right = [Y], append(Left,Right,Args),
    peek_scope(Eq,RetType,Depth,Self),
    use_right_thing_comp(fa(InterpFn,_A1),Eq,RetType,Depth,Self,[InterpFn|Left],Y).

call_from_comp(FnComp,InterpFn,Args):- \+ use_evaluator(fa(InterpFn,_A), compiler, disabled), !, apply(FnComp,Args).
*/


/*
call_from_comp(_FnComp,InterpFn,Args):- Right = [Y], !,
    peek_scope(Eq,RetType,Depth,Self), !, append(Left,Right,[InterpFn|Args]),
    use_right_thing_comp(fa(InterpFn,_A),Eq,RetType,Depth,Self,Left,Y).
*/

% call_fn_native(F, _InterpFn, Args):- !, true_safe, apply(F, Args).

call_fn_native(F, InterpFn,Args):- true_safe,
    call_from_comp(F, InterpFn,Args).

true_safe.


% ~..
dmp_break:- st,ds,break.
cmpd4lst(A,_):- nonvar(A),dmp_break,fail.
cmpd4lst(_A,[Cmpd,_F|_Args]):- \+ compound(Cmpd),dmp_break,fail.
cmpd4lst(_A,[_Cmpd,_F|Args]):- \+ is_list(Args),dmp_break,fail.
%cmpd4lst(A,[_Cmpd,F|Args]):- atom(F),is_cmp_builtin(F),A=..[F|Args],!.
%cmpd4lst(call_fn_native(F,XXX,Args),[Cmpd,F|Args]):- compound(Cmpd),f(XXX)=Cmpd,!.
cmpd4lst(A,[_Cmpd,F|Args]):- atom(F),!,A=..[F|Args],!.
cmpd4lst(call_fn_native_error(F,xxx(?),Args),[F|Args]):- !.

is_cmp_builtin(is_True).
is_cmp_builtin(as_p1_expr).
is_cmp_builtin(as_p1_exec).
is_cmp_builtin(ispeEnN).
is_cmp_builtin(call_fn_native).


/*
cmpd4lst2(A,Info):- compound(A), A=call_fn_native(F,XXX,Args),!,cmpd4lst(F,XXX,Args,Info).
cmpd4lst2(A,Info):- compound(A), compound_name_arguments(A,F,Args),!,cmpd4lst(F,xxx(?),Args,Info).
cmpd4lst2(A,Info):- A=call_fn_native(F,XXX,Args), Info = [XXX,F|Args], compound(XXX), XXX=xxx(_),!,cmpd4lst(F,XXX,Args,Info).
cmpd4lst2(A,Info):- A=call_fn_native(F,XXX,Args), Info = [F|Args], XXX=xxx(?),!,cmpd4lst(F,XXX,Args,Info).
cmpd4lst2(A,[F|Args]):- trace, ' @.. '(A,[F|Args]).

cmpd4lst(F,_XXX,Args,[F|Args]).
cmpd4lst(F,XXX,Args,[XXX2,F|Args]):- compound(XXX2),!.
*/


%into_list_args(A,AA):- is_ftVar(A),AA=A.
%into_list_args(C,[C]):- \+ compound(C),!.
into_list_args(C,C):- \+ compound(C),!.
into_list_args(A,AA):- is_ftVar(A),AA=A.
into_list_args([H|T],[H|T]):- \+ is_list(T),!.
into_list_args([H,List,A],HT):- H == x_assign,!,append(List,[A],HT),!.
into_list_args([H|T],[H|T]):- is_list(T),!.
into_list_args(x_assign(List, A),[H|T]):- append(List,[A],[H|T]),!.
into_list_args(holds(A),AA):- !, into_list_args(A,AA),!.
into_list_args(C,FArgs):- compound_name_arguments(C,F,Args),!,into_list_args([F|Args],FArgs).

compound_name_list(AsPred,FP,PredArgs):- var(AsPred),!,AsPred=[FP|PredArgs].
compound_name_list(AsPred,FP,PredArgs):- iz_conz(AsPred),!,AsPred=[FP|PredArgs].
compound_name_list(AsPred,FP,PredArgs):- into_list_args(AsPred,[FP|PredArgs]),!.
compound_name_list(AsPred,FP,PredArgs):- compound_non_cons(AsPred),!,compound_name_arguments(AsPred,FP,PredArgs).

strip_m(M:BB,BB):- nonvar(BB),nonvar(M),!.
strip_m(BB,BB).


correct_assertz(Info,InfoC):- \+ compound(Info),!,InfoC=Info.
correct_assertz(M:Info,MM:InfoC):- !, correct_assertz(M,MM),correct_assertz(Info,InfoC).
correct_assertz((Info:- (T, B)),(Info:- (T, B))):- compound(Info), atom(T), !.
correct_assertz((Info:-B),(InfoC:-B)):- !, correct_assertz(Info,InfoC).
correct_assertz(call_fn_native(X,_Info,Y),InfoC):-
 !, must_det_lls(InfoC=..[X|Y]).
correct_assertz(Info,Info).


is_prolog_rule(Info):- strip_module(Info,_,Neck), compound(Neck), compound_name_arity(Neck,F,_), F == ':-'.
is_compiler_data(Info):- strip_module(Info,_,Neck), compound(Neck), compound_name_arity(Neck,F,_), compiler_data(F/_),!.

compiler_assertz(Info):- is_list(Info),!,maplist(compiler_assertz,Info),fail.

compiler_assertz(Info):- (once(correct_assertz(Info,InfoC))),Info\=@=InfoC,!,
   debug_info(compiler_assertz,correct_assertz(ca)),
   compiler_assertz(InfoC).

compiler_assertz(Info):-
     once(try_optimize_prolog(ca,Info,Info2)),
     Info\=@=Info2,!,
     info_identity(Info,Id),
     debug_info(compiler_assertz,optimized_code(Id,ca)),
     send_to_pl_file(optimized_code(Id,ca)),
     send_to_pl_file(in_cmt(Info)),
     compiler_assertz(Info2).


compiler_assertz(Info):-
   (is_prolog_rule(Info)-> debug_info(assertz_code, t(Info));
   (is_compiler_data(Info)-> debug_info(assertz_compiler_data, t(Info));
    debug_info(compiler_assertz, Info))),fail.


compiler_assertz(Info):- skip_redef(Info), !, debug_info(skipping_redef,Info).
compiler_assertz(Info):-
  once(unnumbervars_clause(Info,Assert)),
  transpiler_debug(2,output_prolog(Info)),
    once(locally_clause_asserted(Assert)->true;info_assertz(Info,Assert)),!.

info_assertz(Info,Assert):- send_to_pl_file(Info),assertz(Assert).



send_to_pl_file(Info):-
  ignore((option_value(loading_file,MeTTaFile), MeTTaFile \==[], atom(MeTTaFile),
    atom_concat(MeTTaFile,'.pl',PlFile), % append .pl to the .metta name
    ensure_compiled_created(MeTTaFile,PlFile),
    send_to_pl_file(PlFile,Info))).

send_to_pl_file(PlFile,Info):-
    setup_call_cleanup(open(PlFile, append, Stream, [encoding(utf8)]),
      with_output_to(Stream, maybe_write_info(Info)), close(Stream)),!.

maybe_write_info(Info):- var(Info),!.
maybe_write_info(call(Info)):- ignore(Info),!.
maybe_write_info(in_cmt(Info)):- setup_call_cleanup(format('~N/*~n',[]),maybe_write_info(Info),format(' */~n',[])).
maybe_write_info(Info):- string(Info),!,writeln(Info).
maybe_write_info(Info):- \+ compound(Info),!, ppt(Info).
maybe_write_info(Info):- \+ \+ (no_conflict_numbervars(Info), maybe_write_info0(Info)).
maybe_write_info0((:-B)):-  compound(B),gensym(top_call_,Sym),maybe_write_info1((Sym:-B)), maybe_write_info2((:- Sym)).
maybe_write_info0(Info):- maybe_write_info1(Info).

maybe_write_info1(Info):- fail, once(try_harder_optimize_prolog(wa,Info,Info2)),
     Info\=@=Info2,!,
     %setup_call_cleanup(format('~N/* try_harder_optimize_prolog ~n',[]),maybe_write_info2(Info),format(' */~n',[])),
     maybe_write_info1(Info2).
maybe_write_info1(Info):- maybe_write_info2(Info), !.

maybe_write_info2((:-B)):-  into_plnamed((top_call:- time(B)),Info2), !,nl,nl, no_conflict_numbervars(Info2), portray_clause(Info2), nl,nl.
maybe_write_info2((H:-B)):- into_plnamed((H:-B),Info2), !,nl,nl, no_conflict_numbervars(Info2),ppt(Info2), nl,nl.
maybe_write_info2( Info ):- into_plnamed(Info,Info2), !, writeq(Info2),writeln('.').


ensure_compiled_created(MeTTaFile,PlFile) :-
    \+ exists_file(PlFile),!,write_new_plfile(MeTTaFile,PlFile).
ensure_compiled_created(MeTTaFile,PlFile) :-
 nop(((
    time_file(PlFile, PlTime),
    time_file(MeTTaFile, MeTTaTime),
    if_t(PlTime < MeTTaTime,write_new_plfile(MeTTaFile,PlFile))))).

write_new_plfile(MeTTaFile,PlFile):-
    setup_call_cleanup(open(PlFile, write, Stream, [encoding(utf8)]),
      with_output_to(Stream, setup_pl_file(MeTTaFile)), close(Stream)),!.

setup_pl_file(MeTTaFile) :-
    get_time(Now),
    format_time(atom(Timestamp), '%FT%T%:z', Now),
    format('%% Generated from ~w at ~w~n', [MeTTaFile, Timestamp]),
    writeln(":- style_check(-discontiguous)."),
    writeln(":- style_check(-singleton)."),
    %writeln("%:- set_prolog_flag(mettalog_rt,true)."),
    %writeln("%:- set_prolog_flag(mettalog_rt_args, ['--repl=false'])."), writeln("%:- set_prolog_flag(mettalog_rt_args, ['--repl'])."),
    writeln(":- include(library(metta_lang/metta_transpiled_header))."),
    nl.

:- dynamic(user:on_finish_load_metta/1).
:- multifile(user:on_finish_load_metta/1).

on_finish_load_metta(MeTTaFile):-
   atom_concat(MeTTaFile,'.pl',PlFile),
   get_time(Now),
   format_time(atom(Timestamp), '%FT%T%:z', Now),
   sformat(S, '%% Finished generating ~w at ~w~n', [MeTTaFile, Timestamp]),
   send_to_pl_file(PlFile,S),!,
   send_to_pl_file(PlFile,":- normal_IO."),
   send_to_pl_file(PlFile,":- initialization(transpiled_main, program)."),
   setup_library_calls.


cname_var(Sym,Expr):-  gensym(Sym,ExprV),
    put_attr(Expr,vn,ExprV).
    %ignore(Expr='$VAR'(ExprV)), debug_var(ExprV,Expr).

info_identity(_Info,ID):- nb_current('$info_id',ID),!.
info_identity(_Info,info_id).


skip_redef(Info):- \+ callable(Info),!,fail.
skip_redef(Info:-_):- !,skip_redef_head(user,Info).
skip_redef(_:Info):- \+ callable(Info),!,fail.
skip_redef(M:(Info:-_)):- !,skip_redef_head(M,Info).

skip_redef_head(_,Info):- \+ callable(Info),!,fail.
skip_redef_head(_,M:Info):- !, skip_redef_head(M, Info).
skip_redef_head(M,Info):- predicate_property(M:Info,static),!.
skip_redef_head(_,Info):- predicate_property(Info,static),!.
skip_redef_head(_,Info):- compound(Info),compound_name_arity(Info,F,A), compiler_data(F/A),!,fail.
skip_redef_head(M,Info):- source_file(this_is_in_compiler_lib,F), once(source_file(M:Info,F);source_file(Info,F)).
%skip_redef(Info):- source_file(Info,_). % diallow otehr places

skip_redef_fa(Fn,Arity) :- integer(Arity),!,skip_redef_fa(Fn,[Arity]).
skip_redef_fa(Fn,LenArgs) :-
   create_prefixed_name('mc_',LenArgs,Fn,FnWPrefix),
   sum_list(LenArgs,LenArgsTotal),
   LenArgsTotalPlus1 is LenArgsTotal+1,
   functor_chkd(Info,FnWPrefix,LenArgsTotalPlus1),
   skip_redef_head(user,Info),!.

into_fa(Fn/[Arity],Fn,Arity):- must_be(number,Arity).
into_fa(Fn/Arity,Fn,Arity):- must_be(number,Arity).
into_fa(FnArity,_Fn,_Arity):- throw(type_error(f/a,FnArity)).

%must_det_lls(G):- catch(G,E,(wdmsg(E),fail)),!.
%must_det_lls(G):- rtrace(G),!.
%user:numbervars(Term):- varnumbers:numbervars(Term).

must_det_lls(G):- tracing,!,call(G). % already tracing
must_det_lls((A,B)):- !, (A, B).
must_det_lls(G):- !,call(G). % already tracing
must_det_lls((A,B)):- !, must_det_lls(A),must_det_lls(B).
%must_det_lls((G,B)):- catch(G,E,(wdmsg(E),fail)),!,must_det_lls(B).
%must_det_lls((A,B)):- !, must_det_lls(A),must_det_lls(B).
%must_det_lls(G):- tracing,!,(real_notrace(G)*->true;fail).
must_det_lls(G):- catch(G,E,(wdmsg(E),trace,rtrace(G),fail)),!.
%must_det_lls(G):- must_det_ll(G).
must_det_lls(G):- ignore((notrace,nortrace,trace)),rtrace(G),!.

extract_constraints(V,VS):- var(V),get_attr(V,cns,_Self=Set),!,extract_constraints(_Name,Set,VS),!.
extract_constraints(V,VS):- var(V),VS=[],!.
extract_constraints(V,VS):- var(V),!,ignore(get_types_of(V,Types)),extract_constraints(V,Types,VS),!.
extract_constraints(Converted,VSS):- term_variables(Converted,Vars),
      % assign_vns(0,Vars,_),
       maplist(extract_constraints,Vars,VSS).
extract_constraints(V,[],V=[]):-!.
extract_constraints(V,Types,V=Types).


label_vns(S,G,E):- term_variables(G,Vars),assign_vns(S,Vars,E),!.
assign_vns(S,[],S):-!.
assign_vns(N,[V|Vars],O):- get_attr(V,vn,_),!, assign_vns(N,Vars,O).
assign_vns(N,[V|Vars],O):- format(atom(VN),'~w',['$VAR'(N)]),
  put_attr(V,vn,VN), N2 is N+1, assign_vns(N2,Vars,O).

label_arg_types(_,_,[]):-!.
label_arg_types(F,N,[A|Args]):-
  label_arg_n_type(F,N,A),N2 is N+1,
  label_arg_types(F,N2,Args).

% label_arg_n_type(F,0,A):- !, label_type_assignment(A,F).
label_arg_n_type(F,N,A):- compound(F),functor_chkd(F,Fn,Add),Is is Add+N, !, label_arg_n_type(Fn,Is,A).
label_arg_n_type(F,N,A):- add_type_to(A,arg(F,N)),!.

add_type_to(V,T):- is_list(T), !, maplist(add_type_to(V),T).
add_type_to(V,T):- T =@= val(V),!.
add_type_to(V,T):- ground(T),arg_type_hints(T,H),!,add_1type_to(V,H).
add_type_to(V,T):- add_1type_to(V,T),!.

add_1type_to(V,T):- is_list(T), !, maplist(add_1type_to(V),T).
add_1type_to(V,T):-
 must_det_lls((
   get_types_of(V,TV),
   append([T],TV,TTV),
   set_types_of(V,TTV))).

label_type_assignment(V,O):-
 must_det_lls((
   get_types_of(V,TV), get_types_of(O,TO),
   if_t(\+ (member(val(X),TV), fullvar(X)),
           (add_type_to(V,val(O)),add_type_to(V,TO))),
   %add_type_to(O,val(V)),
           add_type_to(O,TV),
   !)).

is_functor_val(val(_)).

%(: if (-> False $_ $else $else))
%(: if (-> False $T $T $T))

arg_type_hints(arg(is_True,1),'Bool').
arg_type_hints(arg(==,0),'Bool').
arg_type_hints(arg(match,0),['Empty','%Undefined%']).
arg_type_hints(arg(empty,0),'Empty').
arg_type_hints(val('Empty'),'Empty').
arg_type_hints(val('True'),'Bool').
arg_type_hints(val('False'),'Bool').
arg_type_hints(val(Val),[val(Val)|Types]):- get_val_types(Val,Types).
arg_type_hints(arg('println!',0),'UnitAtom').
arg_type_hints(arg(F,Arg),[arg(F,Arg)|Types]):-
   findall(Type,get_farg_type(F,Arg,Type),List),merge_types(List,Types),Types\==[].

get_farg_type(F,Arg,Type):- get_type(F,Res),(Res=[Ar|List],Ar=='->'), (Arg==0->last(List,TypeM);nth1(Arg,List,TypeM)),(nonvar(TypeM)->TypeM=Type;Type='%Var').
get_val_type(Val,Type):- get_type(Val,TypeM),(nonvar(TypeM)->TypeM=Type;Type='%Var%').
get_val_types(Val,Types):- findall(Type,get_val_type(Val,Type),List),merge_types(List,Types).
merge_types(List,Types):- list_to_set(List,Types),!.

get_just_types_of(V,Types):- get_types_of(V,VTypes),exclude(is_functor_val,VTypes,Types).

get_types_of(V,Types):- attvar(V),get_attr(V,cns,_Self=Types),!.
get_types_of(V,Types):- compound(V),V=list(_),!,Types=['Expression'].
get_types_of(V,Types):- compound(V),V=arg(_,_),!,Types=[V].
get_types_of(V,Types):- findall(Type,get_type_for_args(V,Type),Types).

get_type_for_args(V,Type):- get_type(V,Type), Type\==[], Type\=='%Undefined%', Type\=='list'.

set_types_of(V,_Types):- nonvar(V),!.
set_types_of(V,Types):- list_to_set(Types,Set),put_attr(V,cns,_Self=Set),   nop(wdmsg(V=Types)).

precompute_typeinfo(HResult,HeadIs,AsBodyFn,Ast,Result) :-
 must_det_lls((
    HeadIs = [FnName|Args],
    LazyArgsList=[], FinalLazyOnlyRet = lazy,
    f2p(HeadIs,LazyArgsList,HResult,FinalLazyOnlyRet,AsBodyFn,NextBody),
    HeadAST=[assign,HResult,[call(FnName)|Args]],
    Ast = [=,HeadIs,NextBody],
    ast_to_prolog_aux(no_caller,[],HeadAST,_HeadC),
    ast_to_prolog(no_caller,[],NextBody,_NextBodyC),
    extract_constraints(Ast,Result))).

:- use_module(library(gensym)).          % for gensym/2
:- use_module(library(pairs)).           % for group_pair_by_key/2
:- use_module(library(logicmoo_utils)).  % for ppt/1 (pretty-print)

/** <module> combine_transform_and_collect_subterm

    Demonstration of a two-pass approach:
      1) Transform an S-expression so that *nested* calls `[Fn|Args]`
         become `'$VAR'('temp_N')` with an assignment `'temp_N' = eval([Fn|...])`.
         The top-level call is preserved.
      2) Collect underscore variables in the *final expression* by
         enumerating all subterms with sub_term/2. Whenever we see a call
         (either `[Fn|Args]` or a compound `Fn(...)`), we look for underscore
         variables in the arguments and note them as `arg(Fn,Pos)`.

    We then show how to run this on a "big" expression with match-body, if,
    let*, etc., using logicmoo_utils to print results.
*/


/* ---------------------------------------------------------------------
   (1) TRANSFORMATION PASS
   --------------------------------------------------------------------- */

/** transform_expr(+OldExpr, -Assignments, -NewTopExpr) is det

    Leaves the **top-level** `[Fn|Args]` intact,
    but for each *nested* call `[SubFn|SubArgs]`, create a fresh
    variable `'$VAR'('temp_N')` and an assignment `'temp_N' = eval([...])`.
*/
transform_expr(OldExpr, Assignments, NewTopExpr) :-
    % unify real Prolog variables as '$VAR'(N), though underscores remain atoms
    numbervars(OldExpr, 0, _, [attvar(skip)]),
    transform_top(OldExpr, NewTopExpr, Assignments, 0, _).

transform_top(Var, Var, [], C, C) :- fullvar(Var), !.
transform_top(Var, Var, [], C, C) :- data_term(Var), !.
transform_top(Var, Var, [], C, C) :- Var==[], !.
transform_top(Var, Var, [], C, C) :- \+ is_list(Var).
transform_top([Fn|Args], [Fn|NewArgs], Assignments, C0, C2) :- atom(Fn), !, transform_list_subcalls(Args, NewArgs, Assignments, C0, C2).
transform_top(List, ListOut, Assignments, C0, C2) :- is_list(List), !, transform_list_subcalls(List, ListOut, Assignments, C0, C2).
transform_top(Anything, Anything, [], C, C).

transform_list_subcalls([], [], [], C, C).
transform_list_subcalls([X|Xs], [Xn|Xsn], Assignments, C0, C2) :-
    transform_subcall(X, Xn, A1, C0, C1),
    transform_list_subcalls(Xs, Xsn, A2, C1, C2),
    append(A1, A2, Assignments).

/** transform_subcall(+Expr, -ExprOut, -Assignments, +C0, -C1) is det

    For *nested* calls `[Fn|Args]`, produce `'$VAR'(temp_N)` plus assignment.
    Otherwise, just keep recursing.
*/
transform_subcall(Var, Var, [], C, C) :-
    \+ is_list(Var), !.
transform_subcall([], [], [], C, C) :- !.
transform_subcall([Fn|Args], TmpVar, [Assignment|Arest], C0, C2) :- atom(Fn), !,
    transform_list_subcalls(Args, NewArgs, Aargs, C0, C1),
    gensym('_temp_', TempName),
    TmpVar = '$VAR'(TempName),
    Assignment = (TmpVar - eval([Fn|NewArgs])),
    append(Aargs, [], Arest),
    C2 is C1.

transform_subcall(List, ListOut, A, C0, C2) :-
    is_list(List),
    transform_list_subcalls(List, ListOut, A, C0, C2).


/** var_call_refs(+Expression, -VarMappings) is det

    After transformation, we gather references to "underscore variables."
    We do this by enumerating all subterms with sub_term/2, checking for
    calls that are either:
      - `[Fn|Args]` (a Prolog list with an atom head), or
      - A compound with an atom functor.

    For each Arg that starts with `_`, or is a Prolog var,
    we produce `_var - arg(Fn,Pos)`.

    Finally group and produce `_varName = [arg(Fn,Pos1), arg(Fn,Pos2), ...]`.
*/
var_call_refs(Expression, VarMappings) :-
    numbervars(Expression, 0, _, [attvar(skip)]),

    % collect all subterms
    findall(Sub, sub_term_safely(Sub, Expression), SubTerms),

    % for each subterm that is a "function call", gather references
    gather_all_function_calls(SubTerms, RawPairs),

    % group and unify
    sort(RawPairs, Sorted),
    group_pair_by_key(Sorted, Grouped),
    maplist(to_equals_pair, Grouped, VarMappings).

to_equals_pair(K-List, K-List).

%group_pair_by_key(X,Y):- !, group_pairs_by_key(X,Y).
group_pair_by_key([], []):-!.
group_pair_by_key([M-N|T0], Done) :- select(K-Vs,T0,TR), M=@=K,!,
     flatten([N,Vs],Flat),list_to_set(Flat,Set), group_pair_by_key([M-Set|TR], Done).
group_pair_by_key([M-N|T0],[M-Set|Done]):-
  flatten([N],Flat),list_to_set(Flat,Set),
  group_pair_by_key(T0, Done).

/** gather_all_function_calls(+SubTerms, -AllPairs) is det

    For each subterm in SubTerms, if it's recognized as a function call,
    call process_function_args/4 to gather underscore variables in the arguments.
*/
gather_all_function_calls([], []).
gather_all_function_calls([Term|Rest], AllPairs) :-
    (   is_function_call(Term, Fn, Args)
    ->  process_function_args(Fn, Args, 1, Pairs)
    ;   Pairs = []
    ),
    gather_all_function_calls(Rest, More),
    append(Pairs, More, AllPairs).

/** is_function_call(+Term, -Fn, -Args) is semidet

    1. If Term is a list [Fn|Args] with `atom(Fn)`, treat it as a call.
    2. If Term is a compound with `functor = Fn` (an atom) and arguments `Args`,
       also treat it as a call. For example, `eval([quote,F])` => Fn=eval, Args=[[quote,F]].
*/
is_function_call(List, Fn, Args) :-
    is_list(List),
    List = [Fn|Args],
    atom(Fn),!, \+ non_function(Fn).

is_function_call(Compound, Fn, Var) :-
    compound(Compound),
    Compound = (Var - eval([Fn|_])),
    atom(Fn),!, \+ non_function(Fn).


non_function(Fn):- var(Fn),!,fail.
non_function('&self').

process_function_args(Fn, Var, _, [Var-arg(Fn,0)]):- is_underscore_var(Var),!.
process_function_args(_, [], _, []).
process_function_args(Fn, [Arg|R], N, [Arg-arg(Fn,N)|Out]) :-
    is_underscore_var(Arg),
    !,
    N2 is N + 1,
    process_function_args(Fn, R, N2, Out).
process_function_args(Fn, [_|R], N, Out) :-
    N2 is N + 1,
    process_function_args(Fn, R, N2, Out).

/** is_underscore_var(+X) is semidet

    True if X is:
      - a real Prolog variable (var/1 or '$VAR'(_)),
      - or an atom starting with `_`.
*/
is_underscore_var(X) :- var(X), !.
is_underscore_var('$VAR'(_)) :- !.
is_underscore_var(X) :-
    atom(X),
    sub_atom(X, 0, 1, _, '_').



/* ---------------------------------------------------------------------
   (3) PUTTING IT ALL TOGETHER
   --------------------------------------------------------------------- */

combine_transform_and_collect(OldExpr, Assignments, NewExpr, VarMappings) :-
    transform_expr(OldExpr, Assignments, NewExpr),
    % Collect references from both the new expression AND the assignments.
    % That way, if you have  _temp_9 = eval([quote,F]) ...
    % the subterm [quote,F] is recognized.
    var_call_refs(OldExpr+Assignments, VarMappings).


/** test_combine_big is det

    Demo with `=`, `match-body`, `if`, nested `let*`, etc.
    Also picks up any compound calls like eval([quote,_goal]).
*/
test_combine_big :-
    OldExpr =
      [ =,
        [ match_body, _info, _body, _kb, _rb, _goal ],
        [ if,
          [==, _body, []],
          eval([quote,_goal]),          % an example compound call
          [ 'let*',
            [ [ [ _cur, _rest ],
                [ decons_atom, _body ]],
              [ _debugging, 'True' ],
              [ _bugcheck, 'False' ],
              [ [],
                [ if,
                  _debugging,
                  [ println,
                    [ quote,
                      [ "IN",
                        ["cur=", _cur],
                        ["goal=", _goal]]]],
                  []]],
              [ _12,
                [ if,
                  _bugcheck,
                  [ 'let*',
                    [ [ RetVal,
                        [ backward_chain, _info,_cur,_kb,_rb ] ],
                      [ _m,
                        [ collapse, [ equalz, [quote,_cur], _RetVal ] ] ],
                      [ [],
                        [ if,
                          [==,_m,[]],
                          [ println,
                            [ quote,
                              [ "BAD",
                                ["cur=", _cur ],
                                ["retVal=", RetVal]]]],
                          []]]],
                    []],
                  []]],
              [ [ quote, _cur ],
                [ backward_chain, _info,_cur,_kb,_rb ]],
              [ [],
                [ if,
                  _debugging,
                  [ println,
                    [ quote,
                      [ 'OUT',
                        ["cur=", _cur],
                        ["goal=", _goal]]]],
                  []]]],
            [ match_body, _info,_rest,_kb,_rb,_goal]]]],

    combine_transform_and_collect(OldExpr, Assignments, NewExpr, VarMappings),

    writeln("=== Original Expression ==="),
    ppt(OldExpr),

    writeln("=== Assignments (subcalls replaced) ==="),
    ppt(Assignments),

    writeln("=== New Expression ==="),
    ppt(NewExpr),

    writeln("=== Var Mappings (underscore variables) ==="),
    append(Assignments,VarMappings,SM),sort(SM,S),
    ppt(S).

%:- test_combine_big.



in_type_set(Set,Type):- Set==Type,!.
in_type_set(Set,Type):- compound(Set),arg(_,Set,Arg),in_type_set(Arg,Type).

b_put_set(Set,Type):- functor_chkd(Set,_,Arg),!,b_put_nset(Set,Arg,Type).
b_put_nset(Set,_,Type):- in_type_set(Set,Type),!.
b_put_nset(Set,N,Type):- arg(N,Set,Arg),
   (compound(Arg)->b_put_set(Arg,Type);b_setarg(N,Set,[Type|Arg])).

is_type_set(Set):-compound(Set),Set=ts(_).
is_var_set(Set):- compound(Set),Set=vs(_).
foc_var(Cond,vs([Var-Set|LazyVars]),TypeSet):-!,
    (var(Set)->(Cond=Var,TypeSet=Set,TypeSet=ts([]));
   (Var==Cond -> TypeSet = Set ;
   (nonvar(LazyVars) -> foc_var(Cond,vs(LazyVars),TypeSet);
    (TypeSet=ts([]),LazyVars=[Var-TypeSet|_])))).
foc_var(Cond,Set,TSet):-add_type(Set,[Cond-TSet]),ignore(TSet=ts(List)),ignore(List=[]).

add_type(Cond,Type,LazyVars):-is_var_set(LazyVars),!,must_det_lls((foc_var(Cond,LazyVars,TypeSet),!,add_type(TypeSet,Type))).
add_type(Cond,Type,_LazyVars):- add_type(Cond,Type),!.

add_type(Cond,Type):-attvar(Cond),get_attr(Cond,ti,TypeSet),!,must_det_lls(add_type(TypeSet,Type)).
add_type(Cond,Type):-var(Cond),!,must_det_lls(put_attr(Cond,ti,ts(Type))),!.
add_type(Cond,Type):-is_type_set(Cond),!,must_det_lls(b_put_set(Cond,Type)),!.
add_type(Cond,Type):-is_var_set(Cond),!,must_det_lls(b_put_set(Cond,Type)),!.
add_type(Cond,Type):- dmsg(unable_to_add_type(Cond,Type)).

remove_stub(Space,Fn,Arity):- \+ transpiler_stub_created(Space,Fn,Arity),!.
remove_stub(Space,Fn,Arity):- retract(transpiler_stub_created(Space,Fn,Arity)),!,
  transpile_impl_prefix(Fn,Arity,IFn),abolish(IFn/Arity),!.

% !(listing! cdr-atom)
transpiler_predicate_store(builtin, 'listing!', [1], [], '', [x(doeval,eager,[])], x(doeval,eager,[])).
'mc__1_1_listing!'(S,RetVal):-
  find_compiled_refs(S, Refs),
  locally(nb_setval(focal_symbol,S),print_refs(Refs)),!,
  length(Refs,RetVal).

'compiled_info'(S):-
  'mc__1_1_listing!'(S,_RetVal).

print_refs(Refs):- is_list(Refs),!,maplist(print_refs,Refs).
print_refs(Refs):- atomic(Refs),clause(M:H,B,Refs),!,print_itree(((M:H):-B)).
print_refs(Refs):- print_itree(Refs).
print_itree(C):- \+ compound(C),!,nl_print_tree(C).
print_itree((H:-B)):- B==true,!,print_itree((H)).
print_itree((M:H)):- M==user,!,print_itree((H)).
print_itree(((M:H):-B)):- M==user,!,print_itree((H:-B)).
print_itree(T):- \+ \+ nl_print_tree(T).

nl_print_tree(PT):-
  stream_property(Err, file_no(2)),
  mesg_color(PT, Color),
  numbervars(PT,55,_,[attvar(skip),singletons(true)]),
  maybe_subcolor(PT,CPT),

  with_output_to(Err,(format('~N'),ansicall(Color,ppt(CPT)),format('~N'))).

maybe_subcolor(PT,CPT):- fail, nb_current(focal_symbol,S), mesg_color(PT, Color), wots(Str,ansicall(Color,ppt1(S))),
   subst001(PT,S,Str,CPT),!.
maybe_subcolor(PT,PT).

find_compiled_refs(S, Refs):-
   atom_concat('_',S,Dashed),
   compiled_info_s(S,Refs1),
   findall(Refs,(current_atom(F),atom_concat(_,Dashed,F),compiled_info_f(F,Refs)),Refs2),
   append_sets([Refs1,Refs2],Refs).

append_sets(RefsL,Refs):- flatten(RefsL,Flat),list_to_set(Flat,Refs).
compiled_info_s(S,Refs):-
   findall(Ref,(compiler_data(F/A),compiled_refs(S,F,A,Ref)),RefsL),append_sets(RefsL,Refs1),
   findall(Ref,(current_predicate(S/A),functor_chkd(P,S,A),clause(P,_,Ref)),Refs2),append_sets([Refs1,Refs2],Refs).
compiled_info_f(F,Refs):- compiled_info_s(F,Refs1), compiled_info_p(F,Refs2),append_sets([Refs1,Refs2],Refs).
compiled_info_p(F,Refs):-
   findall(Ref,(current_predicate(F/A),functor_chkd(P,F,A),current_module(M),
    \+ \+ predicate_property(M:P,_), \+ predicate_property(M:P,imported_from(_)),
    clause(M:P,_,Ref)),Refs).

compiled_refs(Symbol,F,A,Info):-
 functor_chkd(P,F,A),clause(P,B,Ref), (\+ compiler_data_no_call(F/A) -> call(B)), symbol_in(2,Symbol,P),
   (B==true->Info=Ref;Info=P).


symbol_in(_, Symbol, P):-Symbol=@=P,!.
symbol_in(N, Symbol, P):- N>0, compound(P), N2 is N-1, symbol_in_sub(N2, Symbol, P).
symbol_in_sub(N, Symbol, P):- is_list(P),P=[S1,S2,_|_],!,symbol_in_sub(N, Symbol, [S1,S2]).
symbol_in_sub(N, Symbol, P):- is_list(P),!,member(S,P),symbol_in(N, Symbol, S).
symbol_in_sub(N, Symbol, P):- arg(_,P,S),symbol_in(N, Symbol, S).


compiler_data_mf(metta_compiled_predicate/3).
compiler_data_mf(is_transpile_call_prefix/3).
compiler_data_mf(is_transpile_impl_prefix/3).
compiler_data_mf(transpiler_stub_created/3).
compiler_data_mf(transpiler_depends_on/4).
compiler_data_mf(transpiler_clause_store/9).
compiler_data_mf(transpiler_predicate_nary_store/9).
compiler_data_mf(transpiler_predicate_store/7).
compiler_data_mf(metta_function_asserted/3).
compiler_data_mf(metta_other_asserted/2).
compiler_data_mf(transpiler_stored_eval/3).

compiler_data(F/A):- compiler_data_mf(F/A).
compiler_data(metta_atom/2).
compiler_data(metta_type/3).
compiler_data(metta_defn/3).
compiler_data(eval_20/6).
compiler_data_no_call(eval_20/6).

%compiler_data(metta_atom_asserted/2).

%compiler_data(metta_file_buffer/7).

ensure_callee_site(Space,Fn,Arity):- check_supporting_predicates(Space,Fn/Arity),!.
ensure_callee_site(Space,Fn,Arity):-transpiler_stub_created(Space,Fn,Arity),!.
ensure_callee_site(Space,Fn,Arity):-
 must_det_lls((
    compiler_assertz(transpiler_stub_created(Space,Fn,Arity)),
    transpile_call_prefix(Fn,Arity,CFn),

 ((current_predicate(CFn/Arity) -> true ;
  must_det_lls((( functor_chkd(CallP,CFn,Arity),
    CallP @.. [CFn|Args],
    transpile_impl_prefix(Fn,Arity,IFn),
    CallI @.. [IFn|Args],
    %dynamic(IFn/Arity),
    append(InArgs,[OutArg],Args),
    Clause= (CallP:-((pred_uses_impl(Fn,Arity),CallI)*->true;(mc_fallback_unimpl(Fn,Arity,InArgs,OutArg)))),
    compiler_assertz(Clause),
    %output_prolog(Clause),
    %create_and_consult_temp_file(Space,CFn/Arity,[Clause])
    true))))))),!.

%transpile_prefix('').
transpile_impl_prefix('mi__1_').
:- dynamic(is_transpile_impl_prefix/3).
transpile_impl_prefix(F,Arity,Fn):- is_transpile_impl_prefix(F,Arity,Fn)*->true;(transpile_impl_prefix(Prefix),FNArity is Arity-1,atomic_list_concat([Prefix,FNArity,'__',F],Fn),asserta(is_transpile_impl_prefix(F,Arity,Fn))).

transpile_call_prefix('mc__1_').
:- dynamic(is_transpile_call_prefix/3).
transpile_call_prefix(F,Arity,Fn):- is_transpile_call_prefix(F,Arity,Fn)*->true;(transpile_call_prefix(Prefix),FNArity is Arity-1,atomic_list_concat([Prefix,FNArity,'__',F],Fn),asserta(is_transpile_call_prefix(F,Arity,Fn))).


prefix_impl_preds(Prefix,F,A):- prefix_impl_preds_pp(Prefix,F,A).
prefix_impl_preds('mc__1_',F,A):- is_transpile_call_prefix(F,A,Fn),current_predicate(Fn/A), \+ prefix_impl_preds_pp(_,F,A).
prefix_impl_preds('mi__1_',F,A):- is_transpile_impl_prefix(F,A,Fn),current_predicate(Fn/A), \+ prefix_impl_preds_pp(_,F,A).

prefix_impl_preds_pp(Prefix,F,A):- predicate_property('mc__1_2_:'(_,_,_),file(File)),predicate_property(Preds,file(File)),functor_chkd(Preds,Fn,A),
    ((transpile_impl_prefix(Prefix);transpile_call_prefix(Prefix)),atom_list_concat([Prefix,_FNArity,'_',F],Fn)).

maplist_and_conj(_,A,B):- fullvar(A),!,B=A.
maplist_and_conj(_,A,B):- \+ compound(A),!,B=A.
maplist_and_conj(P2,(A,AA),[B|BB]):- !, maplist_and_conj(P2,A,B), maplist_and_conj(P2,AA,BB).
maplist_and_conj(P2,[A|AA],[B|BB]):- !, call(P2,A,B), maplist_and_conj(P2,AA,BB).
maplist_and_conj(P2,A,B):- call(P2,A,B), !.

notice_callee(Caller,Callee):-
   ignore((
     extract_caller(Caller,CallerInt,CallerSz),
     extract_caller(Callee,F,LenArgs),!,
     notice_callee(CallerInt,CallerSz,F,LenArgs))).

notice_callee(CallerInt,CallerSz,F,LenArgs1):-
    ignore((
        CallerInt \== no_caller,
        F \== exec0,
        CallerInt  \== exec0,
        \+ (transpiler_depends_on(CallerInt,CallerSzU,F,LenArgs1U), CallerSzU=@=CallerSz, LenArgs1U=@=LenArgs1),
         compiler_assertz(transpiler_depends_on(CallerInt,CallerSz,F,LenArgs1)),
         transpiler_debug(2,format_e("; Asserting: transpiler_depends_on(~q,~q,~q,~q)\n",[CallerInt,CallerSz,F,LenArgs1])),
         ignore((current_self(Space),ensure_callee_site(Space,CallerInt,CallerSz))),
         transpiler_debug(2,output_prolog(transpiler_depends_on(CallerInt,CallerSz,F,LenArgs1)) ))),
    ignore((
         current_self(Space),ensure_callee_site(Space,F,LenArgs1))).

extract_caller(Var,_,_):- fullvar(Var),!,fail.
extract_caller([H|Args],F,CallerSz):- !, extract_caller(fn_eval(H,Args,_),F,CallerSz).
extract_caller(fn_impl(F,Args,_),F,CallerSz):- !, extract_caller(fn_eval(F,Args,_),F,CallerSz).
extract_caller(fn_eval(F,Args,_),F,CallerSz):- is_list(Args), !, length(Args,CallerSz).
extract_caller(fn_eval(F,Args,_),F,CallerSz):- !, \+ is_list(Args), !, CallerSz= _.
extract_caller(fn_native(F,Args),F,CallerSz):- !, length(Args,CallerSz).
extract_caller(caller(CallerInt,CallerSz),CallerInt,CallerSz):-!.
extract_caller((CallerInt/CallerSz),CallerInt,CallerSz):-!.
extract_caller(H:-_,CallerInt,CallerSz):- !, extract_caller(H,CallerInt,CallerSz).
extract_caller([=,H,_],CallerInt,CallerSz):-  !, extract_caller(H,CallerInt,CallerSz).
extract_caller(P,F,A):- \+ callable(P),!, F=P,A=0.
extract_caller(P,F,A):- \+ is_list(P), functor_chkd(P,F,A).


maybe_lazy_list(_,_,_,[],[]):-!.
maybe_lazy_list(Caller,F,N,[Arg|Args],[ArgO|ArgsO]):- maybe_argo(Caller,F,N,Arg,ArgO),
  N2 is N +1,
  maybe_lazy_list(Caller,F,N2,Args,ArgsO).

maybe_argo(_Caller,_F,_N,Arg,Arg):- is_list(Arg),!.
maybe_argo(_Caller,_F,_N,Arg,Arg):- \+ compound(Arg),!.
maybe_argo(Caller,_F,_N,Arg,ArgO):- ast_to_prolog_aux(Caller,[],Arg,ArgO).

:- dynamic(maybe_optimize_prolog_term/4).
:- dynamic(maybe_optimize_prolog_assertion/4).

try_optimize_prolog(Y,Convert,Optimized):-  fail,
   once(catch_warn(maybe_optimize_prolog_assertion(Y,[],Convert,OptimizedM))),Convert\=@=OptimizedM,!,
   try_optimize_prolog(Y, OptimizedM,Optimized).
try_optimize_prolog(_,Optimized,Optimized).


try_harder_optimize_prolog(Y,Convert,Optimized):-  fail,
   once(catch_warn(maybe_optimize_prolog_assertion(Y,[],Convert,OptimizedM))),Convert\=@=OptimizedM,!,
   try_harder_optimize_prolog(OptimizedM,Optimized).
try_harder_optimize_prolog(_,Optimized,Optimized).

/*
try_optimize_prolog(Y,Convert,Optimized):-
   catch_warn(maybe_optimize_prolog_assertion(Y,[],Convert,MaybeOptimized)),
   actual_change(Convert,MaybeOptimized),!,
   try_optimize_prolog(Y,MaybeOptimized,Optimized).
*/

optimize_prolog_term(_,_,Converted,Optimized):- \+ compound(Converted),!,Converted=Optimized.
optimize_prolog_term(Y,FL,Converted,Optimized):-
   copy_term(Converted,ConvertedC),
   maybe_optimize_prolog_term(Y,FL,Converted,Optimized),
   \+ ((ConvertedC\=@=ConvertedC,
       (debug_info(double_sided_unification,t(ConvertedC\=@=ConvertedC)))),ignore((trace,throw(double_sided_unification)))),!.
optimize_prolog_term(Y,FL,Converted,Optimized):- is_list(Converted),
   maplist(optimize_prolog_term(Y,[list()|FL]),Converted,Optimized),!.
optimize_prolog_term(Y,FL,Converted,Optimized):-
   compound_name_arguments(Converted,F,Args),
   maplist(optimize_prolog_term(Y,[F|FL]),Args,OArgs),
   compound_name_arguments(Optimized,F,OArgs), !.
optimize_prolog_term(_,_,Prolog,Prolog).


actual_change(Body,BodyNew):- copy_term(Body+BodyNew,BodyC+BodyNewC,_), BodyC\=@=BodyNewC.

maybe_optimize_prolog_assertion(Y,Stack,Cmpd,(:-BodyNew)):-  compound(Cmpd),(:-Body)=Cmpd,compound(Body),!,
  maybe_optimize_prolog_assertion(Y,Stack,(cl:-Body),(cl:-BodyNew)).

maybe_optimize_prolog_assertion(_,_,CmpdIn,(Cl:-BodyNew)):-
  compound(CmpdIn),subst_vars(CmpdIn,Cmpd),
  (Cl:-Body)=Cmpd,compound(Body),%copy_term(Body,BodyC),
  must_optimize_whole_body(Cl,Body,BodyNew).

must_optimize_whole_body(Head, Body, BodyNew) :-  %fail,
    term_variables(Body, Vars),
    member(Var,Vars),
    % Count variable usage across full term (Includes Head)
    var_count_in_term(Head+Body,Var,Count),
    %copy_term(Body,BodyC),
    inline_var_maybe(Var, Count, Body, BodyNew), Body \=@= BodyNew, !.

must_optimize_whole_body(_Cl, Body, BodyNew) :- fail,
   sub_term_safely(Sub, Body), compound(Sub), Sub = (L = R),
   L==R, subst001(Body, Sub , true, BodyNew), !.

must_optimize_whole_body(Cl, Body, BodyNew) :- % fail,
     optimize_body(Cl, Body, BodyNew).


label_body_singles(Head,Body):-
   term_singletons(Body+Head,BodyS),
   maplist(label_body_singles_2(Head),BodyS).
label_body_singles_2(Head,Var):- sub_var_safely(Var,Head),!.
label_body_singles_2(_,Var):- ignore(Var='$VAR'('_')).


optimize_body(HB,Body,BodyNew):-
   %prolog_current_frame(Frame), prolog_frame_attribute(Frame, level, Depth),
   %writeln(user_error,Depth=optimize_body(HB,Body,BodyNew)),
   %if_t(Depth>186,trace),
   optimize_body_step(HB,Body,BodyNew),!.
optimize_body(_,Body,Body).

optimize_body_step(_HB,Body,BodyNew):- is_ftVar(Body),!,Body=BodyNew.
optimize_body_step(_HB,Body,BodyNew):- \+ compound(Body),!,Body=BodyNew.
%optimize_body( HB,eval_args(VT,R),eval_args(VT,R)):-!, optimize_body(HB,VT,VTT).
optimize_body_step( HB,with_space(V,T),with_space(V,TT)):-!, optimize_body(HB,T,TT).
optimize_body_step( HB,limit(V,T),limit(V,TT)):-!, optimize_body(HB,T,TT).
optimize_body_step( HB,findall(V,T,R),findall(V,TT,R)):-!, optimize_body(HB,T,TT).
optimize_body_step( HB,loonit_assert_source_tf(V,T,R3,R4), loonit_assert_source_tf(V,TT,R3,R4)):-!,
  optimize_body(HB,T,TT).

optimize_body_step( HB,(B1*->B2;B3),(BN1*->BN2;BN3)):-!, optimize_body(HB,B1,BN1), optimize_body(HB,B2,BN2), optimize_body(HB,B3,BN3).
optimize_body_step( HB,(B1->B2;B3),(BN1->BN2;BN3)):-!, optimize_body(HB,B1,BN1), optimize_body(HB,B2,BN2), optimize_body(HB,B3,BN3).
optimize_body_step( HB,(B1:-B2),(BN1:-BN2)):-!, optimize_body(HB,B1,BN1), optimize_body(HB,B2,BN2).
optimize_body_step( HB,(B1*->B2),(BN1*->BN2)):-!, optimize_body(HB,B1,BN1), optimize_body(HB,B2,BN2).
optimize_body_step( HB,(B1->B2),(BN1*->BN2)):-!, optimize_body(HB,B1,BN1), optimize_body(HB,B2,BN2).
optimize_body_step( HB,(B1;B2),(BN1;BN2)):-!, optimize_body(HB,B1,BN1), optimize_body(HB,B2,BN2).


optimize_body_step(Head,(B0,B1,B2),(B0,BN1)):- did_optimize_conj(Head,B1,B2,BN1).
optimize_body_step(Head,(B1,B2,B3),(BN1,B3)):- did_optimize_conj(Head,B1,B2,BN1).
optimize_body_step(Head,(B1,B2),(BN1)):- did_optimize_conj(Head,B1,B2,BN1).
optimize_body_step(Head,(B1,B2),(BN1,BN2)):-!, optimize_body(Head,B1,BN1), optimize_body(Head,B2,BN2).

% TODO FIXME optimize_body( HB,(B1,B2),(BN1)):- optimize_conjuncts(HB,(B1,B2),BN1).
%optimize_body_step(_HB,==(Var, C), Var=C):- self_eval(C),!.
%optimize_body_step( HB,x_assign(A,B),R):- optimize_x_assign_1(HB,A,B,R),!.
%optimize_body_step(_HB,x_assign(A,B),x_assign(AA,B)):- p2s(A,AA),!.
optimize_body_step(_HB,Body,BodyNew):- Body=BodyNew.



/*
optimize_body(_Head,Body,BodyNew):- var(Body),!,Body=BodyNew.
optimize_body(Head,(B1*->B2;B3),(BN1*->BN2;BN3)):-!, optimize_body(Head,B1,BN1), optimize_body(Head,B2,BN2), optimize_body(Head,B3,BN3).
optimize_body(Head,(B1->B2;B3),(BN1->BN2;BN3)):-!, optimize_body(Head,B1,BN1), optimize_body(Head,B2,BN2), optimize_body(Head,B3,BN3).
optimize_body(Head,(B1,B2),(BN1)):- B2==true,!, optimize_body(Head,B1,BN1).
optimize_body(Head,(B2,B1),(BN1)):- B2==true,!, optimize_body(Head,B1,BN1).
optimize_body(Head,(B1,B2),(BN1,BN2)):-!, optimize_body(Head,B1,BN1), optimize_body(Head,B2,BN2).
optimize_body(Head,(B1:-B2),(BN1:-BN2)):-!, optimize_body(Head,B1,BN1), optimize_body(Head,B2,BN2).
optimize_body(Head,(B1;B2),(BN1;BN2)):-!, optimize_body(Head,B1,BN1), optimize_body(Head,B2,BN2).
optimize_body(_Head,Body,BodyNew):- Body=BodyNew.
*/


var_count_in_term(Term, Var, Count) :-
    term_occurrences(Var, Term, Count).

term_occurrences(Var, Term, Count) :-
    ( Term == Var -> Count = 1
    ; compound(Term) ->
        Term =.. [_|Args],
        maplist(term_occurrences(Var), Args, Counts),
        sum_list(Counts, Count)
    ; Count = 0 ).

var_in_pair(Var,Sub,(Left = Right)):-
     (Sub = (P1, P2, _) ; Sub = (P1, P2)),
     P2 = (Left = Right), Var == Right,
    sub_var_safely(Var, P1),!.

var_in_pair(Var,Sub,(Left = Right)):-
     (Sub = (P1, P2, _) ; Sub = (P1, P2)),
     P1 = (Left = Right), Var == Left,
    sub_var_safely(Var, P2),!.

% Inline variables with exactly two uses
inline_var_maybe(Var, 2, Body, BodyNew) :-
    sub_term_safely(Sub, Body), compound(Sub),
    var_in_pair(Var,Sub, FoundEquality),
    inline_var(Var, 2, FoundEquality, Body, BodyNew), !.

inline_var_maybe(Var, 2, Body, BodyNew) :- fail,
    sub_term_safely(Sub, Body), compound(Sub), Sub = (Left = Right),
     (Var == Left ;  Var ==Right),
    inline_var(Var, 2, (Left = Right), Body, BodyNew), !.

%inline_var_maybe(_,_,Body,Body).

inline_var(Var, 2, (Left = Right), Body, BodyNew):- Var == Left , Var \== Right, !,
  %Right=Var,
  subst001(Body, (Left = Right), true, BodyM),
  subst001(BodyM, Var , Right, BodyNew), !.

inline_var(Var, 2, (Right = Left), Body, BodyNew):- Var == Left , Var \== Right, !,
  %Right=Var,
  subst001(Body, (Right = Left), true, BodyM),
  subst001(BodyM, Var , Right, BodyNew), !.


de_eval(eval(X),X):- compound(X),!.

call1(G):- call(G).
call2(G):- call(G).
call3(G):- call(G).
call4(G):- call(G).
call5(G):- call(G).

trace_break:- trace_break((trace,break)).
trace_break(G):-
   stream_property(Err, file_no(2)),
   current_output(Cur), Cur\=@=Err,!,
   with_output_to(Err, trace_break(G)).
trace_break(G):- nl, writeq(call(G)), trace,break.
%    :- set_prolog_flag(gc,false).

:- if(debugging(metta(compiler_bugs))).
    :- set_prolog_flag(gc,false).
:- endif.

call_fr(G,Result,FA):- current_predicate(FA),!,call(G,Result).
call_fr(G,Result,_):- Result=G.

transpile_eval([Fn|Args],Res):- use_evaluator(fa(Fn,_), compiler, disabled),!, eval_in_only(interp,[Fn|Args],Res).
transpile_eval(Convert,Res) :- nb_current('eval_in_only', interp),!, eval(Convert,Res).
transpile_eval(Convert,Converted) :-
  transpile_eval(Convert,Converted,PrologCode),!,
  eval_in_only(compiler,call(PrologCode)).

transpile_eval(Convert0,LiConverted,PrologCode) :-
   %leash(-all),trace,
   subst_varnames(Convert0,Convert),
   %(transpiler_stored_eval_lookup(Convert,PrologCode0,Converted0) ->
   %   PrologCode=PrologCode0,
   %   LiConverted=Converted0
   %;
      metta_to_metta_body_macro_recurse('transpile_eval',Convert,ConvertMacr),
      f2p(null,[],Converted,_,LE,ConvertMacr,Code1,_),
      lazy_impedance_match(LE,x(doeval,eager,_),Converted,Code1,Converted,Code1,LiConverted,Code),
      ast_to_prolog(no_caller,[],Code,PreOptimized),
      try_optimize_prolog(transpile_eval,PreOptimized,PrologCode),
      compiler_assertz(transpiler_stored_eval(Convert,PrologCode,LiConverted))
   %)
   .

transpile_eval_nocache(Convert,Converted,true) :- nb_current('eval_in_only', interp),!, eval(Convert,Converted).
transpile_eval_nocache(Convert0,LiConverted,PrologCode) :-
   %leash(-all),trace,
   subst_varnames(Convert0,Convert),
   f2p(null,[],Converted,_,LE,Convert,Code1,_),
   lazy_impedance_match(LE,x(doeval,eager,_),Converted,Code1,Converted,Code1,LiConverted,Code),
   ast_to_prolog(no_caller,[],Code,PreOptimized),
   try_optimize_prolog(transpile_eval,PreOptimized,PrologCode),
   compiler_assertz(transpiler_stored_eval(Convert,PrologCode,LiConverted)).

arg_properties_widen(L,L,L) :- !.
arg_properties_widen(x(_,eager,T),x(_,eager,_),x(doeval,eager,T)).
arg_properties_widen(_,_,x(noeval,lazy,[])).


no_conflict_numbervars(Term):-
    findall(N,(sub_term_safely(E,Term),compound(E), '$VAR'(N)=E, integer(N)),NL),!,
    max_list([-1|NL],Max),Start is Max + 1,!,
    numbervars(Term,Start,_,[attvar(skip),singletons(true)]).

% --------------------------------
%    FUNCTS_TO_PREDS EXPLANATION
% --------------------------------

% functs_to_preds is a predicate that converts all Term functions to their equivalent predicates.
% It takes three arguments - RetResult, which will hold the result of the function evaluation,
% Convert, which is the function that needs to be converted, and Converted, which will hold the equivalent predicate.
% Example:
%
%     ?- functs_to_preds(RetResult, is(pi+pi), Converted).
%
%     Converted =  (pi(_A),
%                   +(_A, _A, _B),
%                   _C is _B,
%                   eval_args(_C, RetResult)).
%
functs_to_preds(I,OO):-
   must_det_lls(functs_to_preds0(I,OO)),!.

functs_to_preds0([Eq,H,B],OO):- Eq == '=', !, % added cut to force compile_for_assert/3
   must_det_lls(compile_for_assert(H, B, OO)),!.
functs_to_preds0(EqHB,OO):- compile_head_for_assert(EqHB,OO),!.

functs_to_preds0(I,OO):-
   sexpr_s2p(I, M),
   f2p([],[],_,_Evaluated,M,O),
   expand_to_hb(O,H,B),
   head_preconds_into_body(H,B,HH,BB),!,
   OO = ':-'(HH,BB).

optimize_head_and_body(Head,Body,HeadNewest,BodyNewest):-
   label_body_singles(Head,Body),
   color_g_mesg('#404064',print_pl_source(( Head :- Body))),
   (merge_and_optimize_head_and_body(Head,Body,HeadNew,BodyNew),
      % iterate to a fixed point
      (((Head,Body)=@=(HeadNew,BodyNew))
      ->  (HeadNew=HeadNewest,BodyNew=BodyNewest)
      ;  optimize_head_and_body(HeadNew,BodyNew,HeadNewest,BodyNewest))).

merge_and_optimize_head_and_body(Head,Converted,HeadO,Body):- nonvar(Head),
   Head = (PreHead,True),!,
   merge_and_optimize_head_and_body(PreHead,(True,Converted),HeadO,Body).
merge_and_optimize_head_and_body(AHead,Body,Head,BodyNew):-
   assertable_head(AHead,Head),
   optimize_body(Head,Body,BodyNew).



optimize_x_assign_1(_,Var,_,_):- is_ftVar(Var),!,fail.
optimize_x_assign_1(HB,Compound,R,Code):- \+ compound(Compound),!, optimize_x_assign(HB,Compound,R,Code).
optimize_x_assign_1(HB,[H|T],R,Code):- !, optimize_x_assign(HB,[H|T],R,Code).
optimize_x_assign_1(HB,Compound,R,Code):- p2s(Compound,MeTTa),   optimize_x_assign(HB,MeTTa,R,Code).
%optimize_x_assign_1(_,[Pred| ArgsL], R, x_assign([Pred| ArgsL],R)).

optimize_x_assign(_,[Var|_],_,_):- is_ftVar(Var),!,fail.
optimize_x_assign(_,[Empty], _, (!,fail)):-  Empty == empty,!.
optimize_x_assign(_,[+, A, B], C, plus(A , B, C)):- number_wang(A,B,C), !.
optimize_x_assign(_,[-, A, B], C, plus(B , C, A)):- number_wang(A,B,C), !.
%optimize_x_assign(_,[+, A, B], C, +(A , B, C)):- !.
%optimize_x_assign(_,[-, A, B], C, +(B , C, A)):- !.
optimize_x_assign(_,[*, A, B], C, *(A , B, C)):- number_wang(A,B,C), !.
optimize_x_assign(_,['/', A, B], C, *(B , C, A)):- number_wang(A,B,C), !.
%optimize_x_assign(_,[*, A, B], C, *(A , B, C)):- !.
%optimize_x_assign(_,['/', A, B], C, *(B , C, A)):- !.
%optimize_x_assign(_,[fib, B], C, fib(B, C)):- !.
%optimize_x_assign(_,[fib1, A,B,C,D], R, fib1(A, B, C, D, R)):- !.
optimize_x_assign(_,['pragma!',N,V],Empty,set_option_value_interp(N,V)):-
   nonvar(N),ignore((fail,Empty='Empty')), !.
optimize_x_assign((H:-_),Filter,A,filter_head_arg(A,Filter)):- fail, compound(H), arg(_,H,HV),
  HV==A, is_list(Filter),!.
%optimize_x_assign(_,[+, A, B], C, '#='(C , A + B)):- number_wang(A,B,C), !.
%optimize_x_assign(_,[-, A, B], C, '#='(C , A - B)):- number_wang(A,B,C), !.
optimize_x_assign(_,[match,KB,Query,Template], R, Code):-  match(KB,Query,Template,R) = Code.

optimize_x_assign(HB,MeTTaEvalP, R, Code):- \+ is_ftVar(MeTTaEvalP),
  compound_non_cons(MeTTaEvalP), p2s(MeTTaEvalP,MeTTa),
  MeTTa\=@=MeTTaEvalP,!, optimize_body(HB, x_assign(MeTTa, R), Code).

% optimize_x_assign(_,_,_,_):- !,fail.
optimize_x_assign((H:-_),[Pred| ArgsL], R, Code):- var(R), atom(Pred), ok_to_append(Pred),
  append([Pred| ArgsL],[R], PrednArgs),Code @.. PrednArgs,
  (H @.. [Pred|_] -> nop(set_option_value('tabling',true)) ; current_predicate(_,Code)),!.

number_wang(A,B,C):-
  (numeric(C);numeric(A);numeric(B)),!,
  maplist(numeric_or_var,[A,B,C]),
  maplist(decl_numeric,[A,B,C]),!.


data_term(Convert):- fullvar(Convert),!,fail.
data_term('&self').
data_term(Convert):- self_eval(Convert),!.

into_equals(RetResultL,RetResult,Equals):- into_x_assign(RetResultL,RetResult,Equals).

into_x_assign(RetResultL,RetResult,true):- is_ftVar(RetResultL), is_ftVar(RetResult), RetResult=RetResultL,!.
into_x_assign(RetResultL,RetResult,Code):- var(RetResultL), Code = x_assign(RetResult,RetResultL).
into_x_assign(RetResultL,RetResult,Code):- Code = x_assign(RetResultL,RetResult).

numeric(N):- number(N),!.
numeric(N):- get_attr(N,'Number','Number').
numeric(N):- get_decl_type(N,DT),(DT=='Int',DT=='Number').

decl_numeric(N):- numeric(N),!.
decl_numeric(N):- ignore((var(N),put_attr(N,'Number','Number'))).

numeric_or_var(N):- var(N),!.
numeric_or_var(N):- numeric(N),!.
numeric_or_var(N):- \+ compound(N),!,fail.
numeric_or_var('$VAR'(_)).

get_decl_type(N,DT):- attvar(N),get_atts(N,AV),sub_term_safely(DT,AV),atom(DT).

fullvar(V) :- var(V), !.
fullvar('$VAR'(_)).

/*
ensure_callee_site(Space,Fn,Arity):-transpiler_stub_created(Space,Fn,Arity),!.
ensure_callee_site(Space,Fn,Arity):-
 must_det_lls((
    compiler_assertz(transpiler_stub_created(Space,Fn,Arity)),
    transpile_call_prefix(Fn,CFn),
    %trace,
((current_predicate(CFn/Arity) -> true ;
  must_det_lls((( functor_chkd(CallP,CFn,Arity),
    CallP @.. [CFn|Args],
    transpile_impl_prefix(Fn,IFn),
    CallI @.. [IFn|Args],
    %dynamic(IFn/Arity),
    append(InArgs,[OutArg],Args),
    Clause= (CallP:-((pred_uses_impl(Fn,Arity),CallI)*->true;(mc_fallback_unimpl(Fn,Arity,InArgs,OutArg)))),
    output_prolog(Clause),
    create_and_consult_temp_file(Space,CFn/Arity,[Clause])))))))),!.

prefix_impl_preds(Prefix,F,A):- prefix_impl_preds_pp(Prefix,F,A).
prefix_impl_preds('mc__',F,A):- is_transpile_call_prefix(F,Fn),current_predicate(Fn/A), \+ prefix_impl_preds_pp(_,F,A).
prefix_impl_preds('mi__',F,A):- is_transpile_impl_prefix(F,Fn),current_predicate(Fn/A), \+ prefix_impl_preds_pp(_,F,A).

prefix_impl_preds_pp(Prefix,F,A):- predicate_property('mc__:'(_,_,_),file(File)),predicate_property(Preds,file(File)),functor_chkd(Preds,Fn,A),
    ((transpile_impl_prefix(Prefix);transpile_call_prefix(Prefix)),atom_concat(Prefix,F,Fn)).

maplist_and_conj(_,A,B):- fullvar(A),!,B=A.
maplist_and_conj(_,A,B):- \+ compound(A),!,B=A.
maplist_and_conj(P2,(A,AA),[B|BB]):- !, maplist_and_conj(P2,A,B), maplist_and_conj(P2,AA,BB).
maplist_and_conj(P2,[A|AA],[B|BB]):- !, call(P2,A,B), maplist_and_conj(P2,AA,BB).
maplist_and_conj(P2,A,B):- call(P2,A,B), !.

notice_callee(Caller,Callee):-
   ignore((
     extract_caller(Caller,CallerInt,CallerSz),
     extract_caller(Callee,F,LenArgs1),!,
     notice_callee(CallerInt,CallerSz,F,LenArgs1))).

notice_callee(CallerInt,CallerSz,F,LenArgs1):-
    ignore((
        CallerInt \== no_caller,
        F \== exec0,
        CallerInt  \== exec0,
        \+ (transpiler_depends_on(CallerInt,CallerSzU,F,LenArgs1U), CallerSzU=@=CallerSz, LenArgs1U=@=LenArgs1),
         compiler_assertz(transpiler_depends_on(CallerInt,CallerSz,F,LenArgs1)),
         transpiler_debug(2,format_e("; Asserting: transpiler_depends_on(~q,~q,~q,~q)\n",[CallerInt,CallerSz,F,LenArgs1])),
         ignore((current_self(Space),ensure_callee_site(Space,CallerInt,CallerSz))),
         transpiler_debug(2,output_prolog(transpiler_depends_on(CallerInt,CallerSz,F,LenArgs1)) ))),
    ignore((
         current_self(Space),ensure_callee_site(Space,F,LenArgs1))).

extract_caller(Var,_,_):- fullvar(Var),!,fail.
extract_caller([H|Args],F,CallerSz):- !, extract_caller(fn_eval(H,Args,_),F,CallerSz).
extract_caller(fn_impl(F,Args,_),F,CallerSz):- !, extract_caller(fn_eval(F,Args,_),F,CallerSz).
extract_caller(fn_eval(F,Args,_),F,CallerSz):- is_list(Args), !, length(Args,Caller).
extract_caller(fn_eval(F,Args,_),F,CallerSz):- !, \+ is_list(Args), !, CallerSz= _.
extract_caller(fn_native(F,Args),F,CallerSz):- !, length(Args,CallerSz).
extract_caller(caller(CallerInt,CallerSz),CallerInt,CallerSz):-!.
extract_caller((CallerInt/CallerSz),CallerInt,CallerSz):-!.
extract_caller(H:-_,CallerInt,CallerSz):- !, extract_caller(H,CallerInt,CallerSz).
extract_caller([=,H,_],CallerInt,CallerSz):-  !, extract_caller(H,CallerInt,CallerSz).
extract_caller(P,F,A):- \+ callable(P),!, F=P,A=0.
extract_caller(P,F,A):- \+ is_list(P), functor_chkd(P,F,A).


maybe_lazy_list(_,_,_,[],[]):-!.
maybe_lazy_list(Caller,F,N,[Arg|Args],[ArgO|ArgsO]):- maybe_argo(Caller,F,N,Arg,ArgO),
  N2 is N +1,
  maybe_lazy_list(Caller,F,N2,Args,ArgsO).

maybe_argo(_Caller,_F,_N,Arg,Arg):- is_list(Arg),!.
maybe_argo(_Caller,_F,_N,Arg,Arg):- \+ compound(Arg),!.
maybe_argo(Caller,_F,_N,Arg,ArgO):- ast_to_prolog_aux(Caller,Arg,ArgO).
*/

check_supporting_predicates(Space,F/A) :- % already exists
%trace,
   create_prefixed_name('mc_',A,F,Fp),
   with_mutex_maybe(transpiler_mutex_lock,
      (sum_list(A,ATot),ATot1 is ATot+1,
         (current_predicate(Fp/ATot1) -> true ;
            findall(Atom0, (between(1, ATot1, I0) ,Atom0='$VAR'(I0)), AtomList0),
            H @.. [Fp|AtomList0],
            findall(Atom1, (between(1, ATot, I1), Atom1='$VAR'(I1)), AtomList1),
            B=..[u_assign,[F|AtomList1],'$VAR'(ATot1)],
   %         (transpiler_enable_interpreter_calls -> G=true;G=fail),
   %         compiler_assertz(transpiler_stub_created(F,A)),
   %         create_and_consult_temp_file(Space,Fp/ATot1,[H:-(format_e("; % ######### warning: using stub for:~q\n",[F]),G,B)]))).
   %         compiler_assertz(transpiler_stub_created(F,A)),

   %         transpiler_debug(2,format_e("; % ######### warning: creating stub for:~q\n",[F])),
            (transpiler_enable_interpreter_calls ->
               create_and_consult_temp_file(Space,Fp/ATot1,[H:-(format_e("; % ######### warning: using stub for:~q\n",[F]),B)])
            ;
               create_and_consult_temp_file(Space,Fp/ATot1,[H:-('$VAR'(ATot1)=[F|AtomList1])])
            )
         )
      )
   ).

u_assign(FList,R):- is_list(FList),!,eval_args(FList,R).
u_assign(FList,R):- var(FList),nonvar(R), !, u_assign(R,FList).
u_assign(FList,R):- FList=@=R,!,FList=R.
u_assign(FList,R):- number(FList), var(R),!,R=FList.
u_assign(FList,R):- self_eval(FList), var(R),!,R=FList.
u_assign(FList,R):- var(FList),!,freeze(FList,u_assign(FList,R)).
u_assign(FList,R):- \+ compound(FList), var(R),!,R=FList.
u_assign([F|List],R):- F == ':-',!, trace_break,as_tf(clause(F,List),R).
u_assign(FList,RR):- (compound_non_cons(FList),u_assign_c(FList,RR))*->true;FList=~RR.
u_assign(FList,RR):-
  u_assign_list1(FList,RR)*->true;u_assign_list2(FList,RR).

u_assign_list1([F|List],R):- eval_args([F|List],R), nonvar(R), R\=@=[F|List].
u_assign_list2([F|List],R):- atom(F),append(List,[R],ListR),
  catch(quietly(apply(F,ListR)),error(existence_error(procedure,F/_),_),
     catch(quietly(as_tf(apply(F,List),R)),error(existence_error(procedure,F/_),_),
        quietly(catch(eval_args([F|List],R),_, R=[F|List])))).

%u_assign([V|VI],[V|VO]):- nonvar(V),is_metta_data_functor_chkd(_Eq,V),!,maplist(eval_args,VI,VO).

u_assign_c((F:-List),R):- !, R = (F:-List).

/*
u_assign_c(Cmp,RR):-
  functor_chkd(Cmp,F,_),
  current_predicate(F,_),
  debug(todo,'u_assign_c INTERP: ~q',[Cmp]),!,
  call(Cmp,RR).*/
u_assign_c(FList,RR):-
  functor_chkd(FList,F,_), % (F == 'car-atom' -> trace ; true),
  (catch(quietlY(call(FList,R)),error(existence_error(procedure,F/_),_),
     catch(quietlY(as_tf(FList,R)),error(existence_error(procedure,F/_),_),
      ((p2m(FList,[F0|List0]),catch(eval_args([F0|List0],R),_, R=~[F0|List0])))))),!,
         R=RR.
u_assign_c(FList,RR):- as_tf(FList,RR),!.
u_assign_c(FList,R):- compound(FList), !, FList=~R.

quietlY(G):- call(G).


var_table_lookup(X,[H-R|T],S) :-
   X == H,S=R;  % Test if X and H are the same variable
   var_table_lookup(X,T,S).  % Recursively check the tail of the list

convert_expression_instantiate_lazyn(LazyVars,ExprIn,ExprOut,TableIn,TableOut) :-
   map_fold1(convert_expression_instantiate_lazy1(LazyVars),ExprIn,ExprOut,TableIn,TableOut).

convert_expression_instantiate_lazy1(LazyVars,ValIn,ValOut,TableIn,TableOut) :-
   (is_list(ValIn) ->
      convert_expression_instantiate_lazyn(LazyVars,ValIn,ValOut,TableIn,TableOut)
   ; var_prop_lookup(ValIn,LazyVars,x(_,lazy,_)) ->
      (var_table_lookup(ValIn,TableIn,V) ->
         TableOut=TableIn,
         ValOut=V
      ;
         TableOut=[ValIn-X|TableIn],
         ValOut=X
      )
   ;
      TableOut=TableIn,
      ValOut=ValIn).

convert_p1_table_to_code(X-Y,[native(as_p1_expr),X,Y]).

:- discontiguous(compile_flow_control/8).
:- discontiguous(compile_flow_control3/6).
:- discontiguous(compile_flow_control2/6).
:- discontiguous(compile_flow_control1/6).



add_assignment(A,B,CodeOld,CodeNew) :-
   (fullvar(A),var(B),A==B ->
      B=A,CodeNew=CodeOld
   ; var(A),fullvar(B),A==B ->
      A=B,CodeNew=CodeOld
   ;  append(CodeOld,[[assign,A,B]],CodeNew)).

% !(compile-body! (function 1))
% !(compile-body! (function (throw 1)))
% !(compile-body! (superpose ((throw 1) (throw 2))))

/*
compile_flow_control(HeadIs, LazyVars, RetResult, ResultLazy, Convert, CodeForExpr) :- % dif_functors(HeadIs,Convert),
   Convert =~ ['eval', Expr],
   f2p(HeadIs, LazyVars, RetResult, ResultLazy, Expr, CodeForExpr).

compile_flow_control(HeadIs, LazyVars, RetResult, ResultLazy, Convert, (CodeForSpace,Converted)) :- % dif_functors(HeadIs,Convert),
   Convert =~ ['evalc', Expr, Space],
   f2p(HeadIs, LazyVars, ResSpace,  ResultLazy, Space,CodeForSpace),
   f2p(HeadIs, LazyVars, RetResult, ResultLazy,   Expr,CodeForExpr),
   Converted = with_space(ResSpace,CodeForExpr).
*/

compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Convert, Converted,ConvertedN) :-
  Convert = ['function', Body],!,
  f2p(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Body,BodyCode,BodyCodeN),
  Converted = [[prolog_catch,BodyCode,metta_return(FunctionResult),FunctionResult=RetResult]],
  ConvertedN = [[prolog_catch,BodyCodeN,metta_return(FunctionResultN),FunctionResultN=RetResultN]].

compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Convert, Converted, ConvertedN) :-
  (Convert = ['function', ['return', Body]] ; Convert = ['return',Body]),!,
  f2p(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Body,BodyCode,BodyCodeN),
  append(BodyCode,[[prolog_inline,throw(metta_return(RetResult))]],Converted),
  append(BodyCodeN,[[prolog_inline,throw(metta_return(RetResultN))]],ConvertedN).

compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Convert, Converted, ConvertedN) :- % dif_functors(HeadIs,Convert),
   Convert = ['let',Var,Value1,Body],!,
   compile_let_star(HeadIs,LazyVars,[Var,Value1],Code),
   f2p(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Body,BodyCode,BodyCodeN),
   append(Code,BodyCode,Converted),
   append(Code,BodyCodeN,ConvertedN).

compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Convert, Converted, ConvertedN) :- %dif_functors(HeadIs,Convert),
  Convert = ['let*',Bindings,Body],!,
  must_det_lls((
    maplist(compile_let_star(HeadIs,LazyVars),Bindings,CodeList),
    append(CodeList,Code),
   f2p(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Body,BodyCode,BodyCodeN),
   append(Code,BodyCode,Converted),
   append(Code,BodyCodeN,ConvertedN)
   ))
   .

compile_let_star(HeadIs,LazyVars,[Var,Value1],Code) :-
  f2p(HeadIs,LazyVars,ResValue1,ResValueN,LazyRet,Value1,CodeForValue1,CodeForValueN),
  lazy_impedance_match(LazyRet,x(doeval,eager,[]),ResValue1,CodeForValue1,ResValueN,CodeForValueN,Result,ResultCode),
  add_assignment(Var,Result,ResultCode,Code).

%compile_flow_control2(_HeadIs, LazyVars, RetResult, ResultLazy, Convert, x_assign(Convert,RetResult)) :-   is_ftVar(Convert), var(RetResult),!.

compile_flow_control2(_HeadIs,_RetResult,Convert,_):- \+ compound(Convert),!,fail.
compile_flow_control2(_HeadIs,_RetResult,Convert,_):- compound_name_arity(Convert,_,0),!,fail.
:- op(700,xfx, =~).
compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, (Code1,Eval1Result=Result,Converted)) :- % dif_functors(HeadIs,Convert),
   Convert =~ chain(Eval1,Result,Eval2),!,
   f2p(HeadIs, LazyVars, Eval1Result, ResultLazy, Eval1,Code1),
   f2p(HeadIs, LazyVars, RetResult, ResultLazy, Eval2,Converted).

/*
compile_flow_control2(_HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- % dif_functors(HeadIs,Convert),
   Convert =~ ['bind!',Var,Value],is_ftVar(Value),!,
   Converted = eval_args(['bind!',Var,Value],RetResult).
compile_flow_control2(_HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- % dif_functors(HeadIs,Convert),
   Convert =~ ['bind!',Var,Value], Value =~ ['new-space'],!,
   Converted = eval_args(['bind!',Var,Value],RetResult).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- % dif_functors(HeadIs,Convert),
   Convert =~ ['bind!',Var,Value],
   f2p(HeadIs, LazyVars, ValueResult, ResultLazy, Value,ValueCode),
   Converted = (ValueCode,eval_args(['bind!',Var,ValueResult],RetResult)).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- %  dif_functors(HeadIs,Convert),
  once(Convert =~ if(Cond,Then,Else);Convert =~ 'if'(Cond,Then,Else)),
  !,Test = is_True(CondResult),
  f2p(HeadIs, LazyVars, CondResult, ResultLazy, Cond,CondCode),
  compile_test_then_else(RetResult,LazyVars,ResultLazy,(CondCode,Test),Then,Else,Converted).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- % dif_functors(HeadIs,Convert),
   Convert =~ 'if-error'(Value,Then,Else),!,Test = is_Error(ValueResult),
  f2p(HeadIs, LazyVars, ValueResult, ResultLazy, Value,ValueCode),
  compile_test_then_else(RetResult,LazyVars,ResultLazy,(ValueCode,Test),Then,Else,Converted).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- % dif_functors(HeadIs,Convert),
   Convert =~ 'if-empty'(Value,Then,Else),!,Test = is_Empty(ValueResult),
  f2p(HeadIs, LazyVars, ValueResult, ResultLazy, Value,ValueCode),
  compile_test_then_else(RetResult,LazyVars,ResultLazy,(ValueCode,Test),Then,Else,Converted).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- % dif_functors(HeadIs,Convert),
  (Convert =~ 'if-non-empty-expression'(Value,Then,Else)),!,
  (Test = ( \+ is_Empty(ValueResult))),
  f2p(HeadIs, LazyVars, ValueResult, ResultLazy, Value,ValueCode),
  compile_test_then_else(RetResult,LazyVars,ResultLazy,(ValueCode,Test),Then,Else,Converted).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- % dif_functors(HeadIs,Convert),
    Convert =~ ['if-equals',Value1,Value2,Then,Else],!,Test = equal_enough(ResValue1,ResValue2),
    f2p(HeadIs, LazyVars, ResValue1, ResultLazy, Value1,CodeForValue1),
    f2p(HeadIs, LazyVars, ResValue2, ResultLazy, Value2,CodeForValue2),
  compile_test_then_else(RetResult,LazyVars,ResultLazy,(CodeForValue1,CodeForValue2,Test),Then,Else,Converted).
*/
compile_flow_control1(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :-
    Convert =~ ['assertEqual',Value1,Value2],!,
    cname_var('Expr_',Expr),
    cname_var('FA_',ResValue1),
    cname_var('FA_',ResValue2),
    cname_var('FARL_',L1),
    cname_var('FARL_',L2),
    f2p(HeadIs, LazyVars, ResValue1, ResultLazy, Value1,CodeForValue1),
    f2p(HeadIs, LazyVars, ResValue2, ResultLazy, Value2,CodeForValue2),
    Converted =
              (Expr = Convert,
               loonit_assert_source_tf(Expr,
                (findall(ResValue1,CodeForValue1,L1),
                 findall(ResValue2,CodeForValue2,L2)),
                 equal_enough(L1,L2),RetResult)).


compile_flow_control1(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :-
    Convert =~ ['assertEqualToResult',Value1,Value2],!,
    f2p(HeadIs, LazyVars, ResValue1, ResultLazy, Value1,CodeForValue1),
    ast_to_prolog(HeadIs,[],CodeForValue1,Prolog),

    Converted = loonit_assert_source_tf(Convert,
                findall(ResValue1,Prolog,L1),
                 equal_enough(L1,Value2),RetResult).


compile_flow_control2(_HeadIs, _LazyVars, RetResult, _ResultLazy, Convert, Converted) :-
     Convert =~ 'add-atom'(Where,What), !,
     =(What,WhatP),
     Converted = as_tf('add-atom'(Where,WhatP),RetResult).

compile_flow_control2(_HeadIs, _LazyVars, RetResult, _ResultLazy, Convert, Converted) :-
     Convert =~ 'add-atom'(Where,What,RetResult), !,
     =(What,WhatP),
     Converted = as_tf('add-atom'(Where,WhatP),RetResult).


compile_flow_control2(_HeadIs, _LazyVars, RetResult, _ResultLazy, Convert, (Converted)) :-
    Convert =~ ['superpose',ValueL],is_ftVar(ValueL),
    %maybe_unlistify(UValueL,ValueL,URetResult,RetResult),
    Converted = eval_args(['superpose',ValueL],RetResult),
    cname_var('MeTTa_SP_',ValueL).

compile_flow_control2(HeadIs, _LazyVars, RetResult, _ResultLazy, Convert, (Converted)) :-
    Convert =~ ['superpose',ValueL],is_list(ValueL),
    %maybe_unlistify(UValueL,ValueL,URetResult,RetResult),
    cname_var('SP_Ret',RetResult),
    maplist(f2p_assign(HeadIs,RetResult),ValueL,CodeForValueL),
    list_to_disjuncts(CodeForValueL,Converted),!.


maybe_unlistify([UValueL],ValueL,RetResult,[URetResult]):- fail, is_list(UValueL),!,
  maybe_unlistify(UValueL,ValueL,RetResult,URetResult).
maybe_unlistify(ValueL,ValueL,RetResult,RetResult).

list_to_disjuncts([],false).
list_to_disjuncts([A],A):- !.
list_to_disjuncts([A|L],(A;D)):-  list_to_disjuncts(L,D).


%f2p_assign(_HeadIs,V,Value,is_True(V)):- Value=='True'.
f2p_assign(_HeadIs,ValueR,Value,ValueR=Value):- \+ compound(Value),!.
f2p_assign(_HeadIs,ValueR,Value,ValueR=Value):- is_ftVar(Value),!.
f2p_assign(HeadIs,ValueResult,Value,Converted):-
   f2p(HeadIs, _LazyVars, ValueResultR, _ResultLazy, Value,CodeForValue),
   %into_equals(ValueResultR,ValueResult,ValueResultRValueResult),
   ValueResultRValueResult = (ValueResultR=ValueResult),
   combine_code(CodeForValue,ValueResultRValueResult,Converted).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert,Converted) :-
  Convert =~ ['println!',Value],!,
  Converted = (ValueCode,eval_args(['println!',ValueResult], RetResult)),
  f2p(HeadIs, LazyVars, ValueResult, ResultLazy, Value,ValueCode).



compile_flow_control4(HeadIs, LazyVars, RetResult, ResultLazy, Convert,CodeForValueConverted) :-
    % TODO: Plus seems an odd name for a variable - get an idea why?
    % Plus signifies something with numbers
    Convert =~ [Plus,N,Value], atom(Plus),
    transpile_call_prefix(Plus,PrefixPlus),
    current_predicate(PrefixPlus/3), number(N),
    \+ number(Value), \+ is_ftVar(Value),!,
    f2p(HeadIs, LazyVars, ValueResult, ResultLazy, Value,CodeForValue),!,
    Converted=..[PrefixPlus,N,ValueResult,RetResult],
    combine_code(CodeForValue,Converted,CodeForValueConverted).

compound_equals(COL1,COL2):- COL1=@=COL2,!,COL1=COL2.
compound_equals(COL1,COL2):- compound_equals1(COL1,COL2).
compound_equals1(COL1,COL2):- is_ftVar(COL1),!,is_ftVar(COL2),ignore(COL1=COL2),!.
compound_equals1(COL1,COL2):- compound(COL1),!,compound(COL2), COL1=COL2.

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :-
    Convert =~ ['superpose',COL],compound_equals(COL,'collapse'(Value1)),
    f2p(HeadIs, LazyVars, ResValue1, ResultLazy, Value1,CodeForValue1),
    Converted = (findall(ResValue1,CodeForValue1,Gathered),member(RetResult,Gathered)).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :-
    Convert =~ ['collapse',Value1],!,
    f2p(HeadIs, LazyVars, ResValue1, ResultLazy, Value1,CodeForValue1),
    Converted = (findall(ResValue1,CodeForValue1,RetResult)).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :-
    Convert =~ ['compose',Value1],!, Convert2 =~ ['collapse',Value1],!,
    compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert2, Converted).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- % dif_functors(HeadIs,Convert),
  Convert =~ ['unify',Value1,Value2,Then,Else],!,Test = metta_unify(ResValue1,ResValue2),
    f2p(HeadIs, LazyVars, ResValue1, ResultLazy, Value1,CodeForValue1),
    f2p(HeadIs, LazyVars, ResValue2, ResultLazy, Value2,CodeForValue2),
  compile_test_then_else(RetResult,LazyVars,ResultLazy,(CodeForValue1,CodeForValue2,Test),Then,Else,Converted).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- % dif_functors(HeadIs,Convert),
  Convert =~ ['unify-if',Value1,Value2,Then,Else],!,Test = metta_unify(ResValue1,ResValue2),
    f2p(HeadIs, LazyVars, ResValue1, ResultLazy, Value1,CodeForValue1),
    f2p(HeadIs, LazyVars, ResValue2, ResultLazy, Value2,CodeForValue2),
  compile_test_then_else(RetResult,LazyVars,ResultLazy,(CodeForValue1,CodeForValue2,Test),Then,Else,Converted).


/*
% match(Space,f(1)=Y,Y)
compile_flow_control2(HeadIs, LazyVars, Y, ResultLazy, Convert,Converted) :- dif_functors(HeadIs,Convert),
  Convert=~ match(Space,AsFunctionY,YY),
    nonvar(AsFunctionY),( AsFunctionY =~ (AsFunction=Y)), nonvar(AsFunction),
    !, Y==YY,
    f2p(HeadIs, LazyVars, Y, ResultLazy, AsFunction,Converted),!.
*/
compile_flow_control2(HeadIs, LazyVars, Atom, ResultLazy, Convert,Converted) :-
   Convert=~ match(Space,Q,T),Q==T,Atom=Q,!,
  compile_flow_control2(HeadIs, LazyVars, Atom, ResultLazy, 'get-atoms'(Space),Converted).

compile_flow_control2(_HeadIs, _LazyVars, Match, _ResultLazy, Convert,Converted) :-
    Convert=~ 'get-atoms'(Space),
    Converted = metta_atom_iter(Space,Match).

compile_flow_control2(HeadIs, _LazyVars, AtomsVar, _ResultLazy, Convert,Converted) :-
    Convert=~ 'get-atoms'(Space), AtomsVar = Pattern,
    compile_pattern(HeadIs,Space,Pattern,Converted).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert,Converted) :- dif_functors(HeadIs,Convert),
  Convert =~ 'match'(Space,Pattern,Template),!,
    f2p(HeadIs, LazyVars, RetResult, ResultLazy, Template,TemplateCode),
    compile_pattern(HeadIs,Space,Pattern,SpacePatternCode),
    combine_code(SpacePatternCode,TemplateCode,Converted).

compile_pattern(_HeadIs,Space,Match,SpaceMatchCode):-
  SpaceMatchCode = metta_atom_iter(Space,Match).

metta_atom_iter(Space,Match):-
  metta_atom_iter('=',10,Space,Space,Match).



make_with_space(Space,MatchCode,MatchCode):- Space=='&self',!.
make_with_space(Space,MatchCode,with_space(Space,MatchCode)):- Space\=='&self'.

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- dif_functors(HeadIs,Convert),
  Convert =~ 'match'(_Space,Match,Template),!,
   must_det_lls((
    f2p(HeadIs, LazyVars, _, ResultLazy, Match,MatchCode),
    into_equals(RetResult,Template,TemplateCode),
    combine_code(MatchCode,TemplateCode,Converted))).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- dif_functors(HeadIs,Convert),
   Convert =~ ['if-decons',Atom,Head,Tail,Then,Else],!,Test = unify_cons(AtomResult,ResHead,ResTail),
    f2p(HeadIs, LazyVars, AtomResult, ResultLazy, Atom,AtomCode),
    f2p(HeadIs, LazyVars, ResHead, ResultLazy, Head,CodeForHead),
    f2p(HeadIs, LazyVars, ResTail, ResultLazy, Tail,CodeForTail),
    compile_test_then_else(RetResult,LazyVars,ResultLazy,(AtomCode,CodeForHead,CodeForTail,Test),Then,Else,Converted).


compile_flow_control1(_HeadIs, _LazyVars, RetResult, _ResultLazy, Convert,is_True(RetResult)) :- is_compiled_and(AND),
   Convert =~ [AND],!.

compile_flow_control1(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- is_compiled_and(AND),
   Convert =~ [AND,Body],!,
   f2p(HeadIs, LazyVars, RetResult, ResultLazy, Body,BodyCode),
    compile_test_then_else(RetResult,LazyVars,ResultLazy,BodyCode,'True','False',Converted).

compile_flow_control1(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- is_compiled_and(AND),
   Convert =~ [AND,Body1,Body2],!,
   f2p(HeadIs, LazyVars, B1Res, ResultLazy, Body1,Body1Code),
   f2p(HeadIs, LazyVars, RetResult, ResultLazy, Body2,Body2Code),
   into_equals(B1Res,'True',AE),
   Converted = (Body1Code,AE,Body2Code),!.


compile_flow_control1(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- is_compiled_and(AND),
   Convert =~ [AND,Body1,Body2],!,
   f2p(HeadIs, LazyVars, B1Res, ResultLazy, Body1,Body1Code),
   f2p(HeadIs, LazyVars, _, ResultLazy, Body2,Body2Code),
   into_equals(B1Res,'True',AE),
   compile_test_then_else(RetResult,LazyVars,ResultLazy,(Body1Code,AE,Body2Code),'True','False',Converted).

compile_flow_control1(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted) :- is_compiled_and(AND),
   Convert =~ [AND,Body1,Body2|BodyMore],!,
   And2 =~ [AND,Body2|BodyMore],
   Next =~ [AND,Body1,And2],
   compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy,  Next, Converted).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, sequential(Convert), Converted) :- !,
   compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, transpose(Convert), Converted).

compile_flow_control2(HeadIs, _LazyVars, RetResult, _ResultLazy, transpose(Convert), Converted,Code) :- !,
   maplist(each_result(HeadIs,RetResult),Convert, Converted),
   list_to_disjuncts(Converted,Code).


each_result(HeadIs,RetResult,Convert,Converted):-
   f2p(HeadIs, _LazyVars, OneResult, _ResultLazy, Convert,Code1),
   into_equals(OneResult,RetResult,Code2),
   combine_code(Code1,Code2,Converted).

compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Converter, Converted):- de_eval(Converter,Convert),!,
   compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted).

compile_flow_control2(HeadIs, LazyVars, _Result, ResultLazy, Convert, Converted) :- fail,
   functor_chkd(Convert,Func,PA),
   functional_predicate_arg(Func,PA,Nth),
   Convert =~ [Func|PredArgs],
   nth1(Nth,PredArgs,Result,FuncArgs),
   RetResult = Result,
   AsFunct =~ [Func|FuncArgs],
   compile_flow_control2(HeadIs, LazyVars, RetResult, ResultLazy, AsFunct, Converted).

dif_functors(HeadIs,_):- var(HeadIs),!,fail.
dif_functors(HeadIs,_):- \+ compound(HeadIs),!.
dif_functors(HeadIs,Convert):- compound(HeadIs),compound(Convert),
  compound_name_arity(HeadIs,F,A),compound_name_arity(Convert,F,A).

is_compiled_and(AND):- member(AND,[ (','), ('and'), ('and-seq')]).

flowc.

unnumbervars_clause(Cl,ClU):-
  woc((copy_term_nat(Cl,AC),unnumbervars(AC,UA),copy_term_nat(UA,ClU))),!.
% ===============================
%  Compile in memory buffer
% ===============================
is_clause_asserted(AC):- unnumbervars_clause(AC,UAC),
  expand_to_hb(UAC,H,B),
  H @.. [Fh|Args],
  length(Args,N),
  N1 is N-1,
  atomic_list_concat(['mc__1_',N1,'_',Fh],FPrefixed),
  H2 @.. [FPrefixed|Args],
  clause_occurs_warning(H2,B,Ref),clause(HH,BB,Ref),
  strip_m(HH,HHH),HHH=@=H2,
  strip_m(BB,BBB),BBB=@=B,!.

%get_clause_pred(UAC,F,A):- expand_to_hb(UAC,H,_),strip_m(H,HH),functor_chkd(HH,F,A).


% :- dynamic(needs_tabled/2).

add_assertion(Space,List):- is_list(List),!,
   maplist(add_assertion(Space),List),!.
add_assertion(Space,AC):- must_det_lls(unnumbervars_clause(AC,UAC)), add_assertion1(Space,UAC).

with_mutex_maybe(_,Goal):- wocf(call(Goal)).

add_assertion1(_,AC):- /*'&self':*/is_clause_asserted(AC),!.
%add_assertion1(_,AC):- get_clause_pred(AC,F,A), \+ needs_tabled(F,A), !, pfcAdd(/*'&self':*/AC),!.
%add_assertion1(Space,ACC) :- add_assertion1_depricated(Space,ACC), !.
add_assertion1(_,ACC) :- compiler_assertz(ACC), !.
add_assertion1_depricated(Space,ACC) :-
   must_det_lls((
     copy_term(ACC,AC,_),
     expand_to_hb(AC,H,_),
     as_functor_args(H,F,A), as_functor_args(HH,F,A),
    with_mutex_maybe(transpiler_mutex_lock,(
      % assert(AC),
      % Get the current clauses of my_predicate/1
      findall(HH:-B,clause(/*'&self':*/HH,B),Prev),
      copy_term(Prev,CPrev,_),
      % Create a temporary file and add the new assertion along with existing clauses
      append(CPrev,[AC],NewList),
      cl_list_to_set(NewList,Set),
      length(Set,N),
      if_t(N=2,
         (Set=[X,Y],
            numbervars(X, 0, _, [attvar(skip)]),
            numbervars(Y, 0, _, [attvar(skip)])
         %nl,display(X),
         %nl,display(Y),
         %nl
         )),
      %wdmsg(list_to_set(F/A,N)),
      abolish(/*'&self':*/F/A),
      create_and_consult_temp_file(Space,F/A, Set)
    ))
)).

as_functor_args(AsPred,F,A):- as_functor_args(AsPred,F,A,_ArgsL),!.

as_functor_args(AsPred,F,A,ArgsL):-var(AsPred),!,
  (is_list(ArgsL);(integer(A),A>=0)),!,
   length(ArgsL,A),
   (symbol(F)->
      AsPred @.. [F|ArgsL]
   ;
      (AsPred = [F|ArgsL])).

as_functor_args(call_fn_native(F,_,ArgsL),F,A,ArgsL):- length(ArgsL,A),!.
%as_functor_args(AsPred,_,_,_Args):- is_ftVar(AsPred),!,fail.
as_functor_args(AsPred,F,A,ArgsL):- \+ iz_conz(AsPred),
  AsPred @.. List,!, as_functor_args(List,F,A,ArgsL),!.
%as_functor_args([Eq,R,Stuff],F,A,ArgsL):- (Eq == '='),
%   into_list_args(Stuff,List),append(List,[R],AsPred),!,
%   as_functor_args(AsPred,F,A,ArgsL).
as_functor_args([F|ArgsL],F,A,ArgsL):-  length(ArgsL,A),!.

cl_list_to_set([A|List],Set):-
  member(B,List),same_clause(A,B),!,
  cl_list_to_set(List,Set).
cl_list_to_set([New|List],[New|Set]):-!,
  cl_list_to_set(List,Set).
cl_list_to_set([A,B],[A]):- same_clause(A,B),!.
cl_list_to_set(List,Set):- list_to_set(List,Set).

same_clause(A,B):- A==B,!.
same_clause(A,B):- A=@=B,!.
same_clause(A,B):- unnumbervars_clause(A,AA),unnumbervars_clause(B,BB),same_clause1(AA,BB).
same_clause1(A,B):- A=@=B.
same_clause1(A,B):- expand_to_hb(A,AH,AB),expand_to_hb(B,BH,BB),AB=@=BB, AH=@=BH,!.

%clause('is-closed'(X),OO1,Ref),clause('is-closed'(X),OO2,Ref2),Ref2\==Ref, OO1=@=OO2.

% Convert a list of conditions into a conjunction
list_to_conjunction(C,[CJ]):- \+ is_list(C), !, C = CJ.
list_to_conjunction([], true).
list_to_conjunction([Cond], Cond).
list_to_conjunction([H|T], RestConj) :- H == true, !, list_to_conjunction(T, RestConj).
list_to_conjunction([H|T], (H, RestConj)) :-
   list_to_conjunction(T, RestConj).

% Utility: Combine and flatten a single term into a conjunction
combine_code(Term, Conjunction) :-
    flatten_term(Term, FlatList),
    list_to_conjunction(FlatList, Conjunction).

% combine_code/3: Combines Guard and Body into a flat conjunction
combine_code(Guard, Body, Combined) :-
    combine_code(Guard, FlatGuard), % Flatten Guard
    combine_code(Body, FlatBody),   % Flatten Body
    combine_flattened(FlatGuard, FlatBody, Combined).

% Combine two flattened terms intelligently
combine_flattened(true, Body, Body) :- !.
combine_flattened(Guard, true, Guard) :- !.
combine_flattened(Guard, Body, (Guard, Body)).

% Flatten terms into a flat list
flatten_term(C, CJ):- C==[],!,CJ=C.
flatten_term(C, [CJ]):- \+ compound(C), !, C = CJ.
flatten_term((A, B), FlatList) :- !, % If Term is a conjunction, flatten both sides
    flatten_term(A, FlatA),
    flatten_term(B, FlatB),
    append(FlatA, FlatB, FlatList).
flatten_term(List, FlatList) :- is_list(List),
    !, % If Term is a list, recursively flatten its elements
    maplist(flatten_term, List, NestedLists),
    append(NestedLists, FlatList).
flatten_term([A | B ], FlatList) :-  !, % If Term is a conjunction, flatten both sides
    flatten_term(A, FlatA),
    flatten_term(B, FlatB),
    append(FlatA, FlatB, FlatList).
flatten_term(Term, [Term]). % Base case: single term, wrap it in a list


fn_eval(Fn,Args,Res):- is_list(Args),symbol(Fn),
  transpile_call_prefix(Fn,Pred),
  Pre @.. [Pred|Args],
  catch(call(Pre,Res),error(existence_error(procedure,_/_),_),Res=[Fn|Args]).

fn_native(Fn,Args):- apply(Fn,Args).
%fn_eval(Fn,Args,[Fn|Args]).

assign(X,list(Y)):- is_list(Y),!,X=Y.
assign(X,X).

x_assign(X,X).



ok_to_append('$VAR'):- !, fail.
ok_to_append(_).

p2s(P,S):- into_list_args(P,S).

non_compound(S):- \+ compound(S).


did_optimize_conj(Head,B1,B2,B12):-
 optimize_conj(Head,B1,B2,B12),
 actual_change(B12 , (B1,B2)),!.


optimize_conjuncts(Head,(B1,B2,B3),BN):- B3\=(_,_),
  did_optimize_conj(Head,B2,B3,B23),
  optimize_conjuncts(Head,B1,B23,BN), !.
optimize_conjuncts(Head,(B1,B2,B3),BN):-
  did_optimize_conj(Head,B1,B2,B12),
  optimize_conjuncts(Head,B12,B3,BN),!.
%optimize_conjuncts(Head,(B1,B2),BN1):- optimize_conj(Head,B1,B2,BN1).
optimize_conjuncts(Head,(B1,B2),BN1):- did_optimize_conj(Head,B1,B2,BN1),!.
optimize_conjuncts(Head,B1,B2,OUT):-
   optimize_body(Head,B1,BN1), optimize_body(Head,B2,BN2),!,(BN1,BN2)=OUT.

%optimize_conj(_, x_assign(Term, C), is_True(CC), eval_true(Term)):- 'True'==True, CC==C.
%optimize_conj(_, x_assign(Term, C), is_True(CC), eval_true(Term)):- CC==C, !.
optimize_conj(_, B1,BT,B1):- assumed_true(BT),!.
optimize_conj(_, BT,B1,B1):- assumed_true(BT),!.
%optimize_conj(Head, x_assign(Term, C), x_assign(True,CC), Term):- 'True'==True,
%     optimize_conj(Head, x_assign(Term, C), is_True(CC), CTerm).
%optimize_conj(Head,B1,BT,BN1):- assumed_true(BT),!, optimize_body(Head,B1,BN1).
%optimize_conj(Head,BT,B1,BN1):- assumed_true(BT),!, optimize_body(Head,B1,BN1).
% optimize_conj(Head,B1,B2,OUT):- optimize_body(Head,B1,BN1), optimize_body(Head,B2,BN2),!,(BN1,BN2)=OUT.

assumed_true(B2):- var(B2),!,fail.
assumed_true(eval_true(B2)):-!,assumed_true(B2).
assumed_true(B2):- B2== true,!.
assumed_true(B2):- B2==x_assign('True', '$VAR'('_')),!.
assumed_true(X==Y):- assumed_true(X=Y).
assumed_true(X=Y):- var(X),var(Y), X=Y.
assumed_true(X=Y):- is_ftVar(X),is_ftVar(Y), X=Y.


filter_head_arg(H,F):- var(H),!,H=F.
filter_head_arge(H,F):- H = F.

code_callable(Term,_CTerm):- var(Term),!,fail.
code_callable(Term, CTerm):- current_predicate(_,Term),!,Term=CTerm.
%code_callable(Term, CTerm):- current_predicate(_,Term),!,Term=CTerm.









end_of_file.











compile_head_variablization(Head, NewHead, HeadCode) :-
   must_det_lls((
      as_functor_args(Head,Functor,A,Args),
      % Find non-singleton variables in Args
      fix_non_singletons(Args, NewArgs, Conditions),
      list_to_conjunction(Conditions,HeadCode),
      as_functor_args(NewHead,Functor,A,NewArgs))).

fix_non_singletons(Args, NewArgs, [Code|Conditions]) :-
   sub_term_loc(Var, Args, Loc1), is_ftVar(Var),
   sub_term_loc_replaced(==(Var), _Var2, Args, Loc2, ReplVar2, NewArgsM),
   Loc1 \=@= Loc2,
   Code = same(ReplVar2,Var),
fix_non_singletons(NewArgsM, NewArgs, Conditions).
fix_non_singletons(Args, Args, []):-!.


sub_term_loc(A,A,self).
sub_term_loc(E,Args,e(N,nth1)+Loc):- is_list(Args),!, nth1(N,Args,ST),sub_term_loc(E,ST,Loc).
sub_term_loc(E,Args,e(N,arg)+Loc):- compound(Args),arg(N,Args,ST),sub_term_loc(E,ST,Loc).

sub_term_loc_replaced(P1,E,Args,LOC,Var,NewArgs):- is_list(Args), !, sub_term_loc_l(nth1,P1,E,Args,LOC,Var,NewArgs).
sub_term_loc_replaced(P1,E,FArgs,LOC,Var,NewFArgs):- compound(FArgs), \+ is_ftVar(FArgs),!,
   compound_name_arguments(FArgs, Name, Args),
   sub_term_loc_l(arg,P1,E,Args,LOC,Var,NewArgs),
   compound_name_arguments(NewCompound, Name, NewArgs),NewFArgs=NewCompound.
   sub_term_loc_replaced(P1,A,A,self,Var,Var):- call(P1,A).


sub_term_loc_l(Nth,P1,E,Args,e(N,Nth)+Loc,Var,NewArgs):-
   reverse(Args,RevArgs),
   append(Left,[ST|Right],RevArgs),
   sub_term_loc_replaced(P1,E,ST,Loc,Var,ReplaceST),
   append(Left,[ReplaceST|Right],RevNewArgs),
   reverse(RevNewArgs,NewArgs),
   length([_|Right], N).

/*
as_functor_args(AsPred,F,A,ArgsL):-    nonvar(AsPred),!,into_list_args(AsPred,[F|ArgsL]),    length(ArgsL,A).
as_functor_args(AsPred,F,A,ArgsL):-
   nonvar(F),length(ArgsL,A),AsPred = [F|ArgsL].
*/

compile_for_assert(HeadIs, AsBodyFn, Converted) :- (AsBodyFn =@= HeadIs ; AsBodyFn == []), !,/*trace,*/  compile_head_for_assert(HeadIs,Converted).

% If Convert is of the form (AsFunction=AsBodyFn), we perform conversion to obtain the equivalent predicate.
compile_for_assert(Head, AsBodyFn, Converted) :-
   once(compile_head_variablization(Head, HeadC, CodeForHeadArgs)),
   \+(atomic(CodeForHeadArgs)), !,
   compile_for_assert(HeadC,
      (CodeForHeadArgs,AsBodyFn), Converted).

compile_for_assert(HeadIs, AsBodyFn, Converted) :- is_ftVar(AsBodyFn), /*trace,*/
   AsFunction = HeadIs,!,
   must_det_lls((
   Converted = (HeadC :- BodyC),  % Create a rule with Head as the converted AsFunction and NextBody as the converted AsBodyFn
   %funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, _Nth, Head),
   f2p(HeadIs, LazyVars, HResult, ResultLazy, AsFunction,HHead),
   (var(HResult) -> (Result = HResult, HHead = Head) ;
      funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, _Nth, Head)),
   NextBody = x_assign(AsBodyFn,Result),
   optimize_head_and_body(Head,NextBody,HeadC,BodyC),
   nop(ignore(Result = '$VAR'('HeadRes'))))),!.

% PLACEHOLDER


% If Convert is of the form (AsFunction=AsBodyFn), we perform conversion to obtain the equivalent predicate.
compile_for_assert(HeadIs, AsBodyFn, Converted) :-
   AsFunction = HeadIs, Converted = (HeadCC :- BodyCC),
   funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, _Nth, Head),
   compile_head_args(Head,HeadC,CodeForHeadArgs),
   f2p(HeadIs, LazyVars, Result, ResultLazy, AsBodyFn,NextBody),
   combine_code(CodeForHeadArgs,NextBody,BodyC),!,
   optimize_head_and_body(HeadC,BodyC,HeadCC,BodyCC),!.



% ===============================
%       COMPILER / OPTIMIZER
% Scryer Compiler vs PySWIP ASM Compiler
%
% PySWIP is 222 times faster per join
% ===============================


% Conversion is possible between a function and a predicate of arity when the result is at the nth arg
:- dynamic decl_functional_predicate_arg/3.

% Converion is possible between a  function and predicate is tricky
functional_predicate_arg_tricky(is, 2, 1). % E.g. eval_args(is(+(1,2)),Result) converts to is(Result,+(1,2)).
% Defining standard mappings for some common functions/predicates
decl_functional_predicate_arg(append, 3, 3).
decl_functional_predicate_arg(+, 3, 3).
decl_functional_predicate_arg(pi, 1, 1).
decl_functional_predicate_arg('Empty', 1, 1).
decl_functional_predicate_arg(call,4,4).
decl_functional_predicate_arg(eval_args, 2, 2).
decl_functional_predicate_arg(edge, 2, 2).
decl_functional_predicate_arg('==', 2, 2).
decl_functional_predicate_arg('is-same', 2, 2).
decl_functional_predicate_arg(assertTrue, 2, 2).
decl_functional_predicate_arg(case, 3, 3).
decl_functional_predicate_arg(assertFalse, 2, 2).
decl_functional_predicate_arg('car-atom', 2, 2).
decl_functional_predicate_arg(match,4,4).
decl_functional_predicate_arg('TupleConcat',3,3).
decl_functional_predicate_arg('new-space',1,1).

decl_functional_predicate_arg(superpose, 2, 2).

do_predicate_function_canonical(F,FF):- predicate_function_canonical(F,FF),!.
do_predicate_function_canonical(F,F).
predicate_function_canonical(is_Empty,'Empty').

pi(PI):- PI is pi.

% Retrieve Head of the List
% 'car-atom'(List, Head):- eval_H(['car-atom', List], Head).


% Mapping any current predicate F/A to a function, if it's not tricky
functional_predicate_arg(F, A, L):- decl_functional_predicate_arg(F, A, L).
functional_predicate_arg(F, A, L):- (atom(F)->true;trace), predicate_arity(F,A),
  \+ functional_predicate_arg_tricky(F,A,_), L=A,
  \+ decl_functional_predicate_arg(F, A, _).
functional_predicate_arg(F, A, L):- functional_predicate_arg_tricky(F, A, L).

predicate_arity(F,A):- metta_atom('&self',[:,F,[->|Args]]), length(Args,A).
predicate_arity(F,A):- current_predicate(F/A).
% Certain constructs should not be converted to functions.
not_function(P):- atom(P),!,not_function(P,0).
not_function(P):- callable(P),!,functor_chkd(P,F,A),not_function(F,A).
not_function(F,A):- is_arity_0(F,FF),!,not_function(FF,A).
not_function(!,0).
not_function(print,1).
not_function((':-'),2).
not_function((','),2).
not_function((';'),2).
not_function(('='),2).
not_function(('or'),2).

not_function('a',0).
not_function('b',0).
not_function(F,A):- is_control_structure(F,A).
not_function(A,0):- atom(A),!.
not_function('True',0).
not_function(F,A):- predicate_arity(F,A),AA is A+1, \+ decl_functional_predicate_arg(F,AA,_).

needs_call_fr(P):- is_function(P,_Nth),functor_chkd(P,F,A),AA is A+1, \+ current_predicate(F/AA).

is_control_structure(F,A):- atom(F), atom_concat('if-',_,F),A>2.

'=='(A, B, Res):- as_tf(equal_enough(A, B),Res).
'or'(G1,G2):- G1 *-> true ; G2.
'or'(G1,G2,Res):- as_tf((G1 ; G2),Res).

% Function without arguments can be converted directly.
is_arity_0(AsFunction,F):- compound(AsFunction), compound_name_arity(AsFunction,F,0).

% Determines whether a given term is a function and retrieves the position
% in the predicate where the function Result is stored/retrieved
is_function(AsFunction, _):- is_ftVar(AsFunction),!,fail.
is_function(AsFunction, _):- AsFunction=='$VAR',!, trace, fail.
is_function(AsFunction, Nth) :- is_arity_0(AsFunction,F), \+ not_function(F,0), !,Nth=1.
is_function(AsFunction, Nth) :- is_arity_0(AsFunction,_), !,Nth=1.
is_function(AsFunction, Nth) :-
    callable(AsFunction),
    functor_chkd(AsFunction, Functor, A),
    \+ not_function(Functor, A),
    AA is A + 1,
    functional_predicate_arg_maybe(Functor, AA, Nth).

functional_predicate_arg_maybe(F, AA, Nth):- functional_predicate_arg(F, AA, Nth),!.
functional_predicate_arg_maybe(F, AA, _):- A is AA - 1,functional_predicate_arg(F,A,_),!,fail.
functional_predicate_arg_maybe(F, Nth, Nth):- asserta(decl_functional_predicate_arg(F, Nth, Nth)),!.

% If Convert is of the form (AsFunction=AsBodyFn), we perform conversion to obtain the equivalent predicate.
compile_head_for_assert(HeadIs, (Head:-Body)):-
   compile_head_for_assert(HeadIs, NewHeadIs,Converted),
   head_preconds_into_body(NewHeadIs,Converted,Head,Body).

head_as_is(Head):-
   as_functor_args(Head,Functor,A,_),!,
   head_as_is(Functor,A).
head_as_is(if,3).

compile_head_for_assert(Head, Head, true):-
   head_as_is(Head),!.

compile_head_for_assert(Head, NewestHead, HeadCode):-
   compile_head_variablization(Head, NewHead, VHeadCode),
   compile_head_args(NewHead, NewestHead, AHeadCode),
   combine_code(VHeadCode,AHeadCode,HeadCode).

% Construct the new head and the match body
compile_head_args(Head, NewHead, HeadCode) :-
   must_det_lls((
      as_functor_args(Head,Functor,A,Args),
      maplist(f2p_assign(Head),NewArgs,Args,CodeL),
      as_functor_args(NewHead,Functor,A,NewArgs),
      list_to_conjuncts(CodeL,HeadCode))),!.







:- op(700,xfx,'=~').



compile_for_assert(HeadIs, AsBodyFn, Converted) :- (AsBodyFn =@= HeadIs ; AsBodyFn == []), !,/*trace,*/  compile_head_for_assert(HeadIs,Converted).

% If Convert is of the form (AsFunction=AsBodyFn), we perform conversion to obtain the equivalent predicate.
compile_for_assert(Head, AsBodyFn, Converted) :-
   once(compile_head_variablization(Head, HeadC, CodeForHeadArgs)),
   \+(atomic(CodeForHeadArgs)), !,
   compile_for_assert(HeadC,
      (CodeForHeadArgs,AsBodyFn), Converted).

compile_for_assert(HeadIs, AsBodyFn, Converted) :- fail,is_ftVar(AsBodyFn), /*trace,*/
   AsFunction = HeadIs,!,
   must_det_lls((
   Converted = (HeadC :- BodyC),  % Create a rule with Head as the converted AsFunction and NextBody as the converted AsBodyFn
   %funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, _Nth, Head),
   f2p(HeadIs, LazyVars, HResult, ResultLazy, AsFunction,HHead),
   (var(HResult) -> (Result = HResult, HHead = Head) ;
      funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, _Nth, Head)),
   NextBody = x_assign(AsBodyFn,Result),
   optimize_head_and_body(Head,NextBody,HeadC,BodyC),
   nop(ignore(Result = '$VAR'('HeadRes'))))),!.

compile_for_assert(HeadIs, AsBodyFn, Converted) :-
   %format_e("~q ~q ~q\n",[HeadIs, AsBodyFn, Converted]),
   AsFunction = HeadIs,
   must_det_lls((
   Converted = (HeadC :- NextBodyC),  % Create a rule with Head as the converted AsFunction and NextBody as the converted AsBodyFn
   /*funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, _Nth, Head),*/
   f2p(HeadIs, LazyVars, HResult, ResultLazy, AsFunction,HHead),
   (var(HResult) -> (Result = HResult, HHead = Head) ;
      funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, _Nth, Head)),
   %verbose_unify(Converted),
   f2p(HeadIs, LazyVars, Result, ResultLazy, AsBodyFn,NextBody),
   %RetResult = Converted,
   %RetResult = _,
   optimize_head_and_body(Head,NextBody,HeadC,NextBodyC),
   %fbug([convert(Convert),head_preconds_into_body(HeadC:-NextBodyC)]),
   %if_t(((Head:-NextBody)\=@=(HeadC:-NextBodyC)),fbug(was(Head:-NextBody))),
   nop(ignore(Result = '$VAR'('HeadRes'))))),!.

% If Convert is of the form (AsFunction=AsBodyFn), we perform conversion to obtain the equivalent predicate.
compile_for_assert(HeadIs, AsBodyFn, Converted) :-
   AsFunction = HeadIs, Converted = (HeadCC :- BodyCC),
   funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, _Nth, Head),
   compile_head_args(Head,HeadC,CodeForHeadArgs),
   f2p(HeadIs, LazyVars, Result, ResultLazy, AsBodyFn,NextBody),
   combine_code(CodeForHeadArgs,NextBody,BodyC),!,
   optimize_head_and_body(HeadC,BodyC,HeadCC,BodyCC),!.


/*
*/
metta_predicate(eval_args(evaluable,eachvar)).
metta_predicate(eval_true(matchable)).
metta_predicate(with_space(space,matchable)).
metta_predicate(limit(number,matchable)).
metta_predicate(findall(template,matchable,listvar)).
metta_predicate(match(space,matchable,template,eachvar)).

head_preconds_into_body(Head,Body,Head,Body):- \+ compound(Head),!.
head_preconds_into_body((PreHead,True),Converted,Head,Body):- True==true,!,
  head_preconds_into_body(PreHead,Converted,Head,Body).
head_preconds_into_body((True,PreHead),Converted,Head,Body):- True==true,!,
  head_preconds_into_body(PreHead,Converted,Head,Body).
head_preconds_into_body(PreHead,(True,Converted),Head,Body):- True==true,!,
  head_preconds_into_body(PreHead,Converted,Head,Body).
head_preconds_into_body(PreHead,(Converted,True),Head,Body):- True==true,!,
  head_preconds_into_body(PreHead,Converted,Head,Body).
head_preconds_into_body((AsPredO,Pre),Converted,Head,Body):-
  head_preconds_into_body(Pre,(AsPredO,Converted),Head,Body).

head_preconds_into_body(AHead,Body,Head,BodyNew):-
    assertable_head(AHead,Head),
    optimize_body(Head,Body,BodyNew).


assertable_head(u_assign(FList,R),Head):- FList =~ [F|List],
   append(List,[R],NewArgs), atom(F),!,
   Head @.. [F|NewArgs].
assertable_head(Head,Head).



:- discontiguous f2p/4.

% If Convert is a variable, the corresponding predicate is just eval_args(Convert, RetResult)
f2p(_HeadIs,RetResult,Convert, RetResultConverted) :-
     is_ftVar(Convert),!,% Check if Convert is a variable
     into_equals(RetResult,Convert,RetResultConverted).
    % Converted = eval_args(Convert, RetResult).  % Set Converted to eval_args(Convert, RetResult)

% If Convert is a variable, the corresponding predicate is just eval_args(Convert, RetResult)
f2p(_HeadIs,RetResult,Convert, RetResultConverted) :-
     is_ftVar(Convert),!,% Check if Convert is a variable
     into_equals(RetResult,Convert,RetResultConverted).
    % Converted = eval_args(Convert, RetResult).  % Set Converted to eval_args(Convert, RetResult)
f2p(_HeadIs,RetResult,Convert, RetResultConverted) :-
     number(Convert),!,into_equals(RetResult,Convert,RetResultConverted).

f2p(_HeadIs,RetResult,Convert, Converted) :-
     is_arity_0(Convert,F), !, Converted = x_assign([F],RetResult),!.



/*f2p(HeadIs,RetResult, ConvertL, (Converted,RetResultL=RetResult)) :- is_list(ConvertL),
   maplist(f2p_assign(HeadIs),RetResultL,ConvertL, ConvertedL),
   list_to_conjuncts(ConvertedL,Converted).*/

% If Convert is an "eval_args" function, we convert it to the equivalent "is" predicate.
f2p(HeadIs, LazyVars, RetResult, ResultLazy, EvalConvert,Converted):- EvalConvert =~ eval_args(Convert),  !,
  must_det_lls((f2p(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted))).

% placeholder

f2p(HeadIs,RetResult,Convert, Converted):-
    compound(Convert), Convert = x_assign(C, Var), compound_non_cons(C),into_list_args(C,CC),!,
    f2p(HeadIs,RetResult,x_assign(CC, Var), Converted).

f2p(_HeadIs,_RetResult,Convert, Converted):-
    compound(Convert), Convert = x_assign(C, _Var), is_list(C),Converted = Convert,!.

f2p(HeadIs,RetResult,Convert, Converted) :-
     atom(Convert),  functional_predicate_arg(Convert,Nth,Nth2),
      Nth==1,Nth2==1,
      HeadIs\==Convert,
      Convert = F,!,
      must_det_lls((
        do_predicate_function_canonical(FP,F),
        compound_name_list(Converted,FP,[RetResult]))).

% PLACEHOLDER

% If Convert is an "is" function, we convert it to the equivalent "is" predicate.
f2p(HeadIs, LazyVars, RetResult, ResultLazy, is(Convert),(Converted,is(RetResult,Result))):- !,
   must_det_lls((f2p(HeadIs, LazyVars, Result, ResultLazy, Convert, Converted))).

% If Convert is an "or" function, we convert it to the equivalent ";" (or) predicate.
f2p(HeadIs, LazyVars, RetResult, ResultLazy, or(AsPredI,Convert), (AsPredO *-> true; Converted)) :- fail, !,
  must_det_lls((f2p(HeadIs, LazyVars, RetResult, ResultLazy, AsPredI, AsPredO),
               f2p(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted))).

f2p(HeadIs, LazyVars, RetResult, ResultLazy, (AsPredI; Convert), (AsPredO; Converted)) :- !,
  must_det_lls((f2p(HeadIs, LazyVars, RetResult, ResultLazy, AsPredI, AsPredO),
               f2p(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted))).
f2p(HeadIs, LazyVars, RetResult, ResultLazy, SOR,or(AsPredO, Converted)) :-
  SOR =~ or(AsPredI, Convert),
  must_det_lls((f2p(HeadIs, LazyVars, RetResult, ResultLazy, AsPredI, AsPredO),
               f2p(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted))),!.

% If Convert is a "," (and) function, we convert it to the equivalent "," (and) predicate.
f2p(HeadIs, LazyVars, RetResult, ResultLazy, (AsPredI, Convert), (AsPredO, Converted)) :- !,
  must_det_lls((f2p(HeadIs, LazyVars, _RtResult, ResultLazy, AsPredI, AsPredO),
               f2p(HeadIs, LazyVars, RetResult, ResultLazy, Convert, Converted))).

% If Convert is a ":-" (if) function, we convert it to the equivalent ":-" (if) predicate.
f2p(_HeadIs,RetResult, Convert, Converted) :- Convert =(H:-B),!,
  RetResult=(H:-B), Converted = true.

f2p(_HeadIs,_RetResult, N=V, Code) :- !, into_equals(N,V,Code).





% If Convert is a list, we convert it to its termified form and then proceed with the functs_to_preds conversion.
f2p(HeadIs,RetResult,Convert, Converted) :- fail,
   is_list(Convert),
   once((sexpr_s2p(Convert,IS), \+ IS=@=Convert)), !,  % Check if Convert is a list and not in predicate form
   must_det_lls((f2p(HeadIs, LazyVars, RetResult, ResultLazy,  IS, Converted))).  % Proceed with the conversion of the predicate form of the list.

f2p(HeadIs,RetResult, ConvertL, Converted) :- fail,
   is_list(ConvertL),
   maplist(f2p_assign(HeadIs),RetResultL,ConvertL, ConvertedL),
   list_to_conjuncts(ConvertedL,Conjs),
   into_x_assign(RetResultL,RetResult,Code),
   combine_code(Conjs,Code,Converted).


f2p(HeadIs,RetResultL, ConvertL, Converted) :- fail,
   is_list(ConvertL),
   ConvertL = [Convert],
   f2p(HeadIs,RetResult,Convert, Code), !,
   into_equals(RetResultL,[RetResult],Equals),
   combine_code(Code,Equals,Converted).


% If any sub-term of Convert is a function, convert that sub-term and then proceed with the conversion.
f2p(HeadIs,RetResult,Convert, Converted) :-
    rev_sub_sterm(AsFunction, Convert),  % Get the deepest sub-term AsFunction of Convert
  %  sub_term_safely(AsFunction, Convert), AsFunction\==Convert,
    callable(AsFunction),  % Check if AsFunction is callable
    compile_flow_control(HeadIs,Result,AsFunction, AsPred),
    HeadIs\=@=AsFunction,!,
    subst(Convert, AsFunction, Result, Converting),  % Substitute AsFunction by Result in Convert
    f2p(HeadIs,RetResult,(AsPred,Converting), Converted).  % Proceed with the conversion of the remaining terms

% If any sub-term of Convert is a function, convert that sub-term and then proceed with the conversion.
f2p(HeadIs,RetResult,Convert, Converted) :-
    rev_sub_sterm(AsFunction, Convert),  % Get the deepest sub-term AsFunction of Convert
    callable(AsFunction),  % Check if AsFunction is callable
    is_function(AsFunction, Nth),  % Check if AsFunction is a function and get the position Nth where the result is stored/retrieved
    HeadIs\=@=AsFunction,
    funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, Nth, AsPred),  % Convert AsFunction to a predicate AsPred
    subst(Convert, AsFunction, Result, Converting),  % Substitute AsFunction by Result in Convert
    f2p(HeadIs,RetResult, (AsPred, Converting), Converted).  % Proceed with the conversion of the remaining terms

% If AsFunction is a recognized function, convert it to a predicate.
f2p(HeadIs,RetResult,AsFunction,AsPred):- % HeadIs\=@=AsFunction,
   is_function(AsFunction, Nth),  % Check if AsFunction is a recognized function and get the position Nth where the result is stored/retrieved
   funct_with_result_is_nth_of_pred(HeadIs,AsFunction, RetResult, Nth, AsPred),
   \+ ( compound(AsFunction), arg(_,AsFunction, Arg), is_function(Arg,_)),!.

% If any sub-term of Convert is an eval_args/2, convert that sub-term and then proceed with the conversion.
f2p(HeadIs,RetResult,Convert, Converted) :-
    rev_sub_sterm0(ConvertFunction, Convert), % Get the deepest sub-term AsFunction of Convert
    callable(ConvertFunction),  % Check if AsFunction is callable
    ConvertFunction = eval_args(AsFunction,Result),
    ignore(is_function(AsFunction, Nth)),
    funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, Nth, AsPred),  % Convert AsFunction to a predicate AsPred
    subst(Convert, ConvertFunction, Result, Converting),  % Substitute AsFunction by Result in Convert
    f2p(HeadIs,RetResult, (AsPred, Converting), Converted).  % Proceed with the conversion of the remaining terms

/* MAYBE USE ?
% If Convert is a compound term, we need to recursively convert its arguments.
f2p(HeadIs,RetResult, Convert, Converted) :- fail,
    compound(Convert), !,
    Convert =~ [Functor|Args],  % Deconstruct Convert to functor and arguments
    maplist(convert_argument, Args, ConvertedArgs),  % Recursively convert each argument
    Converted =~ [Functor|ConvertedArgs],  % Reconstruct Converted with the converted arguments
    (callable(Converted) -> f2p(HeadIs,RetResult, Converted, _); true).  % If Converted is callable, proceed with its conversion
% Helper predicate to convert an argument of a compound term
convert_argument(Arg, ConvertedArg) :-
    (callable(Arg) -> ftp(_, _, Arg, ConvertedArg); ConvertedArg = Arg).
*/




% This predicate is responsible for converting functions to their equivalent predicates.
% It takes a function 'AsFunction' and determines the predicate 'AsPred' which will be
% equivalent to the given function, placing the result of the function at the 'Nth' position
% of the predicate arguments. The 'Result' will be used to store the result of the 'AsFunction'.
%
% It handles cases where 'AsFunction' is a variable and when it's an atom or a compound term.
% For compound terms, it decomposes them to get the functor and arguments and then reconstructs
% the equivalent predicate with the 'Result' at the 'Nth' position.
%
% Example:
% funct_with_result_is_nth_of_pred(HeadIs,+(1, 2), Result, 3, +(1, 2, Result)).

into_callable(Pred,AsPred):- is_ftVar(Pred),!,AsPred=holds(Pred).
into_callable(Pred,AsPred):- Pred=AsPred,!.
into_callable(Pred,AsPred):- iz_conz(Pred), !,AsPred=holds(Pred).
into_callable(Pred,AsPred):- Pred=call_fr(_,_,_),!,AsPred=Pred.
into_callable(Pred,AsPred):- Pred =~ Cons,  !,AsPred=holds(Cons).

funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, Nth, AsPred):-
  var(AsPred),!,
  funct_with_result_is_nth_of_pred0(HeadIs,AsFunction, Result, Nth, Pred),
  into_callable(Pred,AsPred).

funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, Nth, AsPred):-
  var(AsFunction),!,
  funct_with_result_is_nth_of_pred0(HeadIs,Function, Result, Nth, AsPred),
  into_callable(Function,AsFunction).

funct_with_result_is_nth_of_pred(HeadIs,AsFunction, Result, Nth, AsPred):-
  funct_with_result_is_nth_of_pred0(HeadIs,AsFunction, Result, Nth, AsPred).

% Handles the case where AsFunction is a variable.
% It creates a compound term 'AsPred' and places the 'Result' at the 'Nth' position
% of the predicate arguments, and the 'AsFunction' represents the functional form with
% arguments excluding the result.
funct_with_result_is_nth_of_pred0(_HeadIs,AsFunction, Result, Nth, AsPred) :-
    is_ftVar(AsFunction),!,
   compound(AsPred),
    compound_name_list(AsPred,FP,PredArgs),
    nth1(Nth,PredArgs,Result,FuncArgs),
    do_predicate_function_canonical(FP,F),
    AsFunction =~ [F,FuncArgs].

% Handles the case where 'AsFunction' is not a variable.
% It decomposes 'AsFunction' to get the functor and arguments (FuncArgs) of the function
% and then it constructs the equivalent predicate 'AsPred' with 'Result' at the 'Nth'
% position of the predicate arguments.
funct_with_result_is_nth_of_pred0(HeadIs,AsFunctionO, Result, Nth, (AsPred)) :-
   de_eval(AsFunctionO,AsFunction),!,funct_with_result_is_nth_of_pred0(HeadIs,AsFunction, Result, Nth, AsPred).

funct_with_result_is_nth_of_pred0(HeadIs,AsFunction, Result, _Nth, AsPred) :-
   nonvar(AsFunction),
   compound(AsFunction),
   \+ is_arity_0(AsFunction,_),
   functor_chkd(AsFunction,F,A),
   HeadIs\=@=AsFunction,
   \+ (compound(HeadIs), (is_arity_0(HeadIs,HF);functor_chkd(HeadIs,HF,_))-> HF==F),
   (into_x_assign(AsFunction, Result,AsPred)
       -> true
       ; (AA is A+1,
           (FAA=(F/AA)),
           \+ current_predicate(FAA), !,
           AsPred = call_fr(AsFunction,Result,FAA))).


funct_with_result_is_nth_of_pred0(_HeadIs,AsFunction, Result, Nth, (AsPred)) :-
   (atom(AsFunction)->AsFunction =~ [F | FuncArgs]; compound_name_list(AsFunction,F,FuncArgs)),
   ignore(var(Nth) -> is_function(AsFunction,Nth); true),
    nth1(Nth, PredArgs, Result, FuncArgs), % It places 'Result' at the 'Nth' position
    AA is Nth+1, \+ current_predicate(F/AA),
    do_predicate_function_canonical(FP,F),
    AsPred =~ [FP | PredArgs]. % It forms the predicate 'AsPred' by joining the functor with the modified arguments list.



funct_with_result_is_nth_of_pred0(_HeadIs,AsFunction, Result, Nth, (AsPred)) :-
    nonvar(AsFunction),
    AsFunction =~ [F | FuncArgs],
    do_predicate_function_canonical(FP,F),
    length(FuncArgs, Len),
   ignore(var(Nth) -> is_function(AsFunction,Nth); true),
   ((number(Nth),Nth > Len + 1) -> throw(error(index_out_of_bounds, _)); true),
   (var(Nth)->(between(1,Len,From1),Nth is Len-From1+1);true),
    nth1(Nth,PredArgs,Result,FuncArgs),
    AsPred =~ [FP | PredArgs].

% optionally remove next line
funct_with_result_is_nth_of_pred0(_HeadIs,AsFunction, _, _, _) :-
    var(AsFunction),
    throw(error(instantiation_error, _)).

% The remove_funct_arg/3 predicate is a utility predicate that removes
% the Nth argument from a predicate term, effectively converting a
% predicate to a function. The first argument is the input predicate term,
% the second is the position of the argument to be removed, and the third
% is the output function term.
remove_funct_arg(AsPred, Nth, AsFunction) :-
    % Decompose AsPred into its functor and arguments.
    AsPred =~ [F | PredArgs],
    % Remove the Nth element from PredArgs, getting the list FuncArgs.
    nth1(Nth,PredArgs,_Result,FuncArgs),
    % Construct AsFunction using the functor and the list FuncArgs.
    do_predicate_function_canonical(F,FF),
    compound_name_list(AsFunction,FF,FuncArgs).

% rev_sub_sterm/2 predicate traverses through a given Term
% and finds a sub-term within it. The sub-term is unifiable with ST.
% This is a helper predicate used in conjunction with others to inspect
% and transform terms.

rev_sub_sterm(ST, Term):- rev_sub_sterm0(ST, Term), ST\=@=Term.
rev_sub_sterm0(_, Term):- never_subterm(Term),!,fail.
rev_sub_sterm0(ST, Term):- Term =~ if(Cond,_Then,_Else),!,rev_sub_sterm0(ST, Cond).
rev_sub_sterm0(ST, Term):- Term =~ 'if-error'(Cond,_Then,_Else),!,rev_sub_sterm0(ST, Cond).
rev_sub_sterm0(ST, Term):- Term =~ 'if-decons'(Cond,_Then,_Else),!,rev_sub_sterm0(ST, Cond).
rev_sub_sterm0(ST, Term):- Term =~ 'chain'(Expr,_Var,_Next),!,rev_sub_sterm0(ST, Expr).
rev_sub_sterm0(ST, Term):-
    % If Term is a list, it reverses the list and searches for a member
    % in the reversed list that is unifiable with ST.
    is_list(Term),!,rev_member(E,Term),rev_sub_sterm0(ST, E).
rev_sub_sterm0(ST, Term):-
    % If Term is a compound term, it gets its arguments and then recursively
    % searches in those arguments for a sub-term unifiable with ST.
    compound(Term), compound_name_list(Term,_,Args),rev_sub_sterm0(ST, Args).
rev_sub_sterm0(ST, ST):-
    % If ST is non-var, not an empty list, and callable, it unifies
    % ST with Term if it is unifiable.
    nonvar(ST), ST\==[], callable(ST).

never_subterm(Term):- is_ftVar(Term).
never_subterm([]).
never_subterm('Nil').
%never_subterm(F):- atom(F),not_function(F,0).

% rev_member/2 predicate is a helper predicate used to find a member
% of a list. It is primarily used within rev_sub_sterm/2 to
% traverse through lists and find sub-terms. It traverses the list
% from the end to the beginning, reversing the order of traversal.
rev_member(E,[_|L]):- rev_member(E,L).
rev_member(E,[E|_]).

% Continuing from preds_to_functs/2
% Converts a given predicate representation to its equivalent function representation
preds_to_functs(Convert, Converted):-
  % Verbose_unify/1 here may be used for debugging or to display detailed unification information
  verbose_unify(Convert),
  % Calls the auxiliary predicate preds_to_functs0/2 to perform the actual conversion
  preds_to_functs0(Convert, Converted).

% if Convert is a variable, Converted will be the same variable
preds_to_functs0(Convert, Converted) :-
    is_ftVar(Convert), !,
    Converted = Convert.

% Converts the rule (Head :- Body) to its function equivalent
preds_to_functs0((Head:-Body), Converted) :- !,
  % The rule is converted by transforming Head to a function AsFunction and the Body to ConvertedBody
  (
   pred_to_funct(Head, AsFunction, Result),
   %ignore(Result = '$VAR'('HeadRes')),
   conjuncts_to_list(Body,List),
   reverse(List,RevList),append(Left,[BE|Right],RevList),
   compound(BE),arg(Nth,BE,ArgRes),sub_var_safely(Result,ArgRes),
   remove_funct_arg(BE, Nth, AsBodyFunction),
   append(Left,[eval_args(AsBodyFunction,Result)|Right],NewRevList),
   reverse(NewRevList,NewList),
   list_to_conjuncts(NewList,NewBody),
   preds_to_functs0(NewBody,ConvertedBody),
   % The final Converted term is constructed
   into_equals(AsFunction,ConvertedBody,Converted)).

% Handles the case where Convert is a conjunction, and AsPred is not not_function.
% It converts predicates to functions inside a conjunction
preds_to_functs0((AsPred, Convert), Converted) :-
    \+ not_function(AsPred),
    pred_to_funct(AsPred, AsFunction, Result),
    sub_var_safely(Result, Convert), !,
    % The function equivalent of AsPred _xs Result in Convert
    subst(Convert, Result, AsFunction, Converting),
    preds_to_functs0(Converting, Converted).

% Handles the special case where eval_args/2 is used and returns the function represented by the first argument of eval_args/2
preds_to_functs0(eval_args(AsFunction, _Result), AsFunction) :- !.

% Handles the general case where Convert is a conjunction.
% It converts the predicates to functions inside a conjunction
preds_to_functs0((AsPred, Converting), (AsPred, Converted)) :- !,
    preds_to_functs0(Converting, Converted).

% Handles the case where AsPred is a compound term that can be converted to a function
preds_to_functs0(AsPred, eval_args(AsFunction, Result)) :-
    pred_to_funct(AsPred, AsFunction, Result), !.

% any other term remains unchanged
preds_to_functs0(X, X).

% Converts a given predicate AsPred to its equivalent function term AsFunction
pred_to_funct(AsPred, AsFunction, Result) :-
    compound(AsPred), % Checks if AsPred is a compound term
    functor_chkd(AsPred, F, A), % Retrieves the functor F and arity A of AsPred
    functional_predicate_arg(F, A, Nth),!, % Finds the Nth argument where the result should be
    arg(Nth, AsPred, Result), % Retrieves the result from the Nth argument of AsPred
    remove_funct_arg(AsPred, Nth, AsFunction). % Constructs the function AsFunction by removing the Nth argument from AsPred

% If not found in functional_predicate_arg/3, it tries to construct AsFunction by removing the last argument from AsPred
pred_to_funct(AsPred, AsFunction, Result) :-
    compound(AsPred), !,
    functor_chkd(AsPred, _, Nth),
    arg(Nth, AsPred, Result),
    remove_funct_arg(AsPred, Nth, AsFunction).

% body_member/4 is utility predicate to handle manipulation of body elements in the clause, but the exact implementation details and usage are not provided in the given code.
body_member(Body,BE,NewBE,NewBody):-
   conjuncts_to_list(Body,List),
   reverse(List,RevList),append(Left,[BE|Right],RevList),
   append(Left,[NewBE|Right],NewRevList),
   reverse(NewRevList,NewList),
   list_to_conjuncts(NewList,NewBody).
% combine_clauses/3 is the main predicate combining clauses with similar heads and bodies.
% HeadBodiesList is a list of clauses (Head:-Body)
% NewHead will be the generalized head representing all clauses in HeadBodiesList
% NewCombinedBodies will be the combined bodies of all clauses in HeadBodiesList.
combine_clauses(HeadBodiesList, NewHead, NewCombinedBodies) :-
    % If HeadBodiesList is empty, then NewCombinedBodies is 'false' and NewHead is an anonymous variable.
    (HeadBodiesList = [] -> NewCombinedBodies = false, NewHead = _ ;
    % Find all Heads in HeadBodiesList and collect them in the list Heads
    findall(Head, member((Head:-_), HeadBodiesList), Heads),
    % Find the least general head among the collected Heads
    least_general_head(Heads, LeastHead),
    functor_chkd(LeastHead,F,A),functor_chkd(NewHead,F,A),
    % Transform and combine bodies according to the new head found
    transform_and_combine_bodies(HeadBodiesList, NewHead, NewCombinedBodies)),
    \+ \+ (
     Print=[converting=HeadBodiesList,newHead=NewHead],
     numbervars(Print,0,_,[attvar(skip)]),fbug(Print),
        nop(in_cmt(print_pl_source(( NewHead :- NewCombinedBodies))))),!.

% Predicate to find the least general unified head (LGU) among the given list of heads.
% Heads is a list of head terms, and LeastGeneralHead is the least general term that unifies all terms in Heads.
least_general_head(Heads, LeastGeneralHead) :-
    lgu(Heads, LeastGeneralHead).

% the LGU of a single head is the head itself.
lgu([Head], Head) :- !.
% find the LGU of the head and the rest of the list.
lgu([H1|T], LGU) :-
    lgu(T, TempLGU),
    % Find generalization between head H1 and temporary LGU
    generalization(H1, TempLGU, LGU).

% generalization/3 finds the generalization of two heads, Head1 and Head2, which is represented by GeneralizedHead.
% This predicate is conceptual and will require more complex processing depending on the actual structures of the heads.
generalization(Head1, Head2, GeneralizedHead) :-
    % Ensure the functor names and arities are the same between Head1 and Head2.
    functor_chkd(Head1, Name, Arity),
    functor_chkd(Head2, Name, Arity),
    functor_chkd(GeneralizedHead, Name, Arity),
    % Generalize the arguments of the heads.
    generalize_args(Arity, Head1, Head2, GeneralizedHead).

% no more arguments to generalize.
generalize_args(0, _, _, _) :- !.
% generalize the corresponding arguments of the heads.
generalize_args(N, Head1, Head2, GeneralizedHead) :-
    arg(N, Head1, Arg1),
    arg(N, Head2, Arg2),
    % If the corresponding arguments are equal, use them. Otherwise, create a new variable.
    (Arg1 = Arg2 -> arg(N, GeneralizedHead, Arg1); arg(N, GeneralizedHead, _)),
    % Continue with the next argument.
    N1 is N - 1,
    generalize_args(N1, Head1, Head2, GeneralizedHead).

% transform_and_combine_bodies/3 takes a list of clause heads and bodies, a new head, and produces a combined body representing all the original bodies.
% The new body is created according to the transformations required by the new head.
transform_and_combine_bodies([(Head:-Body)|T], NewHead, CombinedBodies) :-
    % Transform the body according to the new head.
    transform(Head, NewHead, Body, TransformedBody),
    % Combine the transformed body with the rest.
    combine_bodies(T, NewHead, TransformedBody, CombinedBodies).

/* OLD
% Define predicate combine_clauses to merge multiple Prolog clauses with the same head.
% It receives a list of clauses as input and returns a combined clause.
combine_clauses([Clause], Clause) :- !.  % If there's only one clause, return it as is.
combine_clauses(Clauses, (Head :- Body)) :-  % If there are multiple clauses, combine them.
    Clauses = [(Head :- FirstBody)|RestClauses],  % Decompose the list into the first clause and the rest.
    combine_bodies(RestClauses, FirstBody, Body).  % Combine the bodies of all the clauses.

% Helper predicate to combine the bodies of a list of clauses.
% The base case is when there are no more clauses to combine; the combined body is the current body.
combine_bodies([], Body, Body).
combine_bodies([(Head :- CurrentBody)|RestClauses], PrevBody, Body) :-
    % Combine the current body with the previous body using a conjunction (,).
    combine_two_bodies(PrevBody, CurrentBody, CombinedBody),
    % Recursively combine the rest of the bodies.
    combine_bodies(RestClauses, CombinedBody, Body).

% Predicate to combine two bodies.
% Handles the combination of different Prolog constructs like conjunctions, disjunctions, etc.
combine_two_bodies((A, B), (C, D), (A, B, C, D)) :- !.  % Combine conjunctions.
combine_two_bodies((A; B), (C; D), (A; B; C; D)) :- !.  % Combine disjunctions.
combine_two_bodies(A, B, (A, B)).  % Combine simple terms using conjunction.
*/

% if there are no more bodies, the accumulated Combined is the final CombinedBodies.
combine_bodies([], _, Combined, Combined).
% combine the transformed body with the accumulated bodies.
combine_bodies([(Head:-Body)|T], NewHead, Acc, CombinedBodies) :-
    transform(Head, NewHead, Body, TransformedBody),
    % Create a disjunction between the accumulated bodies and the transformed body.
    NewAcc = (Acc;TransformedBody),
    combine_bodies(T, NewHead, NewAcc, CombinedBodies).

% combine_code/3 combines Guard and Body to produce either Guard, Body, or a conjunction of both, depending on the values of Guard and Body.
combine_code(Guard, Body, Guard) :- Body==true, !.
combine_code(Guard, Body, Body) :- Guard==true, !.
combine_code(Guard, Body, (Guard, Body)).

% create_unifier/3 creates a unification code that unifies OneHead with NewHead.
% If OneHead and NewHead are structurally equal, then they are unified and the unification Guard is 'true'.
% Otherwise, the unification code is 'metta_unify(OneHead,NewHead)'.

create_unifier(OneHead,NewHead,Guard):- OneHead=@=NewHead,OneHead=NewHead,!,Guard=true.
create_unifier(OneHead,NewHead,Guard):- compound(OneHead),
  compound_name_list(OneHead,_,Args1),
  compound_name_list(NewHead,_,Args2),
  create_unifier_goals(Args1,Args2,Guard),!.
create_unifier(OneHead,NewHead,u(OneHead,NewHead)).

create_unifier_goals([V1],[V2],u(V1,V2)):-!.
create_unifier_goals([V1|Args1],[V2|Args2],RightGuard):-!,
  create_unifier_goals(Args1,Args2,Guard),
  combine_code(u(V1,V2),Guard,RightGuard).
create_unifier_goals([],[],true).


% transform/4 combines unification code with Body to produce NewBody according to the transformations required by NewHead.
% It uses create_unifier/3 to generate the unification code between OneHead and NewHead.
transform(OneHead, NewHead, Body, NewBody):- create_unifier(OneHead,NewHead,Guard),
   combine_code(Guard,Body,NewBody).



compile_for_assert_eq(_Eq,H,B,Result):-
  compile_for_assert(H,B,Result), !.

:- dynamic(metta_compiled_predicate/3).

same(X,Y):- X =~ Y.










