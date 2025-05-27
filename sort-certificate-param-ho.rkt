#lang racket

;; -----------------------------------------------------------------------------
;; the CERTIFICATE as an object

(define certificate%
  (class object% (init-field a)
    (super-new)

    (field [N #; Natural           (vector-length a)])
    (field [n #; [Vector- Natural] (build-vector N identity)])

    #; {Natural Natural -> Void}
    (define/public (swap i j)
      (define tmp (vector-ref n i))
      (vector-set! n i (vector-ref n j))
      (vector-set! n j tmp))

    #; {[Vector Real] -> Boolean}
    (define/public (validator b)
      (and 
       (validator-sorted b)
       (validator-p2-p3 b)))

    #; {[Vector Real] -> Boolean}
    (define/private (validator-sorted b)
      (define N (vector-length b))
      (for/and ([i (in-range 0 (sub1 N) +1)])
        (< (vector-ref b i) (vector-ref b (add1 i)))))

    #; {[Vector Real] [Vector Real] -> Boolean}
    (define/private (validator-p2-p3 b)
      (define M (make-vector N #false))
      (for/and ([i (in-range 0 (sub1 N) +1)])
        (begin0
          (and
           ;; vectors are 0-based; indices are from 0 .. N-1 for a vector of size N
           (<= 0 (vector-ref n i) (sub1 N))
           (= (vector-ref a (vector-ref n i)) (vector-ref b i))
           (not (vector-ref M (vector-ref n i))))
          (vector-set! M (vector-ref n i) #true))))))

;; -----------------------------------------------------------------------------
;; SPECIFICTION CONTRACTS

#; {[Parameter [Instance-of Certificate%]]}
;; .. only during the dynamic extent of `sort`
;; `#false` while no `sort` is running
(define record-swap-events (make-parameter #false))

(define contract-for-swap
  (->i ([v vector?] [i natural?] [j natural?])
       #:pre/name (i j) "record the swap event" (send (record-swap-events) swap i j)
       (r void?)))

(define contract-for-self-certifying-sort
  (->i ([a [vectorof real?]]
        [swap contract-for-swap])
       #:param (a) record-swap-events (new certificate% [a a])
       (b [vectorof real?])
       #:post/name (a b) "satisfies p1 p2 and p3" (send (record-swap-events) validator b)))

;; -----------------------------------------------------------------------------
;; IMPLEMENTATION, depends on just the contract from above

;; The code does NOT need to compute the certificate itself. 

#; {[Vector Real] -> (values [Vector Real] [Vector Natural])}
;; sort the given vector `a` in ascending order and produce a certificate 
;; As Knuth wrote in the 1960s, nobody should ever implement bubble sort, but
;; I doing so to show how contracts can "certify" code a la Namjoshi & Zuck 
(define/contract (bubble-sort a swap)
  
  contract-for-self-certifying-sort
  
  (define N (vector-length a))
  (define b (vector-copy a))
  (for ([i (in-range (sub1 N) 0 -1)])
    (for ([j (in-range 0 i +1)])
      (when (> (vector-ref b j) (vector-ref b (add1 j)))
        (swap b j (add1 j)))))
  b)

#; {[Vector X] N N -> Void}
(define (swap b i j)
  (define tmp (vector-ref b i))
  (vector-set! b i (vector-ref b j))
  (vector-set! b j tmp))

;; -----------------------------------------------------------------------------
(module+ test
  (require rackunit)

  (define a-1 (vector 4.1 1.1 3.9 7.9 2.9))
  (define b-1 (bubble-sort a-1 swap))

  (define a-2 (vector 0.1 4.1 1.1 3.9 7.9 2.9 -0.1))
  (define b-2 (bubble-sort a-2 swap)))
