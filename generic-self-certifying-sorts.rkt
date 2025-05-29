#lang racket

;; ---------------------------------------------------------------------------------------------------
;; A SPECIFICATION FOR A PLAIN SORT with SIMPLISTIC (type-like) contracts

(define sort/c ;; generic in which elements are being sorted 
  #; (∀ (α) ...)
  ;; create a sorted version of the given list by comparing the selectable pieces of each element
  (->i ([to-be-sorted (and/c (listof #; α any/c) cons?)] ;; not empty
        [select       (-> #; α any/c #; β any/c)]
        [compare      (-> #; β any/c #; β any/c boolean?)])
       (r (listof #; α any/c))))

;; ---------------------------------------------------------------------------------------------------
;; INSERTION SORT 

(define/contract (insertion-sort lox0 select-y-from-x compare-y-s) sort/c
  #; {[Listof α] -> [Listof α]}
  (define (sort lox)
    (cond
      [(empty? lox) '()]
      [else (insert (first lox) (sort (rest lox)))]))

  #; {α [Listof α] -> [Listof α]}
  (define (insert x lox)
    (cond
      [(empty? lox) (list x)]
      [(compare-y-s (select-y-from-x x) (select-y-from-x (first lox))) (cons x lox)]
      [else (cons (first lox) (insert x (rest lox)))]))
  
  (sort lox0))

;; ---------------------------------------------------------------------------------------------------
;; MERGE SORT

(define/contract (merge-sort lox0 select-y-from-x compare-y-s) sort/c
  #; {[Listof α] [Listof α] -> [Listof α]}
  (define (merge lox loy)
    (cond
      [(empty? lox) loy]
      [(empty? loy) lox]
      [else
       (define x (first lox))
       (define y (first loy))
       (if (compare-y-s (select-y-from-x x) (select-y-from-x y))
           (cons x (merge (rest lox) loy))
           (cons y (merge lox (rest loy))))]))

  #; {[NEListof [Listof α]] -> [Listof α]}
  (define (merge-neighbors lolox)
    (cond
      [(or (empty? lolox) (empty? (rest lolox))) lolox]
      [else
       (define one (first lolox))
       (define two (second lolox))
       (cons (merge one two) (merge-neighbors (rest (rest lolox))))]))

  #; {[NEListof [Listof α]] -> [Listof α]}
  (define (driver lolox)
    (cond
      [(empty? (rest lolox)) (first lolox)]
      [else (driver (merge-neighbors lolox))]))

  (driver (map list lox0)))

;; ---------------------------------------------------------------------------------------------------
(module+ test
  (require rackunit)

  (define a (list 4.1 1.1 3.9 7.9 2.9))
  (define s (list 1.1 2.9 3.9 4.1 7.9))
  (check-equal? (insertion-sort a identity <) s "check insertion sort")
  (check-equal? (merge-sort a identity <) s "check merge sort"))

;; ===================================================================================================
;; GENERIC SPECIFICATION of a SELF-CERTIYING SORT

#; {[Listof Real] [List [Listof Real] [Listof N]] -> Boolean}
(define (validator select compare a result+certificate)
  (define b (first result+certificate))
  (define n (second result+certificate))
  (and 
   (validator-sorted select compare b)
   (validator-p2-p3 select compare a b n)))

#; {[NEListof Real] -> Boolean}
(define (validator-sorted select compare b0)
  (for/fold ([prev (first b0)] [okay? #true] #:result okay?) ([curr (rest b0)])
    (values curr (compare (select prev) (select curr)))))
  
#; {[Listof Real] [Listof Real] [Listof N] -> Boolean}
(define (validator-p2-p3 select compare a0 b0 n0)
  (define a (list->vector a0)) ;; for constant access 
  (define N (length a0))
  (define M (make-vector N #false))
  (for/and ([into-a n0] [in-b b0])
    (begin0
      (and
       (<= 0 into-a (sub1 N))
       (equal? (vector-ref a into-a) in-b)
       (not (vector-ref M into-a)))
      (vector-set! M into-a #true))))

(define self-certifying-sort/c
  #; (∀ (α) ...)
  ;; create a sorted version of the given list by comparing the selectable pieces of each element
  (->i ([to-be-sorted (and/c (listof #; α any/c) cons?)] ;; not empty
        [select       (-> #; α any/c #; β any/c)]
        [compare      (-> #; β any/c #; β any/c boolean?)])
       (result+certificate (list/c (listof #; α any/c) (listof #; α natural?)))
       #:post/name (to-be-sorted select compare result+certificate) "satisfies p1 p2 and p3"
       (validator select compare to-be-sorted result+certificate)))

;; ===================================================================================================
;; FUNCIONAL that turns every list-based sort into a self-certifying sort

(define/contract (certify-sort sort) (-> sort/c self-certifying-sort/c)
  (λ (lox0 select-y-from-x compare-y-s) ;; curried function 
    (define lifted-lox0            (lift-list lox0))
    (define lifted-select-y-from-x (compose select-y-from-x lower-element))
    (define lifted-result          (sort lifted-lox0 lifted-select-y-from-x compare-y-s))
    ;;     proper result:            certificate: 
    (list (lower-list lifted-result) (extract-certificate lifted-result))))

(define (lift-list lox) (for/list ([x lox] [i (in-naturals)]) (lift-element x i)))
(define (lower-list lox) (map lower-element lox))
(define (extract-certificate lifted-result) (map index-element lifted-result))

(define lift-element list)
(define lower-element first)
(define index-element second)

;; ---------------------------------------------------------------------------------------------------
;; SELF-CERTIFYING SORTs, generated parametrically 

;; the following two sort functions are functionally equivalent to sort but self-certify
(define certifying-insertion-sort (compose first (certify-sort insertion-sort)))
(define certifying-merge-sort     (compose first (certify-sort merge-sort)))

(module+ test
  (require rackunit)
  
  (check-equal? (certifying-insertion-sort a identity <) s "check insertion sort")
  (check-equal? (certifying-merge-sort a identity <) s "check merge sort"))
