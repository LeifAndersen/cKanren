;; prefo allows the user to assign a variable several acceptable
;; values without generating extra answers.
;;
;; It is possible to assign a "preference" list to a variable, where
;; the list is in order by preference.  For example,
;;
;; ... (prefo x '(1 2 3)) ...
;;
;; will unify x and 1 if the program reaches the end with x still
;; unground.  It is also acceptable if x is unified with any value
;; in the domain zbefore reification.
;;
;; This goal is not compatitble with =/= (from neq.scm)

(library
  (pref)
  (export
    prefo
    usepref
    get-dom
    enforce-constraintspref)
  (import
    (rnrs)
    (ck)
    (mk))
  
  (define prefo
    (lambda (x l)
      (goal-construct (prefo-c x l))))
  
  (define prefo-c
    (lambda (x l)
      (lambdam@ (a : s d c)
        ((process-prefdom (walk x s) l) a))))

  (define process-prefdom
    (lambda (x l)
      (lambdam@ (a : s d c)
        (cond
          ((var? x)
           (identitym (make-a s (ext-d x l d) c)))
          ((memq x l) (identitym a))
          (else #f)))))

  (define get-dom
    (lambda (x d)
      (cond
        ((assq x d) => rhs)
        (else #f))))

  (define (pick-prefs)
    (lambdam@ (a : s d c)
      ((letrec
           ((loop
              (lambda (d)
                (cond
                  ((null? d) unitg)
                  (else
                    (let ((x (walk (caar d) s)))
                      (cond
                        ((var? x)
                         (fresh ()
                           (== x (cadar d))
                           (loop (cdr d))))
                        (else (loop (cdr d))))))))))
         (loop d))
       a)))

  (define process-prefixpref
    (lambda (p c)
      (cond
        ((null? p) identitym)
        (else
          (let ((x (lhs (car p))) (v (rhs (car p))))
            (lambdam@ (a : s d c)
              (cond
                ((and (not (var? v)) (get-dom x d))
                 => (lambda (dom)
                      (and (memq v dom)
                           ((process-prefixpref (cdr p) c) a))))
                (else ((process-prefixpref (cdr p) c) a)))))))))

  (define reify-constraintspref identitym)
  
  (define enforce-constraintspref
    (lambda (x)
      (goal-construct (pick-prefs))))
  
  (define usepref
    (lambda ()
      (process-prefix process-prefixpref)
      (reify-constraints reify-constraintspref)
      (enforce-constraints enforce-constraintspref)))

)