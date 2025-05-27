#lang racket

;; ---------------------------------------------------------------------------------------------------
;; STANDARD LIB (assume this was defined decades ago)

(define array-list%
  (class object% (init-field #;{[Listof Real]} a)
    (super-new)

    (field [b (apply vector a)])
    (field [N (length a)])
           
    (define/public (size) N)

    (define/public (copy) (new array-list% {a (vector->list b)}))

    (define/public (== a i j)
      (= (vector-ref (get-field b a) i) (vector-ref b j)))
      
    (define/public (>> i j)
      (> (vector-ref b i) (vector-ref b j)))

    (define/public (swap i j)
      (define tmp (vector-ref b i))
      (vector-set! b i (vector-ref b j))
      (vector-set! b j tmp))))

;; -----------------------------------------------------------------------------
;; the CERTIFICATE as an object

(define certificate%
  (class object% (init-field a)
    (super-new)

    (field [N #; Natural           (send a size)])
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
      (define N (send b size))
      (for/and ([i (in-range 0 (sub1 N) +1)])
        (send b >> (add1 i) i)))

    #; {[Vector Real] [Vector Real] -> Boolean}
    (define/private (validator-p2-p3 b)
      (define M (make-vector N #false))
      (for/and ([i (in-range 0 (sub1 N) +1)])
        (begin0
          (and
           ;; vectors are 0-based; indices are from 0 .. N-1 for a vector of size N
           (<= 0 (vector-ref n i) (sub1 N))
           (send b == a (vector-ref n i) i)
           (not (vector-ref M (vector-ref n i))))
          (vector-set! M (vector-ref n i) #true))))))

;; -----------------------------------------------------------------------------
;; SPECIFICTION CONTRACTS

#; {[Parameter [Instance-of Certificate%]]}
;; .. only during the dynamic extent of `sort`
;; `#false` while no `sort` is running
(define record-swap-events (make-parameter #false))

(define vector%/c
  (class/c
   (copy (->m (instanceof/c (recursive-contract vector%/c))))
   (>>   (->m natural? natural? boolean?))
   (swap (->dm ([i natural?] [j natural?])
               #:pre (send (record-swap-events) swap i j)
               (r void?)))))

(define contract-for-self-certifying-sort
  (->i ([a [instanceof/c vector%/c]])
       #:param (a) record-swap-events (new certificate% [a a])
       (b [instanceof/c vector%/c])
       #:post/name (a b) "satisfies p1 p2 and p3" (send (record-swap-events) validator b)))

;; -----------------------------------------------------------------------------
;; IMPLEMENTATION, depends on just the contract from above

;; The code does NOT need to compute the certificate itself. 

#; {[Vector Real] -> (values [Vector Real] [Vector Natural])}
;; sort the given vector `a` in ascending order and produce a certificate 
;; As Knuth wrote in the 1960s, nobody should ever implement bubble sort, but
;; I doing so to show how contracts can "certify" code a la Namjoshi & Zuck 
(define/contract (bubble-sort a)
  
  contract-for-self-certifying-sort
  
  (define N (send a size))
  (define b (send a copy))
  (for ([i (in-range (sub1 N) 0 -1)])
    (for ([j (in-range 0 i +1)])
      (when (send b >> j (add1 j))
        (send b swap j (add1 j)))))
  b)



;; -----------------------------------------------------------------------------
(module+ test
  (require rackunit)

  (define a-1 (new array-list% [a '(4.1 1.1 3.9 7.9 2.9)]))
  (define b-1 (bubble-sort a-1))

  (define a-2 (new array-list% [a '(0.1 4.1 1.1 3.9 7.9 2.9 -0.1)]))
  (define b-2 (bubble-sort a-2)))
