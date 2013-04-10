#lang racket

(require
 "../ck.rkt"
 "../absento.rkt"
 "../tree-unify.rkt"
 "../neq.rkt"
 "tester.rkt")

(provide test-infer test-infer-long)

(define (test-infer)
  (define !-
    (lambda (exp env t)
      (conde
       [(symbolo exp) (lookupo exp env t)]
       [(fresh (x e t-x t-e)
          (== `(lambda (,x) ,e) exp)
          (symbolo x)
          (not-in-envo 'lambda env)
          (== `(-> ,t-x ,t-e) t)
          (!- e `((,x . ,t-x) . ,env) t-e))]
       [(fresh (rator rand t-x)
          (== `(,rator ,rand) exp)
          (!- rator env `(-> ,t-x ,t))
          (!- rand env t-x))])))

  (define lookupo
    (lambda (x env t)
      (fresh (rest y v)
        (== `((,y . ,v) . ,rest) env)
        (conde
         ((== y x) (== v t))
         ((=/= y x) (lookupo x rest t))))))

  (define not-in-envo
    (lambda (x env)
      (conde
       ((== '() env))
       ((fresh (y v rest)
          (== `((,y . ,v) . ,rest) env)
          (=/= y x)
          (not-in-envo x rest))))))

  (parameterize ([reify-with-colon #f]
                 [reify-prefix-dot #f])
    (test-check "types"
                (run 10 (q) (fresh (t exp) (!- exp '() t)  (== `(,exp => ,t) q)))
                '((((lambda (_.0) _.0) => (-> _.1 _.1)) (sym _.0))
                  (((lambda (_.0) (lambda (_.1) _.1))
                    =>
                    (-> _.2 (-> _.3 _.3)))
                   (=/= ((_.0 lambda)))
                   (sym _.0 _.1))
                  (((lambda (_.0) (lambda (_.1) _.0))
                    =>
                    (-> _.2 (-> _.3 _.2)))
                   (=/= ((_.0 _.1)) ((_.0 lambda)))
                   (sym _.0 _.1))
                  ((((lambda (_.0) _.0) (lambda (_.1) _.1)) => (-> _.2 _.2))
                   (sym _.0 _.1))
                  (((lambda (_.0) (lambda (_.1) (lambda (_.2) _.2)))
                    =>
                    (-> _.3 (-> _.4 (-> _.5 _.5))))
                   (=/= ((_.0 lambda)) ((_.1 lambda)))
                   (sym _.0 _.1 _.2))
                  (((lambda (_.0) (lambda (_.1) (lambda (_.2) _.1)))
                    =>
                    (-> _.3 (-> _.4 (-> _.5 _.4))))
                   (=/= ((_.0 lambda)) ((_.1 _.2)) ((_.1 lambda)))
                   (sym _.0 _.1 _.2))
                  (((lambda (_.0) (_.0 (lambda (_.1) _.1)))
                    =>
                    (-> (-> (-> _.2 _.2) _.3) _.3))
                   (=/= ((_.0 lambda)))
                   (sym _.0 _.1))
                  (((lambda (_.0) (lambda (_.1) (lambda (_.2) _.0)))
                    =>
                    (-> _.3 (-> _.4 (-> _.5 _.3))))
                   (=/= ((_.0 _.1)) ((_.0 _.2)) ((_.0 lambda)) ((_.1 lambda)))
                   (sym _.0 _.1 _.2))
                  (((lambda (_.0) (lambda (_.1) (_.1 _.0)))
                    =>
                    (-> _.2 (-> (-> _.2 _.3) _.3)))
                   (=/= ((_.0 _.1)) ((_.0 lambda)))
                   (sym _.0 _.1))
                  ((((lambda (_.0) _.0) (lambda (_.1) (lambda (_.2) _.2)))
                    =>
                    (-> _.3 (-> _.4 _.4)))
                   (=/= ((_.1 lambda)))
                   (sym _.0 _.1 _.2))))
    ))

(define (test-infer-long)
  (test-infer))

(module+ main
  (test-infer-long))
