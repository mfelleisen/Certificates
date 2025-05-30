
## Measuring various contracts for argmax

Each argmax is measured in four contexts:

|              | short list | long list |
| ------------ | ---------- | --------- | 
| `most`       | 100000 x   | 10x       | 
| `expensive`  | 100000 x   | 10x       | 

where `most` uses a simple selector on the pair and `expensive` computes a 4-th degree polynomial (from the same number)


| argmax                   | without contract  | plain            | max-checking       | full correctness     | full with certificate | 
| ------------------------ | ----------------- | ---------------- | ------------------ | -------------------- | --------------------- |
| most @ many @ short      |  6  /  7  / 0     |  66  /  68  / 0  |  128  /  133  / 0  |  139  /  144  / 0    |  94  /  98  / 0       |
| most @ few @ long        |  54  /  58  / 0   |  212  /  219  / 1|  413  /  428  / 2  |  502  /  519  / 47   |  801  /  819  / 387   |
| expensive @ many @ short |  32  /  33  / 0   |  90  /  93  / 0  |  181  /  187  / 1  |  191  /  199  / 1    |  124  /  129  / 0     |
| expensive @ few @ long   |  309  /  324  / 0 |  477  /  496  / 1|  953  /  989  / 3  |  1095  /  1133  / 102|  1142  /  1172  / 451 |


At least at first glance, certificates do not uniformly reduce costs.
