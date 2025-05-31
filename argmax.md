## Measuring various contracts for argmax

Each argmax is measured in four contexts:

|              | short list | long list |
| ------------ | ---------- | --------- | 
| `most`       | 100000 x   | 10x       | 
| `expensive`  | 100000 x   | 10x       | 

where `most` uses a simple selector on the pair and `expensive` computes a 4-th degree polynomial (from the same number)

### Tested Variants 

|  argmax              |  purpose             	    			   	       		  	   | 
|--------------------- |---------------------------------------------------------------------------------- |
| (original)           | supplied by Racket 								   |
| (internal plain)     | rewritten (same speed) and collects certificate internally   			   |
| (internal ->i)       | rewritten (same speed) and collects certificate internally, PLUS ->i contract 	   |
| (lifted certificate) | re-using Racket's argmax, but lifting `f` to collect certificate externally  	   |
| (->i and lifted)     | like above plus ->i contract  	       	      	      		  		   |
| 		       |										   |
| (full ->i)           | full correctness expressed via plain ->i contract 				   |
| (max ->i)            | only checking that it returns an elemant that produces a maximal result for `f`   |
| (plain ->i)          | Racket's argmax equipped with ->i  	       		  	  	     	   |

### Performance: `->`

|  argmax  | most @ short, 100000x | most @ long, 10x | expensive @ short, 100000x | expensive @ long, 10x |
|----------|-----------------------|------------------|----------------------------|-----------------------|
| (original)           | ___6 : ___6 : ___0 | __55 : __59 : ___0 | __31 : __33 : ___0 | _308 : _323 : ___0 |
| (internal plain)     | __20 : __21 : ___0 | _383 : _393 : _212 | __54 : __57 : ___0 | _757 : _779 : _319 |
| (internal ->)        | __77 : __80 : ___0 | _634 : _648 : _303 | _108 : _112 : ___0 | 1006 : 1032 : _387 |
| (lifted certificate) | __22 : __24 : ___0 | _404 : _415 : _212 | __55 : __58 : ___0 | _840 : _863 : _383 |
| (-> and lifted)      | __80 : __84 : ___0 | _702 : _717 : _354 | _108 : _112 : ___0 | 1046 : 1073 : _417 |
| (param ->i)          | _185 : _192 : ___0 | 1370 : 1414 : _373 | _223 : _232 : ___1 | 1814 : 1870 : _506 |
| 		     | 	     	     | 	     	      |	      	      |	       	      	  |
| (full ->i)           | _140 : _145 : ___1 | _508 : _525 : __48 | _194 : _202 : ___0 | 1100 : 1142 : _102 |
| (max ->i)            | _129 : _134 : ___0 | _416 : _432 : ___2 | _182 : _190 : ___1 | _955 : _994 : ___4 |
| (plain ->)           | __58 : __61 : ___0 | _214 : _222 : ___1 | __82 : __85 : ___0 | _481 : _500 : ___1 |

### Performance: `->i` where useful 

|  argmax  | most @ short, 100000x | most @ long, 10x | expensive @ short, 100000x | expensive @ long, 10x |
|----------|-----------------------|------------------|----------------------------|-----------------------|
| (original)           | ___6 : ___6 : ___0 | __54 : __58 : ___0 | __31 : __32 : ___0 | _299 : _315 : ___0 |
| (internal plain)     | __20 : __21 : ___0 | _380 : _391 : _210 | __54 : __57 : ___0 | _760 : _782 : _322 |
| (internal ->i)       | __85 : __89 : ___0 | _631 : _645 : _302 | _113 : _118 : ___0 | 1001 : 1027 : _385 |
| (lifted certificate) | __23 : __24 : ___0 | _403 : _414 : _211 | __55 : __58 : ___0 | _840 : _864 : _380 |
| (->i and lifted)     | __89 : __92 : ___0 | _705 : _720 : _356 | _115 : _120 : ___0 | 1052 : 1080 : _416 |
| (param ->i)          | _188 : _195 : ___0 | 1377 : 1418 : _374 | _228 : _237 : ___0 | 1817 : 1869 : _512 |
| 		     | 	     	     | 	     	      |	      	      |	       	      	  |
| (full ->i)           | _142 : _147 : ___0 | _508 : _526 : __48 | _196 : _203 : ___1 | 1102 : 1143 : _102 |
| (max ->i)            | _128 : _133 : ___0 | _418 : _434 : ___2 | _181 : _188 : ___1 | _949 : _988 : ___3 |
| (plain ->i)          | __66 : __68 : ___0 | _215 : _223 : ___1 | __89 : __93 : ___0 | _486 : _506 : ___1 |


### Observations

- Certificates do reduce the cost. External certificates, created via
  "lifting", decrease the running time only a little more than
  internally created certificates.

- Plain self-certification essentially increases the cost by a factor of 3. 

- The `->i` contracts impose a much more serious cost.
- Well, `->` also imposes such a cost ...

- Indeed, `->i` contracts on `argmax` with internal or external
  certificate makes it look like certificates don't help much when the
  function is called a few times on long lists.


