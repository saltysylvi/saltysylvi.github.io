# Boolean scans in BQN

02/08/2023

Documenting the effects of all 16 boolean scans.

---

I used `<``` in my [other post](escaping-backticks.md),
but I only knew to reach for that trick because I had seen it in the documentation.
At least for me, it's not so obvious what a scan like that will do before I sit down and work it out.
So I wonder, what other cool scan tricks am I missing out on?

Thankfully, I don't have to wonder.
Since there's only 16 possible boolean scans, we can just exhaustively work out what each one does.

## Dyadic boolean functions

By boolean scan, I mean `F``` where `F` is a dyadic function from booleans to booleans.

There are 16 dyadic boolean functions:  
There are the 2 constant functions: `0˙` and `1˙`.  
There are the 4 functions that only depend on one argument: `⊣`, `⊢`, `¬∘⊣`, and `¬∘⊢`.  
And then there are 10 functions that depend on both arguments: `∧`, `∨`, `¬∘∧`, `¬∘∨`, `=`, `≠`, `<`, `>`, `≤`, and `≥`.  
These last 10 are the ones that are generally interesting and useful.

Of those 10 functions `∧`, `∨`, `¬∘∧`, and `¬∘∨` look like boolean functions, while the rest are usually thought of as more general comparison functions.
They are perfectly good boolean functions, however.
For instance, when restricted to booleans, `≠` is just XOR and `≤` is `¬⊸∨`, aka the material conditional.

## Symmetry

It turns out that `F``⌾¬` is equivalent to `F⌾¬```.
It's not that deep or anything.
The former flips all the booleans once at the beginning, does the scan, and then flips the result.
The latter, as it scans along, flips each boolean argument to `F`, applies `F`, and then flips the result back.
The end result is the same: each argument of `F` has been flipped on the way in, and each result of `F` has been flipped on the way out.

I'll call `F⌾¬` the "De Morgan dual" of `F`, or just dual for short.
So, modulo that symmetry, there are even less boolean scans.
10 of them, in fact.
We might expect to get 8 pairs, but all 4 of the one-argument boolean functions are self-dual.

This might seem abstract, but making use of this fact is fairly straightforward.
We basically just switch the 0s and 1s around.
For example, `∧``` keeps only leading 1s. 
Since the De Morgan dual of `∧` is `∨`, we can quickly deduce that `∨``` keeps only leading 0s.

Here are the 10 dual pairs:
```
0    1
⊣    ⊣
⊢    ⊢
¬∘⊣  ¬∘⊣
¬∘⊢  ¬∘⊢
∧    ∨
¬∘∧  ¬∘∨
≠    =
<    ≤
>    ≥
```

## Scans

Let's observe what each of the 10 scans in the left column of the above table do.
The scans in the right column do the same things, but with 0 and 1 switched.

---

`0``` just gives back the first element of the list and then all 0s.

I can't think of a good use of this off the top of my head,
though I suppose it might be useful somewhere.

---

`⊣``` is the same as `≠⥊⊏`.
It always returns the first element repeatedly.

`⊢``` is just `⊢`!
It does nothing.

`¬∘⊣``` returns a list of alternating 0s and 1s, starting with whichever one started the original list.

`¬∘⊢``` negates every element but the first one.

None of these seems very useful, but you never know.

---

`∧``` stays 1 so long as the input is 1, and then at the first 0 switches to 0 and stays 0.

Example: counting leading #s for markdown headings
```
   +´'#'="### Heading 3 # blah #"
5
   +´∧`'#'="### Heading 3 # blah #"
3
```
The first line just tells us there are 5 #s in the string, which is not what we want.
Adding an `∧``` keeps only the leading #s.

---

`¬∘∧``` flips every 0 (except the first 0 when the input starts with 0) and turns off every other 1 in a run of 1s.
If the first run of 1s is at the very start or after a single 0, then every second 1 in that run is turned off.
For any other run of 1s, the first, third, fifth, etc. 1s are turned off.

That's the best description I could make of this one.

Example: if we give a left argument to start the scan with, it can be used to remove escaping backslashes.
Though I'd probably just stick to `<``` for this (see below).
```
   s ← "foo\nbar \\baz\\\\"
   (¬∘∧` '\'=s) / s
"oonbar \baz\\"
   (⊑⊸(¬∘∧`) '\'=s) / s
"foonbar \baz\\"
```
Using `¬∘∧` we can remove all the escaping backslashes.
This would be most useful after replacing the escaped characters, but I don't show that here.
The first attempt accidentally removes the starting `f` since a starting 0 doesn't get flipped.
Giving a left argument of 0 to the scan would flip the starting 0 and give us the correct result here.
However, if the string started with a backslash, then we'd need a left argument of 1 to make sure that starting backslash gets dropped.
So the left argument that works in both cases is `⊑`, the first element of the input.

---

`≠``` flips all the 0s between two 1s, up to but not including the second 1.

Example: Extract characters between parentheses.
```
   s ← "abc(defg)ijkl(m)"
   s∊"()"
⟨ 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 1 ⟩
  ≠`s∊"()"
⟨ 0 0 0 1 1 1 1 1 0 0 0 0 0 1 1 0 ⟩
  0⌈≠`⊸-s∊"()"
⟨ 0 0 0 0 1 1 1 1 0 0 0 0 0 0 1 0 ⟩
  (0⌈≠`⊸-s∊"()")/s
"defgm"
```
The tricky bit here (other than the `≠```) subtracts the mask of parens from the `≠` scanned mask and then replaces negative numbers with 0.
This has the effect of removing the opening parens from the mask.
We could equivalently subtract a separate mask of just opening parens and then not need the `⌈` part.

---

`<``` has the effect of turning off every other 1 in a run of 1s.

Example: backslash escaping in strings.
```
   s ← "foo\nbar \\baz\\\\"
   '\'=s
⟨ 0 0 0 1 0 0 0 0 0 1 1 0 0 0 1 1 1 1 ⟩
   <`'\'=s
⟨ 0 0 0 1 0 0 0 0 0 1 0 0 0 0 1 0 1 0 ⟩
```
The second line is a mask of all backslashes, while the third line is mask of only the backslashes that are escaping another character.

---

`>``` starts with a 1 if the input does (obviously), and then continues outputting 1s until the next 1.
It's a little bit like `≠``` in that it flips all the 0s between two 1s,
and it's a little bit like `∧``` in that the output is a run of 1s and then the rest is 0s.

Example: maybe there's some kind of text format where a line has an optional part at the beginning in square brackets, the bracketed part must be at the very beginning, and any square brackets later in the line don't have the same meaning.
```
   s ← "[red=true]Some text and some [foo]."
   s∊"[]"
⟨ 1 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 ⟩
   >`s∊"[]"
⟨ 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ⟩
   0⌈>`⊸-s∊"[]"
⟨ 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 ⟩
   (0⌈>`⊸-s∊"[]")/s
"red=true"
```
This code extracts any text in brackets but only if they are at the very beginning of the line.
I used the same `0⌈` trick as in the `≠``` example to remove the opening bracket.

## Conclusion

It looks like the boolean scans to be aware of are `∧`, `≠`, and `<`, as well as their duals.
The rest don't have the same level of applicability, as far as I can tell anyway.
This aligns with the fact that the only boolean scans I've used or seen others use are `∧`, `∨`, `≠`, and `<`.
So, while I'm glad to have checked, I guess I wasn't missing out on any cool useful scans.
Oh well.

Happy scanning! <3
