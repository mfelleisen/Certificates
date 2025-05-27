## Self-Certifying Code

This repo is inspired by


- [Program Correctness through Self-Certification](https://cacm.acm.org/research/program-correctness-through-self-certification/)

- [Trace Contracts](https://www.cambridge.org/core/journals/journal-of-functional-programming/article/trace-contracts/4AF1C7361751839FF7E2DEBC65A050EE)

- [parameter specs in `->i` contracts](https://docs.racket-lang.org/reference/function-contracts.html#%28form._%28%28lib._racket%2Fcontract%2Fbase..rkt%29._-~3ei%29%29)

Namjoshi & Zuck present the idea of self-certifying code, that is,
algorithms that not only produce an output for some input but also a
_certificate_ of correctness. Ideally, this certificate is easy to
produce, in terms of developer effort and in terms of computational
effort. Similarly, the specification of the algorithm should come wit
a _validator_ that is also easy to implement and that can check this
certificate with low computational effort. Their article presents the
idea with a specification and implementation of an imperative bubble
sort algorithm for vectors.

### Plain Contracts: Implementing Self-Certification with 

Using plain old dependent contracts, an implementation of Namjoshi &
Zuck's idea is straightforward.

See [sort with certificate contract](sort-certificate.rkt). 


### Parameter Contracts: Moving the Generation of the Certificate into the Specification

The addition of certificate-generating code to an algorithm may cause
problems:

1. Weaving certificate-generating code into the functional code may
   cause the injection of bugs. Since the two pieces are related via a
   (probably unstated) logical invariant, the developer must recognize
   it, establish it, and maintain it.

2. Like defensive code, certificate-generating algorithms force future
   readers to tease the important bits apart just to understand the
   code.

3. If these maintainers must change the functional parts of the
   algorithm, they may inadvertently mess up certificate-generating
    parts. Also see 1 concerning _logical invariant_. 

This analysis suggests that the generation of certificates is really a
_specification_ task and not an _implementation_ one.

Using `#:param` contracts, an implementation of the same bubble-sort
algorithm can cleanly separate these pieces.

See [sort with parameter contract for generatin a certificate](sort-certificate-param.rkt).


### How to Define the Interface Specification

Does all of this mean that algorithm designers have to expose pieces
of the code, such as `swap`, so that the specification can attach the
proper contracts?

No.

When objects, functions, and contracts are first-class values,
specifications can express these constraints with the _retroactive_
attachment of contracts.

**Example 1** If the core language is a class-based, object-oriented
  language, like Java, the specifier can impose an opaque contract on
  the `array-list%` collection class from the standard library. The
  key pieces of code look like this:

```
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
```

See [sort on "array lists"](sort-certificate-param-class.rkt) for the full code. 


**Example 2** In a functional language, such as Racket, we can
  explicate that `swap` is an explicit building block by turning it
  into a parameter of `sort` and by _retroactively_ imposing the
  appropriate contract on this extra parameter:

```
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
```

**Example 3** In this setting, we can go even further by making `swap`
  an _optional_ parameter and _optionally_ imposing an appropriate
  contract. That is, if the implementer of `sort` directly refers to
  some existing `swap` or open-codes `swap` inside the `for` loop,
  the contract can simply _not_ compute the certificate (and could
  even issue a warning that the developer disabled it).

See [ho sort](sort-certificate-param-ho.rkt) for the full code.

Higher-order languages offer several alternative mechanisms to cope
with this problem.

What this approach exposes is that we tend to think of specifications
in a naive manner, not realizing that extensional-looking specs often
implicitly assume intensional aspects, which should be stated explicitly.


### Complexity Certificates via Parameter Contracts

The same idea can be used to check the algorithmic complexity of code.

Using `#:param` contracts, an implementation of any sort algorithm can
count the number of comparisons and ensure that they don't exceed an
expected number. 

See [sort and check complexity with parameter contracts](sort-complexity.rkt).
