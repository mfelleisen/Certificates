
## Measuring various contracts for argmax

Each argmax is measured in four contexts:

|              | short list | long list |
| ------------ | ---------- | --------- | 
| `most`       | 100000 x   | 10x       | 
| `expensive`  | 100000 x   | 10x       | 

where `most` uses a simple selector on the pair and `expensive` computes a 4-th degree polynomial (from the same number)

|  argmax  | most @ short, 100000x | most @ long, 10x | expensive @ short, 100000x | expensive @ long, 10x |
|----------|-----------------------|------------------|----------------------------|-----------------------|
| (with certificate) | 95 / 99 / 0 | 811 / 830 / 393 | 124 / 129 / 0 | 1153 / 1185 / 456 |
| (full correctness) | 141 / 146 / 0 | 508 / 526 / 47 | 191 / 199 / 0 | 1098 / 1139 / 102 |
| (max only) | 129 / 134 / 0 | 417 / 433 / 2 | 181 / 188 / 1 | 950 / 989 / 3 |
| (plain ->i) | 66 / 69 / 0 | 215 / 223 / 0 | 88 / 92 / 0 | 480 / 500 / 1 |
| (no contract) | 6 / 6 / 0 | 54 / 58 / 0 | 31 / 33 / 0 | 302 / 317 / 0 |

At least at first glance, certificates do not uniformly reduce costs.
