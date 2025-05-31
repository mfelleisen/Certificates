#lang racket

(module+ test
  (require "argmax-table.rkt")
  (require rackunit)

  #; {[Listof [List Symbol N]] -> [List Symbol N]}
  ;; for functionality testing 
  (define-syntax-rule (most-fruit argmax l)
    (argmax second l))

  #; {[Listof [List Symbol N]] -> [List Symbol N]}
  (define-syntax-rule (expensive-fruit argmax l)
    (argmax polynomial l))

  (define (polynomial x)
    (define n (second x))
    (+ (* 3.1 (expt n 4)) (* 13.7 (expt n 3)) (* 130000.7 (expt n 2)) (* -1 n) 1))

  #; {N [Listof [List Symbol N]] -> Void}
  ;; for performance testing
  (define-syntax-rule (run-often n fruit argmax in)
    (let ([x #false])
      (with-output-to-string
        (lambda ()
          (collect-garbage) (collect-garbage) (collect-garbage)
          (time (for ([i (in-range n)]) (set! x (fruit argmax in)))))))))

;; ---------------------------------------------------------------------------------------------------
;; a plain contract 

(module argmax-plain racket
  (provide
   (contract-out
    [argmax argmax/c]))

  (define argmax/c ;; the plainest contract 
    (-> (-> any/c real?) list? any/c)))

;; ---------------------------------------------------------------------------------------------------
;; a contract to ensure that the result is a maximum of `f` of all elements of `lox`

(module argmax-max racket
  (provide
   (contract-out
    [argmax argmax/c]))

  (define (f-larger-at-r-than-any-other-x f lox r)
    (define f@r (f r))
    (andmap (λ (x) (>= f@r (f x))) lox))

  (define argmax/c 
    (->i ([f (-> any/c real?)] [lox list?]) (r any/c)
         #:post/name (f lox r) "(f r) is largest" (f-larger-at-r-than-any-other-x f lox r))))

;; ---------------------------------------------------------------------------------------------------
;; a plain contract to ensure that
;; -- the result is a maximum of `f` of all elements of `lox` and
;; -- it is the leftmost such element 

(module argmax-max-leftmost racket
  (provide
   (contract-out
    [argmax argmax/c]))
  
  (define argmax/c 
    (->i ([f (-> any/c real?)] [lox list?]) (r any/c)
         #:post/name (f lox r) "(f r) is largest and leftmost one" (complete-specification f lox r)))

  (define (complete-specification f lox r)
    (define f@r (f r))<
    (define f@lox (map f lox))
    (and
     (f-larger-at-r-than-any-other-x f@lox f@r)
     (upto r lox f@r f@lox)))

  (define (f-larger-at-r-than-any-other-x f@lox f@r)
    (andmap (λ (f@x) (>= f@r f@x)) f@lox))

  (define (upto r lox f@r f@lox)
    (define prefix (takef lox (λ (x) (not (equal? r x)))))
    (for/and ([f@x f@lox] [_ prefix])
      (< f@x f@r))))

(module argmax-param-contract racket
  (provide
   (contract-out
    [argmax argmax/c]))

  (define argmax%
    (class object%
      (super-new)

      (field [cache '()])

      (define/public (check f r)
        (set! cache (reverse cache))
        (define f@r (f r))
        (define lox (map car cache))
        (define f@lox (map cadr cache))
        (and
         (f-larger-at-r-than-any-other-x f@lox f@r)
         (upto r lox f@r f@lox)))
  
      (define (f-larger-at-r-than-any-other-x f@lox f@r)
        (andmap (λ (f@x) (>= f@r f@x)) f@lox))
  
      (define (upto r lox f@r f@lox)
        (for/and ([f@x f@lox] [x lox] #:break (equal? x r))
          (< f@x f@r)))

      (define/public (record x y)
        (set! cache (cons (list x y) cache)))))

  (define argmax/p (make-parameter #false))
  
  (define argmax/c
    (->i ([f (->i ([x any/c]) (y real?) #:post (x y) (send (argmax/p) record x y))]
          [lox list?])
         #:param () argmax/p (new argmax%)
         (r any/c)
         #:post/name (f lox r) "(f r) is largest and leftmost one" (send (argmax/p) check f r))))

;; ---------------------------------------------------------------------------------------------------
;; a self-certifying contract to ensure that
;; -- the result is a maximum of `f` of all elements of `lox` and
;; -- it is the leftmost such element

(module argmax-max-leftmost-with-certificate racket
  (provide
   (contract-out
    [argmax argmax/c]))
  
  (require (rename-in racket (argmax old:argmax)))

  (define argmax/c 
    (-> (-> any/c real?) list? any/c))

  (define (argmax f lox)
    (define *cache '())
    (define (g x)
      (define f@x (f x))
      (set! *cache (cons (list x f@x) *cache))
      f@x)
    (define r (old:argmax g lox))
    (unless (complete-specification (reverse *cache) f r)
      (error 'argmax "failed specs"))
    r)

  ;; CAUTION: this assumes that `old:argmax` traverses `lox` from left to right
  (define (complete-specification cache f r)
    (define f@r (f r))
    (define lox (map car cache))
    (define f@lox (map cadr cache))
    (and
     (f-larger-at-r-than-any-other-x f@lox f@r)
     (upto r lox f@r f@lox)))
  
  (define (f-larger-at-r-than-any-other-x f@lox f@r)
    (andmap (λ (f@x) (>= f@r f@x)) f@lox))
  
  (define (upto r lox f@r f@lox)
    (for/and ([f@x f@lox] [x lox] #:break (equal? x r))
      (< f@x f@r))))

;; ---------------------------------------------------------------------------------------------------
;; a self-certifying WITHOUT contract, but via LIFTING to ensure that
;; -- the result is a maximum of `f` of all elements of `lox` and
;; -- it is the leftmost such element
(module argmax-max-leftmost-with-certificate-no-contract racket
  (provide argmax)
  
  (require (rename-in racket (argmax old:argmax)))

  (define argmax/c 
    (-> (-> any/c real?) list? any/c))

  (define (argmax f lox)
    (define *cache '())
    (define (g x)
      (define f@x (f x))
      (set! *cache (cons (list x f@x) *cache))
      f@x)
    (define r (old:argmax g lox))
    (unless (complete-specification (reverse *cache) f r)
      (error 'argmax "failed specs"))
    r)

  ;; CAUTION: this assumes that `old:argmax` traverses `lox` from left to right
  (define (complete-specification cache f r)
    (define f@r (f r))
    (define lox (map car cache))
    (define f@lox (map cadr cache))
    (and
     (f-larger-at-r-than-any-other-x f@lox f@r)
     (upto r lox f@r f@lox)))
  
  (define (f-larger-at-r-than-any-other-x f@lox f@r)
    (andmap (λ (f@x) (>= f@r f@x)) f@lox))
  
  (define (upto r lox f@r f@lox)
    (for/and ([f@x f@lox] [x lox] #:break (equal? x r))
      (< f@x f@r))))

;; ---------------------------------------------------------------------------------------------------
;; a re-implementation that is as fast the one in the library (confirmed)
;; then equipped with a self-certification process 

(module my-max racket
  (provide argmax)

  (provide
   (contract-out
    [rename argmax argmax-with argmax/c]))

  (define argmax/c ;; the plainest contract 
    (-> (-> any/c real?) list? any/c))
  
  (define (argmax f lox0)
    (define-values (r cache) (argmax0 f lox0))
    (unless (complete-specification (reverse cache) f r)
      (error 'argmax "failed specs"))
    r)
    
  (define (argmax0 f lox0)
    (when (null? lox0)
      (error 'argmax "non-empty list expected, given '*()"))
    (define one0 (car lox0))
    (define mx0  (f one0))
    (let loop ([lox (rest lox0)] [mx mx0] [the-one one0] [cache (list (list one0 mx0))])
      (cond
        [(null? lox) (values the-one cache)]
        [(cons? lox)
         (define x (car lox))
         (define y (f x))
         (define cache++ (cons (list x y) cache))
         (if (> y mx)
             (loop (cdr lox) y x cache++)
             (loop (cdr lox) mx the-one cache++))]
        [else (error "list expected, given ~v" lox0)])))

  ;; CAUTION: this assumes that `old:argmax` traverses `lox` from left to right
  (define (complete-specification cache f r)
    (define f@r (f r))
    (define lox (map car cache))
    (define f@lox (map cadr cache))
    (and
     (f-larger-at-r-than-any-other-x f@lox f@r)
     (upto r lox f@r f@lox)))
  
  (define (f-larger-at-r-than-any-other-x f@lox f@r)
    (andmap (λ (f@x) (>= f@r f@x)) f@lox))
  
  (define (upto r lox f@r f@lox)
    (for/and ([f@x f@lox] [x lox] #:break (equal? x r))
      (< f@x f@r)))

  ;; just for the record: combining the two passes like this is slower than two passes
  (define (one-pass-check r lox f@r f@lox)
    (define not-seen-yet #true)
    (for/and ([f@x f@lox] [x lox])
      (cond
        [not-seen-yet
         (if (equal? x r)
             (set! not-seen-yet #false) ;; void counts as true
             (< f@x f@r))]
        [else (>= f@r f@x)]))))

;; ---------------------------------------------------------------------------------------------------
(require (prefix-in 0: 'my-max))
(require (prefix-in p: 'argmax-plain))
(require (prefix-in q: 'argmax-param-contract))
(require (prefix-in m: 'argmax-max))
(require (prefix-in f: 'argmax-max-leftmost))
(require (prefix-in c: 'argmax-max-leftmost-with-certificate))
(require (prefix-in d: 'argmax-max-leftmost-with-certificate-no-contract))
(require (except-in 'my-max argmax))

(module+ test
  (define in1 '((banana 1) (apples 0) (oranges 3) (mango 2) (pears 3) (blueberry 3)))

  (define ex2 (make-list 10000 '(ugly 0))) ;; ex pushes the result to the right 
  (define in2 (apply append ex2 (make-list 100000 in1)))
  
  (define *measurements
    '())

  (define-syntax-rule (measure argmax x ...)
    (let ()
      ;; ensure it's correct
      (check-equal? (most-fruit argmax in1) '(oranges 3))
      (check-equal? (most-fruit argmax in2) '(oranges 3))
      
      (define tmp
        (list
         (format "~a" '(x ...))
         (run-often 100000 most-fruit argmax in1)
         (run-often 10 most-fruit argmax in2)
         (run-often 100000 expensive-fruit argmax in1)
         (run-often 10 expensive-fruit argmax in2)))
      (set! *measurements (cons tmp *measurements))))
  
  (measure argmax "original")
  (measure 0:argmax "internal plain")
  (measure argmax-with "internal ->")
  (measure d:argmax "lifted certificate")
  (measure c:argmax "-> and lifted")
  (measure f:argmax "full ->i")
  (measure m:argmax "max ->i")
  (measure p:argmax "plain ->")

  (measure q:argmax "param ->i")
  
  
  (print-table (reverse *measurements)))
