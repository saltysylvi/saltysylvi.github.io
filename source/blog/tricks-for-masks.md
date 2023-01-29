# Tricks for working with masks in BQN

xx/xx/2023

A collection of techniques for manipulating boolean lists in BQN, mostly using shifts and scans.

---

In this post "mask" means a list of boolean (0 or 1) values.

Many BQN programs rely on effectively manipulating masks.
One common pattern is using a mask as a left argument to Replicate `/` to filter the right argument.
Another common pattern is to use a mask as an intermediate form for a left argument to Group `⊔`.
For example, we might have a mask where each 1 represents the start of a contiguous subgroup.
Then taking a sum scan of the mask gives each subgroup a different number for using with Group.

BQN has excellent facilities for working with masks, but when first seen these techniques can look very strange and confusing.
This post provides a reference for what various shifts and scans do to masks.

## Dyadic boolean functions

There are 16 dyadic boolean functions:
There are the 2 constant functions: `0˙` and `1˙`.
There are the 4 functions that only depend on one argument: `⊣`, `⊢`, `¬∘⊣`, and `¬∘⊢`.
And then there are 10 functions that depend on both arguments: `∧`, `∨`, `¬∘∧`, `¬∘∨`, `=`, `≠`, `<`, `>`, `≤`, and `≥`.
These last 10 are the ones that are generally interesting and useful for manipulating masks.

Some things to note:

Each boolean function is [pervasive](https://mlochbaum.github.io/BQN/doc/arithmetic.html#pervasion), so it automatically applies elementwise when passed two equal length masks.

The functions `∧`, `∨`, `¬∘∧`, and `¬∘∨` look like boolean functions, while the rest are usually thought of as more general comparison functions.
When restricted to booleans however,

## Shifts

Let's record what each of the 10 "interesting" boolean functions does when used with a shift.
By that I mean something like `≠⟜»`, where we compare a mask to a left or right shift of itself.

In general, `F⟜»` is equivalent to `»⊸(F˜)` and closely related to `«⟜F`, `F˜⟜«`
The first one says `current F previous`.
The second one says `previous F˜ current`, which is to say `current F previous`.
The third one says `next F current`.
The fourth one says `current F˜ next`, which is to say `next F Current`.
So the first pair and the second pair differ only at the edge...maybe I can prove some equivalency using another shift.

## Scans

Let's observe what each of the 16 functions does as a scan.

`∧` scan stays 1 so long as input is 1, and then at the first 0 switches to 0 and stays 0.
Example: counting leading #s for markdown headings.

`∨` scan stays 0 so long as input is 0, and then at the first 1 switches to 1 and stays 1.

`<` scan has the effect of replacing any 1 that immediately follows another 1 with 0.
Ehh, not a good explanation.
Example: Marshall's sequence splitting code.