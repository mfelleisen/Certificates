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


### Complexity Certificates via Parameter Contracts

The same idea can be used to check the algorithmic complexity of code.

Using `#:param` contracts, an implementation of any sort algorithm can
count the number of comparisons and ensure that they don't exceed an
expected number. 

See [sort and check complexity with parameter contracts](sort-complexity.rkt).
