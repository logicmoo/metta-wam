:- encoding(iso_latin_1).
:- flush_output.
:- setenv('RUST_BACKTRACE',full).
%:- '$set_source_module'('user').
/*
# Core in Rust
In the original version, the core logic and functionalities of the MeTTa system are implemented in Rust. Rust is known for its performance and safety features, making it a suitable choice for building robust, high-performance systems.

# Python Extensions
Python is used to extend or customize MeTTa. Typically, Python interacts with the Rust core through a Foreign Function Interface (FFI) or similar bridging mechanisms. This allows Python programmers to write code that can interact with the lower-level Rust code, while taking advantage of Python's ease of use and rich ecosystem.

# Prolog Allows Python Extensions
Just like the Rust core allowed for Python extensions, the Prolog code also permits Python and Rust developers (thru python right now) to extend or customize parts of MeTTa. This maintains the system?s extensibility and allows users who are more comfortable with Python to continue working with the system effectively.

*/


:- use_module(library(janus)).
:- use_module(library(filesex)).

:- multifile(is_python_space/1).
:- dynamic(is_python_space/1).
:- volatile(is_python_space/1).

is_rust_space(GSpace):- is_python_space(GSpace).

is_not_prolog_space(GSpace):-  is_rust_space(GSpace), !.
is_not_prolog_space(GSpace):-  \+ is_asserted_space(GSpace), \+ is_nb_space(GSpace), !.

with_safe_argv(Goal):-
  current_prolog_flag(argv,Was),
  setup_call_cleanup(set_prolog_flag(argv,[]),Goal,set_prolog_flag(argv,Was)).

ensure_space_py(Space,GSpace):- py_is_object(Space),!,GSpace=Space.
ensure_space_py(Space,GSpace):- var(Space),ensure_primary_metta_space(GSpace), Space=GSpace.
ensure_space_py(metta_self,GSpace):- ensure_primary_metta_space(GSpace),!.

:- dynamic(is_metta/1).
:- volatile(is_metta/1).
ensure_rust_metta(MeTTa):- is_metta(MeTTa),!.
ensure_rust_metta(MeTTa):-
   with_safe_argv(py_call(hyperon:'MeTTa'(),MeTTa)),
   asserta(is_metta(MeTTa)).

ensure_rust_metta:- ensure_rust_metta(_).

:- dynamic(is_metta_learner/1).
:- volatile(is_metta_learner/1).
ensure_metta_learner(Metta_Learner):- is_metta_learner(Metta_Learner),!.
ensure_metta_learner(Metta_Learner):-
   with_safe_argv(py_call(metta_vspace:'metta_learner':'MettaLearner'(),Metta_Learner)),
   asserta(is_metta_learner(Metta_Learner)).


:- multifile(space_type_method/3).
:- dynamic(space_type_method/3).
space_type_method(is_not_prolog_space,new_space,new_rust_space).
space_type_method(is_not_prolog_space,add_atom,add_to_space).
space_type_method(is_not_prolog_space,remove_atom,remove_from_space).
space_type_method(is_not_prolog_space,replace_atom,replace_in_space).
space_type_method(is_not_prolog_space,atom_count,atom_count_from_space).
space_type_method(is_not_prolog_space,get_atoms,query_from_space).
space_type_method(is_not_prolog_space,atom_iter,atoms_iter_from_space).
space_type_method(is_not_prolog_space,query,query_from_space).

:- dynamic(is_primary_metta_space/1).
:- volatile(is_primary_metta_space/1).
% Initialize a new hyperon.base.GroundingSpace and get a reference
ensure_primary_metta_space(GSpace) :- is_primary_metta_space(GSpace),!.
ensure_primary_metta_space(GSpace) :- ensure_rust_metta(MeTTa),
   with_safe_argv(py_call(MeTTa:space(),GSpace)),
    asserta(is_primary_metta_space(GSpace)).
ensure_primary_metta_space(GSpace) :- new_rust_space(GSpace).
ensure_primary_metta_space:- ensure_primary_metta_space(_).

:- if( \+ current_predicate(new_rust_space/1 )).
% Initialize a new hyperon.base.GroundingSpace and get a reference
new_rust_space(GSpace) :-
    with_safe_argv(py_call(hyperon:base:'GroundingSpace'(), GSpace)),
    asserta(is_python_space(GSpace)).
:- endif.

:- if( \+ current_predicate(query_from_space/3 )).
% Query from hyperon.base.GroundingSpace
query_from_space(Space, QueryAtom, Result) :-
    ensure_space(Space,GSpace),
    py_call(GSpace:'query'(QueryAtom), Result).


% Replace an atom in hyperon.base.GroundingSpace
replace_in_space(Space, FromAtom, ToAtom) :-
    ensure_space(Space,GSpace),
    py_call(GSpace:'replace'(FromAtom, ToAtom), _).

% Get the atom count from hyperon.base.GroundingSpace
atom_count_from_space(Space, Count) :-
    ensure_space(Space,GSpace),
    py_call(GSpace:'atom_count'(), Count).

% Get the atoms from hyperon.base.GroundingSpace
atoms_from_space(Space, Atoms) :-
    ensure_space(Space,GSpace),
    py_call(GSpace:'get_atoms'(), Atoms).

atom_from_space(Space, Sym):-
   atoms_iter_from_space(Space, Atoms),elements(Atoms,Sym).

% Get the atom iterator from hyperon.base.GroundingSpace
atoms_iter_from_space(Space, Atoms) :-
    ensure_space(Space,GSpace),
    with_safe_argv(py_call(metta_vspace:'metta_learner':get_atoms_iter_from_space(GSpace),Atoms)),
    %py_call(GSpace:'atoms_iter'(), Atoms).
    true.
:- endif.

py_to_pl(I,O):- py_to_pl(_,I,O).
py_to_pl(VL,I,O):- ignore(VL=[vars]), py_to_pl(VL,[],[],_,I,O),!.
is_var_or_nil(I):- var(I),!.
is_var_or_nil([]).
%py_to_pl(VL,Par,_Cir,_,L,_):- wdmsg(py_to_pl(VL,Par,L)),fail.
py_to_pl(_VL,_Par,Cir,Cir,L,E):- var(L),!,E=L.
py_to_pl(_VL,_Par,Cir,Cir,L,E):- L ==[],!,E=L.
py_to_pl(_VL,_Par,Cir,Cir,L,E):- member(N-NE,Cir), N==L, !, (E=L;NE=E), !.
py_to_pl(_VL,_Par,Cir,Cir, LORV:_B:_C,LORV):- is_var_or_nil(LORV),  !.
py_to_pl(VL,Par,Cir,CirO,[H|T]:B:C,[HH|TT]):-  py_to_pl(VL,Par,Cir,CirM,H:B:C,HH), py_to_pl(VL,Par,CirM,CirO,T:B:C,TT).
py_to_pl(_VL,_Par,Cir,Cir, LORV:_B,LORV):- is_var_or_nil(LORV),  !.
py_to_pl(VL,Par,Cir,CirO,[H|T]:B,[HH|TT]):-  py_to_pl(VL,Par,Cir,CirM,H:B,HH), py_to_pl(VL,Par,CirM,CirO,T:B,TT).
py_to_pl(VL,Par,Cir,CirO,A:B:C,AB):-  py_is_object(A),callable(B),py_call(A:B,R),py_to_pl(VL,Par,Cir,CirO,R:C,AB).
py_to_pl(VL,Par,Cir,CirO,A:B,AB):-  py_is_object(A),callable(B),py_call(A:B,R),py_to_pl(VL,Par,Cir,CirO,R,AB).
py_to_pl(VL,Par,Cir,CirO,A:B,AA:BB):-  !, py_to_pl(VL,Par,Cir,CirM,A,AA),py_to_pl(VL,Par,CirM,CirO,B,BB).
py_to_pl(VL,Par,Cir,CirO,A-B,AA-BB):- !, py_to_pl(VL,Par,Cir,CirM,A,AA),py_to_pl(VL,Par,CirM,CirO,B,BB).
py_to_pl(_VL,_Par,Cir,Cir,L,E):- atom(L),!,E=L.
py_to_pl(VL,Par,Cir,CirO,[H|T],[HH|TT]):- !, py_to_pl(VL,Par,Cir,CirM,H,HH), py_to_pl(VL,Par,CirM,CirO,T,TT).
py_to_pl(VL,Par,Cir,CirO,O,E):- py_is_object(O),py_class(O,Cl),!,pyo_to_pl(VL,Par,[O=E|Cir],CirO,Cl,O,E).
py_to_pl(VL,Par,Cir,CirO,L,E):- is_dict(L,F),!,dict_pair(L,F,NV),!,py_to_pl(VL,Par,Cir,CirO,NV,NVL),dict_pair(E,F,NVL).
py_to_pl(_VL,_Par,Cir,Cir,L,E):- \+ callable(L),!,E=L.
%py_to_pl(VL,Par,Cir,CirO,A:B:C,AB):-  py_is_object(A),callable(B),py_call(A:B,R),!, py_to_pl(VL,Par,[A:B-AB|Cir],CirO,R:C,AB).
%py_to_pl(VL,Par,Cir,CirO,A:B,AB):-  py_is_object(A),callable(B),py_call(A:B,R),!, py_to_pl(VL,Par,[A:B-AB|Cir],CirO,R,AB).
py_to_pl(VL,Par,Cir,CirO,A,AA):- compound(A),!,compound_name_arguments(A,F,L),py_to_pl(VL,Par,Cir,CirO,L,LL),compound_name_arguments(AA,F,LL).
py_to_pl(_VL,_Par,Cir,Cir,E,E).
/*
varname_to_real_var(RL,E):- upcase_atom(RL,R),varname_to_real_var0(R,E).
varname_to_real_var0(R,E):- nb_current('cvariable_names',VL),!,varname_to_real_var0(R,VL,E).
varname_to_real_var0(R,E):- nb_setval('cvariable_names',[R=v(_)]),!,varname_to_real_var0(R,E).
varname_to_real_var0(R,[],E):- nb_setval('cvariable_names',[R=v(_)]),!,varname_to_real_var0(R,E).
varname_to_real_var0(R,VL,E):- member(N=V,VL), N==R,!,arg(1,V,E).
varname_to_real_var0(R,VL,E):- extend_container(VL,R=v(_)),varname_to_real_var0(R,E).*/
% Predicate to extend the list inside the container
extend_container(Container, Element) :-
    arg(2, Container, List),
    nb_setarg(2, Container, [Element|List]).

rinto_varname(R,RN):- atom_number(R,N),atom_concat('Num',N,RN).
rinto_varname(R,RN):- upcase_atom(R,RN).
real_VL_var(RL,VL,E):- nonvar(RL), !, rinto_varname(RL,R),!,real_VL_var0(R,VL,E).
real_VL_var(RL,VL,E):- member(N=V,VL), V==E,!,RL=N.
real_VL_var(RL,VL,E):- compound(E),E='$VAR'(RL),ignore(real_VL_var0(RL,VL,E)),!.
real_VL_var(RL,VL,E):- format(atom(RL),'~p',[E]), member(N=V,VL), N==RL,!,V=E.
real_VL_var(RL,VL,E):- format(atom(RL),'~p',[E]), real_VL_var0(RL,VL,E).
real_VL_var0(R,VL,E):- member(N=V,VL), N==R,!,V=E.
real_VL_var0(R,VL,E):- extend_container(VL,R=E),!. % ,E='$VAR'(R).

pyo_to_pl(VL,_Par,Cir,Cir,Cl,O,E):- Cl=='VariableAtom', !, py_call(O:get_name(),R), real_VL_var(R,VL,E),!.
pyo_to_pl(VL,Par,Cir,CirO,Cl,O,E):- class_to_pl1(Par,Cl,M),py_member_values(O,M,R), !, py_to_pl(VL,[Cl|Par],Cir,CirO,R,E).
pyo_to_pl(VL,Par,Cir,CirO,Cl,O,E):- class_to_pl(Par,Cl,M), % wdmsg(class_to_pl(Par,Cl,M)),
   py_member_values(O,M,R), !, py_to_pl(VL,[Cl|Par],Cir,CirO,R,E).
pyo_to_pl(VL,Par,Cir,CirO,Cl,O,E):- catch(py_obj_dir(O,L),_,fail),wdmsg(py_obj_dir(O,L)),py_decomp(M),meets_dir(L,M),wdmsg(py_decomp(M)),
  py_member_values(O,M,R), member(N-_,Cir), R\==N, !, py_to_pl(VL,[Cl|Par],Cir,CirO,R,E),!.

pl_to_py(Var,Py):- pl_to_py(_VL,Var,Py).
pl_to_py(VL,Var,Py):- var(VL),!,ignore(VL=[vars]),pl_to_py(VL,Var,Py).
pl_to_py(_VL,Sym,Py):- is_list(Sym),!, maplist(pl_to_py,Sym,PyL), py_call(metta_vspace:'metta_learner':'MkExpr'(PyL),Py),!.
pl_to_py(VL,Var,Py):- var(Var), !, real_VL_var(Sym,VL,Var), py_call('hyperon.atoms':'V'(Sym),Py),!.
pl_to_py(VL,'$VAR'(Sym),Py):- !, real_VL_var(Sym,VL,_),py_call('hyperon.atoms':'V'(Sym),Py),!.
pl_to_py(VL,DSym,Py):- atom(DSym),atom_concat('$',VName,DSym), rinto_varname(VName,Sym),!, pl_to_py(VL,'$VAR'(Sym),Py).
pl_to_py(_VL,Sym,Py):- atom(Sym),!, py_call('hyperon.atoms':'S'(Sym),Py),!.
pl_to_py(_VL,Sym,Py):- string(Sym),!, py_call('hyperon.atoms':'S'(Sym),Py),!.
%pl_to_py(VL,Sym,Py):- is_list(Sym), maplist(pl_to_py,Sym,PyL), py_call('hyperon.atoms':'E'(PyL),Py),!.
pl_to_py(_VL,Sym,Py):- py_is_object(Sym),py_call('hyperon.atoms':'ValueAtom'(Sym),Py),!.
pl_to_py(_VL,Sym,Py):- py_call('hyperon.atoms':'ValueAtom'(Sym),Py),!.

%elements(Atoms,E):- is_list(Atoms),!,
meets_dir(L,M):- atom(M),!,member(M,L),!.
meets_dir(L,M):- is_list(M),!,maplist(meets_dir(L),M).
meets_dir(L,M):- compound_name_arity(M,N,0),!,member(N,L),!.
meets_dir(L,M):- compound(M),!,compound_name_arguments(M,F,[A|AL]),!,maplist(meets_dir(L),[F,A|AL]).

py_member_values(O,C,R):- is_list(O),!,maplist(py_member_values,O,C,R).
py_member_values(O,C,R):- is_list(C),!,maplist(py_member_values(O),C,R).
%py_member_values(O,C,R):- atom(C),!,compound_name_arity(CC,C,0),!,py_call(O:CC,R).
py_member_values(O,f(F,AL),R):- !,py_member_values(O,[F|AL],[RF|RAL]), compound_name_arguments(R,RF,RAL).
py_member_values(O,C,R):- py_call(O:C,R,[py_string_as(atom),py_object(false)]).

py_to_str(PyObj,Str):-
   with_output_to(string(Str),py_pp(PyObj,[nl(false)])).

 tafs:-
    atoms_from_space(Space, _),py_to_pl(VL,Space,AA), print_tree(aa(Pl,aa)),pl_to_py(VL,AA,Py), print_tree(py(Pl,py)),pl_to_py(VL,Py,Pl),print_tree(pl(Pl,pl))
    ,
    atoms_from_space(Space, [A]),py_to_pl(VL,A,AA),
    atoms_from_space(Space, [A]),py_obj_dir(A,D),writeq(D),!,py_to_pl(VL,D:get_object(),AA),writeq(AA),!,fail.

py_class(A,AA):- py_call(A:'__class__',C), py_call(C:'__name__',AA,[py_string_as(atom)]),!.
py_decomp(M,C):- py_decomp(M), compound_name_arity(C,M,0).


class_to_pl1(_Par,'GroundingSpaceRef',get_atoms()).
class_to_pl1(_Par,'ExpressionAtom',get_children()).
class_to_pl1(_Par,'SpaceRef',get_atoms()).
class_to_pl1(_Par,'VariableAtom','__repr__'()).
class_to_pl1(_Par,'SymbolAtom',get_name()).
class_to_pl1(_Par,'bool','__repr__'()).
class_to_pl(_Par,'ValueAtom','__repr__'()).
class_to_pl(_Par,'ValueObject','value').
class_to_pl(Par,'GroundedAtom','__repr__'()):- length(Par,Len),Len>=5,!.
class_to_pl(Par,_,'__str__'()):- length(Par,Len),Len>15,!.
class_to_pl(_Par,'GroundedAtom',get_object()).

/*


class_to_pl(Par,'bool','__repr__'()).

*/
py_decomp('__repr__'()).
py_decomp('__str__'()).
py_decomp(get_atoms()).
py_decomp(get_children()).
py_decomp(get_object()).
py_decomp(get_name()).
py_decomp(value()).

py_decomp('__class__':'__name__').
%py_decomp(f(get_grounded_type(),['__str__'()])).
py_decomp(f('__class__',['__str__'()])).
%__class__
%get_type()

%atoms_from_space(Space, [Atoms]),py_pp(Atoms),py_call(Atoms:get_object(),A),atoms_from_space(A,Dir),member(E,Dir),py_obj_dir(E,C),py_call(E:get_children(),CH),py_pp(CH).


% Remove an atom from hyperon.base.GroundingSpace
:- if( \+ current_predicate(remove_from_space/2 )).
remove_from_space(Space, Sym) :-
    ensure_space(Space,GSpace),
    py_call(GSpace:'remove'(Sym), _).
:- endif.

% Add an atom to hyperon.base.GroundingSpace
:- if( \+ current_predicate(add_to_space/2 )).
add_to_space(Space, Sym) :-
    ensure_space(Space,GSpace),
    py_call(GSpace:'add'(Sym), _).
:- endif.


'extend-py!'(Module,_):-
  with_safe_argv((
  %listing(ensure_rust_metta/1),
  ensure_metta_learner,
  wdmsg('extend-py!'(Module)),
  ensure_rust_metta(MeTTa),
  replace_in_string(["/"="."],Module,ToPython),
  py_call(MeTTa:load_py_module(ToPython),Result),
  wdmsg(result(MeTTa->Result)))),!.

ensure_metta_learner:-
  with_safe_argv(ensure_metta_learner(Learner)),
  wdmsg(ensure_metta_learner(Learner)).

% Example usage
example_usage :-
    with_safe_argv(ensure_primary_metta_space(GSpace)),
    %some_query(Query),
    Query = [],
    with_safe_argv(query_from_space(GSpace, Query , Result)),
    writeln(Result).

%atoms_from_space(Sym):-  atoms_iter_from_space(metta_self, Atoms),py_iter(Atoms,Sym).
atom_count_from_space(Count):-  atom_count_from_space(metta_self, Count).


%:- .
%:- ensure_rust_metta.
%:- with_safe_argv(ensure_primary_metta_space(_GSpace)).
/*
Rust: The core of MeTTa is implemented in Rust, which provides performance and safety features.

Python Extensions: Python is used for extending the core functionalities. Python communicates with Rust via a Foreign Function Interface (FFI) or similar mechanisms.

Prolog: The Prolog code is an additional layer that allows you to extend or customize parts of MeTTa using Python and Rust. It maintains the system's extensibility.


VSpace is a space with its backend in Prolog, it implies that you're using Prolog's logic programming capabilities to manage and manipulate a particular domain, which in this context is referred to as a "space" (possibly akin to the GroundingSpace in Python, but implemented in Prolog).

To integrate VSpace with the existing Python and Rust components, similar interfacing techniques could be used. You could expose Prolog predicates as functions that can be called from Python or Rust, and likewise, call Python or Rust functions from within Prolog.


*/

%:- ensure_loaded(metta_interp).
on_restore1:- ensure_metta_learner.

:- dynamic(want_py_lib_dir/1).
:- prolog_load_context(directory, ChildDir),
   file_directory_name(ChildDir, ParentDir),
   file_directory_name(ParentDir, GParentDir),
   assert(want_py_lib_dir(GParentDir)).

want_py_lib_dir:-
   with_safe_argv(forall(want_py_lib_dir(GParentDir),  py_add_lib_dir(GParentDir))).

%:- initialization(on_restore1,restore).
%:- initialization(on_restore2,restore).
