
(: unify (-> Atom Atom Atom Atom %Undefined%))
(: if (-> Bool Atom Atom $t#330))
(: quote (-> Atom Atom))
(: Error (-> Atom Atom ErrorType))
(: empty (-> %Undefined%))
(: get-atoms (-> Space Atom))
(: add-atom (-> Space Atom (->)))
(: remove-atom (-> Space Atom (->)))
(: add-atom (-> Space Atom (->)))

;`$then`, `$else` should be of `Atom` type to avoid evaluation
; and infinite cycle in inference
(: if (-> Bool Atom Atom $t))
(= (if True $then $else) $then)
(= (if False $then $else) $else)

(: Error (-> Atom Atom ErrorType))

(= (if-non-empty-expression $atom $then $else)
  (chain (eval (get-metatype $atom)) $type
    (eval (if-equal $type Expression
      (eval (if-equal $atom () $else $then))
      $else ))))

(= (if-decons $atom $head $tail $then $else)
  (eval (if-non-empty-expression $atom
    (chain (decons $atom) $list
      (match $list ($head $tail) $then $else) )
    $else )))

(= (if-empty $atom $then $else)
  (eval (if-equal $atom Empty $then $else)))

(= (if-error $atom $then $else)
  (eval (if-decons $atom $head $_
    (eval (if-equal $head Error $then $else))
    $else )))

(= (return-on-error $atom $then)
  (eval (if-empty $atom Empty
    (eval (if-error $atom $atom
      $then )))))

(= (car $atom)
  (eval (if-decons $atom $head $_
    $head
    (Error (car $atom) "car expects a non-empty expression as an argument") )))

(= (switch $atom $cases)
  (chain (decons $cases) $list (eval (switch-internal $atom $list))))

(= (switch-internal $atom (($pattern $template) $tail))
  (match $atom $pattern $template (eval (switch $atom $tail))))

(= (subst $atom $var $templ)
  (match $atom $var $templ
    (Error (subst $atom $var $templ)
      "subst expects a variable as a second argument") ))

(= (reduce $atom $var $templ)
  (chain (eval $atom) $res
    (eval (if-error $res $res
      (eval (if-empty $res
        (eval (subst $atom $var $templ))
        (eval (reduce $res $var $templ)) ))))))

(= (type-cast $atom $type $space)
  (chain (eval (get-type $atom $space)) $actual-type
    (eval (switch ($actual-type $type)
      (
        ((%Undefined% $_) $atom)
        (($_ %Undefined%) $atom)
        (($type $_) $atom)
        ($_ (Error $atom BadType)) )))))

(= (is-function $type)
  (chain (eval (get-metatype $type)) $meta
    (eval (switch ($type $meta)
      (
        (($_ Expression)
          (chain (eval (car $type)) $head
            (match $head -> True False) ))
        ($_ False) )))))

(= (interpret $atom $type $space)
  (chain (eval (get-metatype $atom)) $meta
    (eval (switch ($type $meta)
      (
        ((Atom $_meta) $atom)
        (($meta $meta) $atom)
        (($_type Variable) $atom)

        (($_type Symbol) (eval (type-cast $atom $type $space)))
        (($_type Grounded) (eval (type-cast $atom $type $space)))
        (($_type Expression) (eval (interpret-expression $atom $type $space))) )))))

(= (interpret-expression $atom $type $space)
  (eval (if-decons $atom $op $args
    (chain (eval (get-type $op $space)) $op-type
      (chain (eval (is-function $op-type)) $is-func
        (match $is-func True
          (chain (eval (interpret-func $atom $op-type $space)) $reduced-atom
            (eval (call $reduced-atom $type $space)) )
          (chain (eval (interpret-tuple $atom $space)) $reduced-atom
            (eval (call $reduced-atom $type $space)) ))))
    (eval (type-cast $atom $type $space)) )))

(= (interpret-func $expr $type $space)
  (eval (if-decons $expr $op $args
    (chain (eval (interpret $op $type $space)) $reduced-op
      (eval (return-on-error $reduced-op
        (eval (if-decons $type $arrow $arg-types
          (chain (eval (interpret-args $expr $args $arg-types $space)) $reduced-args
            (eval (return-on-error $reduced-args
              (cons $reduced-op $reduced-args) )))
          (Error $type "Function type expected") )))))
    (Error $expr "Non-empty expression atom is expected") )))

(= (interpret-args $atom $args $arg-types $space)
  (match $args ()
    (match $arg-types ($ret) () (Error $atom BadType))
    (eval (if-decons $args $head $tail
      (eval (if-decons $arg-types $head-type $tail-types
        (chain (eval (interpret $head $head-type $space)) $reduced-head
          ; check that head was changed otherwise Error or Empty in the head
          ; can be just an argument which is passed by intention
          (eval (if-equal $reduced-head $head
            (eval (interpret-args-tail $atom $reduced-head $tail $tail-types $space))
            (eval (return-on-error $reduced-head
              (eval (interpret-args-tail $atom $reduced-head $tail $tail-types $space)) )))))
        (Error $atom BadType) ))
      (Error (interpret-atom $atom $args $arg-types $space)
        "Non-empty expression atom is expected") ))))

(= (interpret-args-tail $atom $head $args-tail $args-tail-types $space)
  (chain (eval (interpret-args $atom $args-tail $args-tail-types $space)) $reduced-tail
    (eval (return-on-error $reduced-tail
      (cons $head $reduced-tail) ))))

(= (interpret-tuple $atom $space)
  (match $atom ()
    $atom
    (eval (if-decons $atom $head $tail
      (chain (eval (interpret $head %Undefined% $space)) $rhead
        (chain (eval (interpret-tuple $tail $space)) $rtail
          (cons $rhead $rtail) ))
      (Error (interpret-tuple $atom $space) "Non-empty expression atom is expected as an argument") ))))

(= (call $atom $type $space)
  (chain (eval $atom) $result
    (eval (if-empty $result $atom
      (eval (if-error $result $result
        (eval (interpret $result $type $space)) ))))))

(: ErrorType Type)
(: Error (-> Atom Atom ErrorType))
(: ReturnType Type)
(: return (-> Atom ReturnType))

(: function (-> Atom Atom))
(: eval (-> Atom Atom))
(: chain (-> Atom Variable Atom Atom))
(: unify (-> Atom Atom Atom Atom Atom))
(: cons (-> Atom Atom Atom))
(: decons (-> Atom Atom))

(: id (-> Atom Atom))
(= (id $x) $x)

(: apply (-> Atom Variable Atom Atom))
(= (apply $atom $var $templ)
  (function (chain (eval (id $atom)) $var (return $templ))) )

(: if-non-empty-expression (-> Atom Atom Atom Atom))
(= (if-non-empty-expression $atom $then $else)
  (function (chain (eval (get-metatype $atom)) $type
    (eval (if-equal $type Expression
      (eval (if-equal $atom () (return $else) (return $then)))
      (return $else) )))))

(: if-decons (-> Atom Variable Variable Atom Atom Atom))
(= (if-decons $atom $head $tail $then $else)
  (function (eval (if-non-empty-expression $atom
    (chain (decons $atom) $list
      (unify $list ($head $tail) (return $then) (return $else)) )
    (return $else) ))))

(: if-empty (-> Atom Atom Atom Atom))
(= (if-empty $atom $then $else)
  (function (eval (if-equal $atom Empty (return $then) (return $else)))) )

(: if-not-reducible (-> Atom Atom Atom Atom))
(= (if-not-reducible $atom $then $else)
  (function (eval (if-equal $atom NotReducible (return $then) (return $else)))) )

(: if-error (-> Atom Atom Atom Atom))
(= (if-error $atom $then $else)
  (function (eval (if-decons $atom $head $_
    (eval (if-equal $head Error (return $then) (return $else)))
    (return $else) ))))

(: return-on-error (-> Atom Atom Atom))
(= (return-on-error $atom $then)
  (function (eval (if-empty $atom (return (return Empty))
    (eval (if-error $atom (return (return $atom))
      (return $then) ))))))

(: switch (-> %Undefined% Expression Atom))
(= (switch $atom $cases)
  (function (chain (decons $cases) $list
    (chain (eval (switch-internal $atom $list)) $res
      (chain (eval (if-not-reducible $res Empty $res)) $x (return $x)) ))))

(= (switch-internal $atom (($pattern $template) $tail))
  (function (unify $atom $pattern
    (return $template)
    (chain (eval (switch $atom $tail)) $ret (return $ret)) )))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MeTTa interpreter implementation ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(= (match-types $type1 $type2 $then $else)
  (function (eval (if-equal $type1 %Undefined%
    (return $then)
    (eval (if-equal $type2 %Undefined%
      (return $then)
      (eval (if-equal $type1 Atom
        (return $then)
        (eval (if-equal $type2 Atom
          (return $then)
          (unify $type1 $type2 (return $then) (return $else)) ))))))))))

(= (type-cast $atom $type $space)
  (function (chain (eval (get-metatype $atom)) $meta
    (eval (if-equal $type $meta
      (return $atom)
      ; TODO: the proper way to get types is something like
      ; `(collapse (get-type <atom> <space>))` but it leads to the infinite
      ; recursion because interpreter called by `collapse` evaluates
      ; `type-cast` again.
      (chain (eval (collapse-get-type $atom $space)) $actual-types
        (chain (eval (foldl-atom $actual-types False
          $a $b (chain (eval (match-types $b $type True False)) $is-b-comp
            (chain (eval (or $a $is-b-comp)) $or $or) ))) $is-some-comp
          (eval (if $is-some-comp
            (return $atom)
            (return (Error $atom BadType)) )))))))))


(= (is-function $type)
  (function (chain (eval (get-metatype $type)) $meta
    (eval (switch ($type $meta) (
      (($_ Expression)
        (eval (if-decons $type $head $_tail
          (unify $head -> (return True) (return False))
          (return (Error (is-function $type) "is-function non-empty expression as an argument")) )))
      ($_ (return False))
    ))))))

(: filter-atom (-> Expression Variable Atom Expression))
(= (filter-atom $list $var $filter)
  (function (eval (if-decons $list $head $tail
    (chain (eval (filter-atom $tail $var $filter)) $tail-filtered
      (chain (eval (apply $head $var $filter)) $filter-expr
        (chain $filter-expr $is-filtered
          (eval (if $is-filtered
            (chain (cons $head $tail-filtered) $res (return $res))
            (return $tail-filtered) )))))
    (return ()) ))))

(: map-atom (-> Expression Variable Atom Expression))
(= (map-atom $list $var $map)
  (function (eval (if-decons $list $head $tail
    (chain (eval (map-atom $tail $var $map)) $tail-mapped
      (chain (eval (apply $head $var $map)) $map-expr
        (chain $map-expr $head-mapped
          (chain (cons $head-mapped $tail-mapped) $res (return $res)) )))
    (return ()) ))))

(: foldl-atom (-> Expression Atom Variable Variable Atom Atom))
(= (foldl-atom $list $init $a $b $op)
  (function (eval (if-decons $list $head $tail
    (chain (eval (apply $init $a $op)) $op-init
      (chain (eval (apply $head $b $op-init)) $op-head
        (chain $op-head $head-folded
          (chain (eval (foldl-atom $tail $head-folded $a $b $op)) $res (return $res)) )))
    (return $init) ))))

(= (interpret $atom $type $space)
  (function (chain (eval (get-metatype $atom)) $meta
    (eval (if-equal $type Atom
      (return $atom)
      (eval (if-equal $type $meta
        (return $atom)
        (eval (switch ($type $meta) (
          (($_type Variable) (return $atom))
          (($_type Symbol)
            (chain (eval (type-cast $atom $type $space)) $ret (return $ret)))
          (($_type Grounded)
            (chain (eval (type-cast $atom $type $space)) $ret (return $ret)))
          (($_type Expression)
            (chain (eval (interpret-expression $atom $type $space)) $ret (return $ret)))
        ))))))))))

(= (interpret-expression $atom $type $space)
  (function (eval (if-decons $atom $op $args
    (chain (eval (get-type $op $space)) $op-type
      (chain (eval (is-function $op-type)) $is-func
        (unify $is-func True
          (chain (eval (interpret-func $atom $op-type $type $space)) $reduced-atom
            (chain (eval (metta-call $reduced-atom $type $space)) $ret (return $ret)) )
          (chain (eval (interpret-tuple $atom $space)) $reduced-atom
            (chain (eval (metta-call $reduced-atom $type $space)) $ret (return $ret)) ))))
    (chain (eval (type-cast $atom $type $space)) $ret (return $ret)) ))))

(= (interpret-func $expr $type $ret-type $space)
  (function (eval (if-decons $expr $op $args
    (chain (eval (interpret $op $type $space)) $reduced-op
      (eval (return-on-error $reduced-op
        (eval (if-decons $type $arrow $arg-types
          (chain (eval (interpret-args $expr $args $arg-types $ret-type $space)) $reduced-args
            (eval (return-on-error $reduced-args
              (chain (cons $reduced-op $reduced-args) $r (return $r)))))
          (return (Error $type "Function type expected")) )))))
    (return (Error $expr "Non-empty expression atom is expected")) ))))

(= (interpret-args $atom $args $arg-types $ret-type $space)
  (function (unify $args ()
    (eval (if-decons $arg-types $actual-ret-type $_tail
      (eval (match-types $actual-ret-type $ret-type
        (return ())
        (return (Error $atom BadType)) ))
      (return (Error (interpret-args $atom $args $arg-types $ret-type $space) "interpret-args expects a non-empty value for $arg-types argument")) ))
    (eval (if-decons $args $head $tail
      (eval (if-decons $arg-types $head-type $tail-types
        (chain (eval (interpret $head $head-type $space)) $reduced-head
          ; check that head was changed otherwise Error or Empty in the head
          ; can be just an argument which is passed by intention
          (eval (if-equal $reduced-head $head
            (chain (eval (interpret-args-tail $atom $reduced-head $tail $tail-types $ret-type $space)) $ret (return $ret))
            (eval (return-on-error $reduced-head
              (chain (eval (interpret-args-tail $atom $reduced-head $tail $tail-types $ret-type $space)) $ret (return $ret)) )))))
        (return (Error $atom BadType)) ))
      (return (Error (interpret-atom $atom $args $arg-types $space) "Non-empty expression atom is expected")) )))))

(= (interpret-args-tail $atom $head $args-tail $args-tail-types $ret-type $space)
  (function (chain (eval (interpret-args $atom $args-tail $args-tail-types $ret-type $space)) $reduced-tail
    (eval (return-on-error $reduced-tail
      (chain (cons $head $reduced-tail) $ret (return $ret)) )))))

(= (interpret-tuple $atom $space)
  (function (unify $atom ()
    (return $atom)
    (eval (if-decons $atom $head $tail
      (chain (eval (interpret $head %Undefined% $space)) $rhead
        (eval (if-empty $rhead (return Empty)
          (chain (eval (interpret-tuple $tail $space)) $rtail
            (eval (if-empty $rtail (return Empty)
              (chain (cons $rhead $rtail) $ret (return $ret)) ))))))
      (return (Error (interpret-tuple $atom $space) "Non-empty expression atom is expected as an argument")) )))))

(= (metta-call $atom $type $space)
  (function (eval (if-error $atom (return $atom)
    (chain (eval $atom) $result
      (eval (if-not-reducible $result (return $atom)
        (eval (if-empty $result (return Empty)
          (eval (if-error $result (return $result)
            (chain (eval (interpret $result $type $space)) $ret (return $ret)) )))))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Standard library written in MeTTa ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;`$then`, `$else` should be of `Atom` type to avoid evaluation
; and infinite cycle in inference
(: if (-> Bool Atom Atom $t))
(= (if True $then $else) $then)
(= (if False $then $else) $else)

(: or (-> Bool Bool Bool))
(= (or False False) False)
(= (or False True) True)
(= (or True False) True)
(= (or True True) True)

(: and (-> Bool Bool Bool))
(= (and False False) False)
(= (and False True) False)
(= (and True False) False)
(= (and True True) True)

(: match (-> Atom Atom Atom %Undefined%))
(= (match $space $pattern $template)
  (unify $pattern $space $template Empty))

(: let (-> Atom %Undefined% Atom Atom))
(= (let $pattern $atom $template)
  (unify $atom $pattern $template Empty))

(: let* (-> Expression Atom Atom))
(= (let* $pairs $template)
  (eval (if-decons $pairs ($pattern $atom) $tail
    (let $pattern $atom (let* $tail $template))
    $template )))

(: car-atom (-> Expression Atom))
(= (car-atom $atom)
  (eval (if-decons $atom $head $_
    $head
    (Error (car-atom $atom) "car-atom expects a non-empty expression as an argument") )))

(: cdr-atom (-> Expression Expression))
(= (cdr-atom $atom)
  (eval (if-decons $atom $_ $tail
    $tail
    (Error (cdr-atom $atom) "cdr-atom expects a non-empty expression as an argument") )))

(: quote (-> Atom Atom))
(= (quote $atom) NotReducible)

(: unquote (-> %Undefined% %Undefined%))
(= (unquote (quote $atom)) $atom)

; TODO: there is no way to define operation which consumes any number of
; arguments  and returns unit
(= (nop) ())
(= (nop $x) ())

