#lang racket

;; -----------------------------------------------------------------------------
;; SPECIFICATION, including contract

#; {[Vector Real] [Vector Real] [Vector N] -> Boolean}
(define (validator a b n)
  (and 
   (validator-sorted b)
   (validator-p2-p3 a b n)))

#; {[Vector Real] -> Boolean}
(define (validator-sorted b)
  (define N (vector-length b))
  (for/and ([i (in-range 0 (sub1 N) +1)])
    (< (vector-ref b i) (vector-ref b (add1 i)))))

#; {[Vector Real] [Vector Real] [Vector N] -> Boolean}
(define (validator-p2-p3 a b n)
  (define N (vector-length a))
  (define M (make-vector N #false))
  (for/and ([i (in-range 0 (sub1 N) +1)])
    (begin0
      (and
       ;; vectors are 0-based; indices are from 0 .. N-1 for a vector of size N
       (<= 0 (vector-ref n i) (sub1 N))
       (= (vector-ref a (vector-ref n i)) (vector-ref b i))
       (not (vector-ref M (vector-ref n i))))
      (vector-set! M (vector-ref n i) #true))))

(define contract-for-self-certifying-sort
  (->i ([a [vectorof real?]]) (values (b [vectorof real?]) (n [vectorof real?]))
       #:post/name (b) "sorted" (validator-sorted b)
       #:post/name (a b n) "satisfies p2 and p3" (validator-p2-p3 a b n)
       #:post/name (a b n) "satisfies p1 p2 and p3" (validator a b n)))

;; -----------------------------------------------------------------------------
;; IMPLEMENTATION, depends on just the contract from above 

#; {[Vector Real] -> (values [Vector Real] [Vector Natural])}
;; sort the given vector `a` in ascending order and produce a certificate 
;; As Knuth wrote in the 1960s, nobody should ever implement bubble sort, but
;; I doing so to show how contracts can "certify" code a la Namjoshi & Zuck 
(define/contract (bubble-sort a)

  ;; here is one way to attach the contract to a function
  contract-for-self-certifying-sort
  
  (define N (vector-length a))
  (define b (vector-copy a))
  (define n (build-vector N identity))
  (for ([i (in-range (sub1 N) 0 -1)])
    (for ([j (in-range 0 i +1)])
      (when (> (vector-ref b j) (vector-ref b (add1 j)))
        (swap b j (add1 j))
        (swap n j (add1 j)))))
  (values b n))

#; {[Vector X] N N -> Void}
(define (swap b i j)
  (define tmp (vector-ref b i))
  (vector-set! b i (vector-ref b j))
  (vector-set! b j tmp))

;; -----------------------------------------------------------------------------
(module+ test
  (require rackunit)

  (define a (vector 4.1 1.1 3.9 7.9 2.9))
  (define-values (b n) (bubble-sort a))
  
  (check-false (validator-sorted a) "a-is-sorted")
  (check-true (validator-sorted b) "b-is-sorted")
  (check-true (validator-p2-p3 a b n) "p2-p3-is-satisfied"))