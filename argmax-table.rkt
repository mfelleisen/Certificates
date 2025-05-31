#lang racket

(provide print-table)

(define (print-table example0)
  (define title (->row HEADER))
  (define dashes (->header title))

  (define n (string-length (argmax string-length (map first example0))))
  (define example
    (map (λ (x) (cons (~a (first x) #:width n) (rest x))) example0))
  
  (define body (map ->body (map ->row example)))

  (printf "~a\n" title)
  (printf "~a\n" dashes)
  (for-each (λ (x) (printf "~a\n" x)) body))

(define HEADER
    '(" argmax "
      "most @ short, 100000x"
      "most @ long, 10x"
      "expensive @ short, 100000x"
      "expensive @ long, 10x"))
  
(define (->row los)
  (let* ([los los]
         [los (string-join los " | ")]
         [los (~a "| " los " |")])
    los))

(define (->header s)
  (regexp-replace* #px"- -" (regexp-replace* #rx"\\(|[a-z]|\\>|\\)|@|1|0|\\,| " s "-") "---"))

(define (->body s0)
  (let* ([s s0]
         [s (regexp-replace* #px" time:" s ":")]
         [s (regexp-replace* #px"\n|cpu: " s "")]
         [s (regexp-replace* #px"real:|gc:" s ":")]
         [s (regexp-replace* #px" (\\d) " s " ___\\1 ")]
         [s (regexp-replace* #px" (\\d\\d) " s " __\\1 ")]
         [s (regexp-replace* #px" (\\d\\d\\d) " s " _\\1 ")])
    s))

(module+ test
  (define example
    '(("(with certificate)"
       "cpu time: 142 real time: 153 gc time: 2\n"
       "cpu time: 1100 real time: 1157 gc time: 458\n"
       "cpu time: 217 real time: 237 gc time: 3\n"
       "cpu time: 1828 real time: 1941 gc time: 575\n")
      ("(full correctness)"
       "cpu time: 184 real time: 194 gc time: 2\n"
       "cpu time: 626 real time: 663 gc time: 55\n"
       "cpu time: 316 real time: 332 gc time: 4\n"
       "cpu time: 1882 real time: 1999 gc time: 179\n")
      ("(max-checking)"
       "cpu time: 166 real time: 181 gc time: 2\n"
       "cpu time: 589 real time: 635 gc time: 9\n"
       "cpu time: 297 real time: 320 gc time: 4\n"
       "cpu time: 1736 real time: 1865 gc time: 24\n")
      ("(plain ->i)"
       "cpu time: 88 real time: 95 gc time: 1\n"
       "cpu time: 277 real time: 295 gc time: 3\n"
       "cpu time: 171 real time: 180 gc time: 3\n"
       "cpu time: 832 real time: 903 gc time: 11\n")
      ("(no contract)"
       "cpu time: 7 real time: 7 gc time: 0\n"
       "cpu time: 73 real time: 77 gc time: 0\n"
       "cpu time: 73 real time: 80 gc time: 1\n"
       "cpu time: 626 real time: 658 gc time: 8\n")))

 
  
  (print-table example))