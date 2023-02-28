# BQNcrate: generating permutations

02/28/2023

Studying the BQNcrate expression for generating all permutations of `↕n0` as table rows in lexicographical order.

---

I was working on an [Advent of Code problem](https://adventofcode.com/2015/day/9) 
that involved finding an optimal ordering, and I wanted to write a simple bruteforce solution.
So I headed over to [BQNcrate](https://mlochbaum.github.io/bqncrate/) to see how to generate all permutations of a list.

Here is the expression I found:
```
(≍↕0){∾˝(0∾˘1+𝕩)⊸⊏˘⍒˘=⌜˜↕𝕨}´-⟜↕n0
```

I had to study it for a bit to see how it worked.
(Like, what's `⍒` doing in there?)
I think it's a really cool bit of BQN, and I want to explain it here.

## Overview

The core of the above expression is a block function that takes a positive integer `n` as its left argument and a table of all permutations of `↕n-1` as its right argument and returns a table of of all permutations of `↕n`.
Using this function, we can generate all permutations of `↕n` for any `n` by starting with a table of all permutations of `↕0` and folding over the list of positive integers up to `n`.

The block function operates on the principle that we can generate all the permutations of `↕n` by doing every combination of picking a number from `↕n`, say `k`, and a permutation of `↕n-1`, say `p`. 
Then, loosely speaking, we get the permutation of `↕n` that puts `k` first and permutes the remaining values of `↕n` using `p`.

## Specifics

The table of all permutations of `↕0` is `≍↕0` above.
`↕0` makes an empty list, and solo (`≍`) adds a leading axis.
So `≍↕0` is a table with one row and zero columns, indicating that there is one and only one permutation of zero things,
and we can list what goes where with an empty list.

The list `-⟜↕n0` expands to `n0-↕n0` which the same as `⌽1+↕n0`, a list of positive integers `⟨n0,n0-1,...,1⟩`.

```
   -⟜↕4
⟨ 4 3 2 1 ⟩
```

We need a descending list because BQN's fold works right to left.

Now for the block.
The first step is generating an identity matrix.

```
   =⌜˜↕4
┌─
╵ 1 0 0 0
  0 1 0 0
  0 0 1 0
  0 0 0 1
          ┘
```

This is the standard identity matrix idiom.
Self (`˜`) is used to pass `↕4` as both arguments to `=⌜` which then returns a table comparing every pair of elements of `↕4`.
Since each element of `↕4` is unique, the only 1s are on the diagonal.

The next step is using `⍒` on each row.

```
   ⍒˘=⌜˜↕4
┌─
╵ 0 1 2 3
  1 0 2 3
  2 0 1 3
  3 0 1 2
          ┘
```

Grade down (`⍒`) returns the indices that would stably sort its input in descending order.
Cells (`˘`) applies a function to the major cells of an array, which for a table are its rows.
Since each row has a single 1 and then a bunch of 0s, grade down returns the index of the 1 and then the rest of the indices in ascending order.

At this point each row represents the whole collection of permutations that start with the same number the row starts with.
To get all the permutations, we need to permute the last 3 elements of each row in every possible way.
For example, to get every permutation starting with `1`, we need to apply all 6 permutations of 3 things to the last 3 elements of the second row.

By assumption, the right argument of the block is a table of permutations `↕3`,
which I'll just list out here as `p`.

```
   p ← [0‿1‿2,0‿2‿1,1‿0‿2,1‿2‿0,2‿0‿1,2‿1‿0]
┌─
╵ 0 1 2
  0 2 1
  1 0 2
  1 2 0
  2 0 1
  2 1 0
        ┘
```

To turn a permutation of `↕3` into a permutation of `↕4` that leaves the first element unchanged,
we add `1` and prepend a `0`.

```
   0∾˘1+p
┌─
╵ 0 1 2 3
  0 1 3 2
  0 2 1 3
  0 2 3 1
  0 3 1 2
  0 3 2 1
          ┘
```

Addition is pervasive, so `1+p` increments every number in `p`.
Join to (`∾`) with cells (`˘`) is used to prepend a `0` to each row.

The next step is to apply each modified permutation to each row of the table from above.
```
   (0∾˘1+p)⊸⊏˘⍒˘=⌜˜↕4
┌─
╎ 0 1 2 3
  0 1 3 2
  0 2 1 3
  0 2 3 1
  0 3 1 2
  0 3 2 1

  1 0 2 3
  1 0 3 2
  1 2 0 3
  1 2 3 0
  1 3 0 2
  1 3 2 0

  2 0 1 3
  2 0 3 1
  2 1 0 3
  2 1 3 0
  2 3 0 1
  2 3 1 0

  3 0 1 2
  3 0 2 1
  3 1 0 2
  3 1 2 0
  3 2 0 1
  3 2 1 0
          ┘
```

Select (`⊏`) (i.e. indexing) is used to apply a permutation.
We bind (`⊸`) the table of modified permutations to `⊏` and then use `˘` on the whole thing.
This makes a one argument function that permutes each row in all six ways,
returning a table for each row.

The last step of the block function is the join all the tables into one long table.
```
   ∾˝(0∾˘1+p)⊸⊏˘⍒˘=⌜˜↕4
┌─
╵ 0 1 2 3
  0 1 3 2
  0 2 1 3
  0 2 3 1
  0 3 1 2
  0 3 2 1
  1 0 2 3
  1 0 3 2
  1 2 0 3
  1 2 3 0
  1 3 0 2
  1 3 2 0
  2 0 1 3
  2 0 3 1
  2 1 0 3
  2 1 3 0
  2 3 0 1
  2 3 1 0
  3 0 1 2
  3 0 2 1
  3 1 0 2
  3 1 2 0
  3 2 0 1
  3 2 1 0
          ┘
```

Join to (`∾`) joins arrays along their leading axis, rows for tables.
Calling it with insert (`˝`) joins all the tables together, like a fold.

And that's that pretty much.
Using a right to left fold, we just repeatedly call that block, growing our table of permutations.
I like the use of fold where my first instinct is recursion,
and I like the clever use of grade down on the identity matrix.

Happy permuting! <3
