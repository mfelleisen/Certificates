#lang racket/base

;; code originally due to Cameron Moy. 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; require

(require racket/contract
         racket/list
         racket/match)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; contract

(define (sort/c make-bound)
  (define num-comparisons (make-parameter #f))
  (parametric->/c (α)
    (->i ([lt? (->* (α α) #:pre (num-comparisons (add1 (num-comparisons))) boolean?)]
          [vs (listof α)])
         #:param () num-comparisons 0
         [result (listof α)]
         #:post (vs)
         (<= (num-comparisons) (make-bound (length vs))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; definition

;; The number of calls to `lt?` is bounded by `(n ⌈lg n⌉ − 2⌈lg n⌉ + 1)` where
;; `n` is the length of `vs`.
(define merge-sort/c
  (sort/c (λ (n) (if (zero? n) 0 (add1 (* (- n 2) (ceiling (log n 2))))))))

;; Merge sort is bounded by this number of operations.
(define/contract (merge-sort lt? vs)
  merge-sort/c
  (let recur ([vs vs])
    (match vs
      [(or (list) (list _)) vs]
      [_ (define-values (lvs rvs)
           (split-at vs (quotient (length vs) 2)))
         (merge lt? (recur lvs) (recur rvs))])))

(define (merge lt? as bs)
  (match* (as bs)
    [((list) bs) bs]
    [(as (list)) as]
    [((list a as ...) (list b bs ...))
     (if (lt? a b)
         (cons a (merge lt? as (cons b bs)))
         (cons b (merge lt? (cons a as) bs)))]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; quicksort

;; Quick sort is *not* bounded by this number of operations! This fails.
(define/contract (quick-sort lt? vs)
  merge-sort/c
  (let recur ([vs vs])
    (match vs
      [(or (list) (list _)) vs]
      [(cons pivot rst)
       (define-values (lvs rvs)
         (partition (λ (v) (lt? v pivot)) rst))
       (append (recur lvs) (list pivot) (recur rvs))])))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; tests

(module+ test
  (require rackunit)

  (define (check-sort my-sort)
    (define/contract (prop xs)
      (-> (listof exact-integer?) #t)
      (equal? (my-sort < xs) (sort xs <)))
    (contract-exercise prop #:fuel 25))

  ;; Merge sort is OK.
  (check-sort merge-sort)

  ;; Including on a descending list.
  (check-equal?
   (merge-sort < '(5 4 3 2 1 0))
   (range 6))

  ;; Quick sort is not!
  (check-exn
   exn:fail:contract?
   (λ () (quick-sort < '(5 4 3 2 1 0)))))
