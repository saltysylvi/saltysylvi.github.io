# Flat array programming 2

10/04/2023

Using flat array techniques to parse natural numbers from a string.

---

This is my second post exploring flat array programming.
[Last time](flat1.md) we learned how to perform partitioned reverse, mesh, and expand.
Today we're going to learn partitioned plus fold and partitioned plus scan.
Then we'll put everything together to parse the natural numbers from a string, without splitting the string!

## A note on terminology

The [Bob Smith paper](https://dl.acm.org/doi/10.1145/390009.804488) discusses techniques for performing "partitioned" operations on lists.
Let's discuss what that means so that we can benefit from the terminology.

We're given two lists, `p` and `b`, where `p` is boolean list whose `1`s mark the partition starts and `b` is a list we're thinking of as being partitioned, that is, comprised of sublists.

Here is an example.
```
    p ← 1‿0‿0‿0‿1‿0‿1‿0‿0
    b ← "abcdijxyz"
    p≍b
┌─
╵ 1   0   0   0   1   0   1   0   0
  'a' 'b' 'c' 'd' 'i' 'j' 'x' 'y' 'z'
                                      ┘
```

In BQN we can use `(¯1+``p)⊔b` to actually split up the partitions.
```
    p
⟨ 1 0 0 0 1 0 1 0 0 ⟩
    +`p
⟨ 1 1 1 1 2 2 3 3 3 ⟩
    ¯1+`p
⟨ 0 0 0 0 1 1 2 2 2 ⟩
    (¯1+`p)⊔b
⟨ "abcd" "ij" "xyz" ⟩
```

Given a function `F`, "partitioned `F`" means splitting a list into sublists, applying `F` to each sublist, and joining the resulting lists back together.
For example, here is partitioned reverse.
```
    ∾⌽¨(¯1+`p)⊔b
"dcbajizyx"
```

Following the paper, we can encapsulate this idea in a 2-modifier.
(Note that the paper really just introduces notation, not a modifier.)
```
    _part_ ← {∾⍟(1<≡)𝔾¨(¯1+`𝕗)⊔𝕩}
    p _part_ ⌽ b
"dcbajizyx"
```

We use `∾⍟(1<≡)` instead of plain `∾` to join only if the list is nested.
For example, if we did a partitioned plus fold, the result of each plus fold is a number, not a list,
so there is nothing to join, and in fact join will error.

Anyway, the amazing thing is, as we saw last time,
we don't need to actually do the splitting and joining to compute partitioned reverse.

```
    b⊏˜⌽⍒+`p
"dcbajizyx"
```

So when I say we're going to learn partitioned plus fold and partitioned plus scan,
what I mean is we're going to learn how to simulate `p _part_ (+´) b` and `p _part_ (+``) b` without actually splitting up `b`.

## Partitioned plus fold

Here's the example we're going to work out.
```
    p ← 1‿0‿0‿0‿1‿0‿1‿0‿0
    b ← 1‿2‿3‿4‿100‿200‿9‿10‿11
    p _part_ (+´) b
⟨ 10 300 30 ⟩
    -⟜»(1⌽p)/+`b
⟨ 10 300 30 ⟩
```

First we take the plus scan of `b`.
```
    +`b
⟨ 1 3 6 10 110 310 319 329 340 ⟩
```

The next idea is that `1⌽p` indicates the partition end points.
Each partition start point is one place to the right of the previous partitions endpoint,
including the first partition start point if we count that as one past the end.

```
    p≍b
┌─
╵ 1 0 0 0   1   0 1  0  0
  1 2 3 4 100 200 9 10 11
                          ┘
    (1⌽p)≍b
┌─
╵ 0 0 0 1   0   1 0  0  1
  1 2 3 4 100 200 9 10 11
                          ┘
```

Let's look at the value of the plus scan at the partition endpoints.

```
    (1⌽p)≍+`b
┌─
╵ 0 0 0  1   0   1   0   0   1
  1 3 6 10 110 310 319 329 340
                               ┘
    (1⌽p)/+`b
⟨ 10 310 340 ⟩
```

The first one, `10`, is the plus fold of the first partition.
The second one, `310`, is almost the plus fold of the second partition,
but of course it's too large by `10` because we've included everything from the first partition.
Similarly, `340`, is too large by `310`
because we've included the sum of the first two partitions.

To account for this, we subtract the previous value from each,
with the previous value of the first being `0`, since it's already correct.
This is exactly what `-⟜»` does.

```
    -⟜»(1⌽p)/+`b
⟨ 10 300 30 ⟩
```

Voila!

## Partitioned plus scan

Partitioned plus scan combines partitioned plus fold and expand.
Here's how it looks.

```
    p ← 1‿0‿0‿0‿1‿0‿1‿0‿0
    b ← 1‿2‿3‿4‿100‿200‿9‿10‿11
    p _part_ (+`) b
⟨ 1 3 6 10 100 300 9 19 30 ⟩
    +`b-(⍋⍋p)⊏(-≠p)↑-⟜»p/+`»b
⟨ 1 3 6 10 100 300 9 19 30 ⟩
```

Let's break it down.
The overall idea is to compute the partitioned plus scan with one big plus scan over a modified `b`.
If we just did `+``b`, we'd get the right result for the first partition, but for the second partition we'd be off by the sum of the first partition.

```
    +`b
⟨ 1 3 6 10 110 310 319 329 340 ⟩
    #      ↑ too high by 10 starting here
```

We can fix that by subtracting the sum of the first partition from `b` at the start of the second partition.
This effectively "resets" the plus scan at the second partition.

```
    #         ↓ subtract 10 here, 100 becomes 90
    +`1‿2‿3‿4‿90‿200‿9‿10‿11
⟨ 1 3 6 10 100 300 309 319 330 ⟩
    #      ↑ fixed!
```

Now at the third partition, we're be off by the sum of the second partition, so we need to do the same trick. 
```
    #                ↓ subtract 300 here
    +`1‿2‿3‿4‿90‿200‿¯291‿10‿11
⟨ 1 3 6 10 100 300 9 19 30 ⟩
    #              ↑ fixed!
```

To get the adjustments we need, we can do a partitioned plus fold, and then shift in a `0`.

```
    -⟜»(1⌽p)/+`b
⟨ 10 300 30 ⟩
    »-⟜»(1⌽p)/+`b
⟨ 0 10 300 ⟩
```

It ends up being a few characters shorter if we shift in the `0` at the start because then we can avoid rotating `p`.
The idea is still the same though.

```
    -⟜»p/+`»b
⟨ 0 10 300 ⟩
```

Now we need to get these numbers into position for subtracting from `b`.
This calls for expand.

```
    (⍋⍋p)⊏(-≠p)↑-⟜»p/+`»b
⟨ 0 0 0 0 10 0 300 0 0 ⟩
```

Finally we just subtract and plus scan.

```
    b-(⍋⍋p)⊏(-≠p)↑-⟜»p/+`»b
⟨ 1 2 3 4 90 200 ¯291 10 11 ⟩
    +`b-(⍋⍋p)⊏(-≠p)↑-⟜»p/+`»b
⟨ 1 3 6 10 100 300 9 19 30 ⟩
```

Clever, right?

## Parsing numbers

Now that we've built up some tools, let's apply them to a little parsing problem.
We're given a string and we want to parse all the natural numbers out of it into a list.
This is a pretty standard thing to have to do for Advent of Code, for example.

First let's show how we would handle a single string of digits.

The first step is to turn characters into single digit numbers using character arithmetic.
```
    s ← "12345"
    s-'0'
⟨ 1 2 3 4 5 ⟩
```

Next we get the powers of 10 to multiply each digit by.
```
    ↕≠s
⟨ 0 1 2 3 4 ⟩
    ⌽↕≠s
⟨ 4 3 2 1 0 ⟩
    10⋆⌽↕≠s
⟨ 10000 1000 100 10 1 ⟩
```

Finally, we multiply and sum.
```
    (s-'0') × 10⋆⌽↕≠s
⟨ 10000 2000 300 40 5 ⟩
    +´ (s-'0') × 10⋆⌽↕≠s
12345
```

Let's think about which operations we used and how we could apply them to a partitioned string of digits.

First we subtract `'0'` from each substring.
That will implicitly happen if we just subtract `'0'` from the whole string.

Next we do `↕≠` on each partition.
We can construe this as the plus scan of an all `1`s list, minus `1`.
```
    ↕≠s
⟨ 0 1 2 3 4 ⟩
    (+`1‿1‿1‿1‿1)-1
⟨ 0 1 2 3 4 ⟩
```
We can do partitioned plus scan, and as we just mentioned partitioned subtraction is automatic.

Next we have to do partitioned reverse, which is no problem.

Then we have partitioned exponentiation and partitioned multiplication, both of which are automatic.
And finally, we know how to perform partitioned plus fold, so we have everything we need.

Here's how we construct `p` and `b`.

```
    test ← "17 apples, 200 pears, and 3 cabbages"
    d ← test∊'0'+↕10
⟨ 1 1 0 0 0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 ⟩
```

`d` is a mask of digit locations.

```
    b ← (d/test)-'0'
⟨ 1 7 2 0 0 3 ⟩
```

`b` is a list of all the digits from `test`.
I went ahead and did the `'0'` subtraction here.

To get `p`, we need to find the locations where there is a digit after a non-digit.
That's where `d` is greater than its previous value.
```
    >⟜» d
⟨ 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 ⟩
    p ← d/>⟜»d
⟨ 1 0 1 0 0 1 ⟩
```

And now we just put together all the partitioned operations on `p` and `b`.

```
    # partitioned plus scan
    Pps ← {+`𝕩-(⍋⍋𝕨)⊏(-≠𝕩)↑-⟜»𝕨/+`»𝕩}

    # partitioned plus fold
    Ppf ← {-⟜»(1⌽𝕨)/+`𝕩}

    # partitioned reverse
    Pr ← {𝕩⊏˜⌽⍒+`𝕨}

    (≠p)⥊1
⟨ 1 1 1 1 1 1 ⟩
    p Pps (≠p)⥊1
⟨ 1 2 1 2 3 1 ⟩
    1 -˜ p Pps (≠p)⥊1
⟨ 0 1 0 1 2 0 ⟩
    p Pr 1 -˜ p Pps (≠p)⥊1
⟨ 1 0 2 1 0 0 ⟩
    10 ⋆ p Pr 1 -˜ p Pps (≠p)⥊1
⟨ 10 1 100 10 1 1 ⟩
    b × 10 ⋆ p Pr 1 -˜ p Pps (≠p)⥊1
⟨ 10 7 200 0 0 3 ⟩
    p Ppf b × 10 ⋆ p Pr 1 -˜ p Pps (≠p)⥊1
⟨ 17 200 3 ⟩
```

## Condensing

We can simplify the all `1`s partitioned plus scan a whole bunch.

```
    # original
    p {+`𝕩-(⍋⍋𝕨)⊏(-≠𝕩)↑-⟜»𝕨/+`»𝕩} (≠p)⥊1

    # plug in p for 𝕨 and (≠p)⥊1 for 𝕩
    +`((≠p)⥊1)-(⍋⍋p)⊏(-≠((≠p)⥊1))↑-⟜»p/+`»(≠p)⥊1

    # ((≠p)⥊1)- is just 1- ; length of (≠p)⥊1 is ≠p
    +`1-(⍋⍋p)⊏(-≠p)↑-⟜»p/+`»(≠p)⥊1

    # +`»(≠p)⥊1 is ↕≠p
    +`1-(⍋⍋p)⊏(-≠p)↑-⟜»p/↕≠p

    # p/↕≠p is /p
    +`1-(⍋⍋p)⊏(-≠p)↑-⟜»/p

    # tacit for funsies
    +`1-⍋∘⍋⊏-∘≠↑·-⟜»/
```

Just for fun let's golf it all into one terse function.

```
    Nats ← {
        p←d/>⟜»d←𝕩∊'0'+↕10 ⋄ b←'0'-˜d/𝕩
        e←(⌽+`⍒⊸⊏¯1+`1-⍋∘⍋⊏-∘≠↑·-⟜»/)p
        -⟜»(1⌽p)/+`b×10⋆e
    }
    Nats "17 apples, 200 pears, and 3 cabbages"
⟨ 17 200 3 ⟩
```

Ridiculous!

## Conclusion

I hope you enjoyed this little exploration of the flat array programming style.
I think it's cool how all the ideas build on each other and come together to make something useful.
It looks hard at first, but it's really not too hard to get the hang of it once you've seen a few examples.
I guess the same could be said of array programming as a whole.

Happy array programming, and keep it flat! <3
