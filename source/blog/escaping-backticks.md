# Escaping backticks in my BQN site generator

01/29/2023

Updating my BQN site generator to allow backticks inside inline code sections.

---

The [first version of my BQN site generator](site-generator-docs-0.md) didn't allow any escaping of backticks within a backtick delimited inline code section.
This is pretty annoying when writing BQN, since the backtick is a crucial one-modifier, Scan.

But now check it out: `+``↕10`.
Inline code with a backtick inside it!

The syntax for this is like BQN's strings: a backtick starts an inline code section and a second backtick ends the section unless it is immediately followed by a second backtick, in which case the pair of backticks is treated as a single backtick and the code section continues.

So what I typed to get `+``↕10` was ```+````↕10```.

As I mentioned, this is how BQN strings work, so I'm sure there's something instructive in the self-hosted compiler. 
One day I'll look at it, but for now I decided I would rather just write something myself.

## The change

Line 8 changed from
```
lines {∾⍟(1<≡)("<code>"‿"</code>"⥊˜≠)⌾(('`'=𝕩)⊸/)𝕩}¨⌾((¬b)⊸/)↩
```
to
```
lines {o←(>⟜»∨>⟜«)≠`⊸∨t←'`'=𝕩 ⋄ ∾⍟(1<≡)(¬<`t∧¬o)/("<code>"‿"</code>"⥊˜≠)⌾(o⊸/)𝕩}¨⌾((¬b)⊸/)↩
```

This is now a really long and ugly line.
But honestly the whole script is written to be replaced,
and I'm documenting how this line works in this blog post, so I'm not super concerned.

## How it worked before

The line schematically looks like `lines {--block--}¨⌾((¬b)⊸/)↩`.

The `lines` on the left and `↩` all the way on the right tell us that we are modifying `lines` with the monadic function in the middle.

The variable `b` is a mask for the lines of the markdown file, where a 1 means that the line is part of a code block and a 0 means that a line is not part of a code block.
So the part on the far right `⌾((¬b)⊸/)` means that the block is only applied to lines that are not part of a code block. I.e. we don't allow inline code inside a code block.

The block gets applied to Each (`¨`) line, `𝕩`.
The Under, `⌾(('``'=𝕩)⊸/)`, grabs all the backticks in the line, does something to them, and then puts the results back in place of the backticks.
The "something" done to the backticks is the fork `("<code>"‿"</code>"⥊˜≠)`,
which reshapes the pair of opening and closing code tags so there are as many tags as backticks.
Thus, each opening backtick is replaced with an opening tag and each closing backtick with a closing tag.

Finally, `∾⍟(1<≡)` joins everything together if the depth of the list is greater than 1.
Depth greater than 1 happens when we've replaced a backtick (a character) with a code tag (a string), and that's when we need to join back into a string.
If we've made no replacements, then we already have just a string, we don't need to join, and attempting the join results in an error.

## How it works now

The overall strategy is the same; only the block has changed.
The block now has two statements in it.
The first statement calculates a mask of unescaped or "outer" (hence `o`) backticks.
The second statement replaces the outer backticks with code tags, just like before,
but now before joining it filters out one backtick from each pair of escaped/inner backticks.

To calculate the outer backticks, first we get a mask of all backticks `t`.

```
   a ← "So what I typed to get `+``↕10` was ```+````↕10```."
   t←'`'=a
⟨ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 1 1 0 0 0 1 0 0 0 0 0 1 1 1 0 1 1 1 1 0 0 0 1 1 1 0 ⟩
```

Then we use the `≠``⊸∨` trick to "fill-in" between the backticks.
A `≠``` flips between 0 and 1 every time it hits a 1.
When it hits the first backtick it makes everything 1 until the the second backtick at which point it becomes 0.
Then everything stays 0 until it hits the third backtick, at which point everything becomes 1s until the fourth backtick.
Since it changes back to 0 at the even number backticks, we need the `⊸∨` part to add the even number backticks back in.

```
   ≠`⊸∨t←'`'=a
⟨ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 ⟩
```

Now we need to get the outer 1s of each group of 1s.
Those are values that are either strictly greater than the value before them
or strictly greater than the value after them.
This is exactly what the fork `>⟜»∨>⟜«` does.

```
   o←(>⟜»∨>⟜«)≠`⊸∨t←'`'=a
⟨ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 ⟩
   a↩'_'¨⌾(o⊸/)a
"So what I typed to get _+``↕10_ was _``+````↕10``_."
```

For illustrative purposes, I've replaced the outer backticks with underscores.
There's the first statement of the block down.

Now we just need to filter out one of each pair of inner backticks.
The inner backticks are just `t∧¬o`, all the backticks without the outer ones.

```
   t∧¬o
⟨ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 1 1 0 1 1 1 1 0 0 0 1 1 0 0 ⟩
```

To filter out one of the backticks from each pair at first I tried `(¬∧⟜«t∧¬o)/`.
The critical part, `∧⟜«`, checks if a value is 1 and the next value is 1.
But that doesn't work since it will turn a whole run of backticks into a single backtick.

```
   (¬∧⟜«t∧¬o)/a
"So what I typed to get _+`↕10_ was _`+`↕10`_."
```

We're supposed to have 2 backticks after the second `+`, not just 1.

We need an operation that removes every other 1 from a run of 1s.
It turns out that this is exactly what `<``` does.

```
   (¬<`t∧¬o)/a
"So what I typed to get _+`↕10_ was _`+``↕10`_."
```

Weird but useful.
When the `<` scan hits a 1 after a 0, it outputs 1, but when it hits a 1 after a 1 it outputs 0.
(I didn't realize this on my own by the way! I saw this trick in some code Marshall wrote somewhere.)

And there you have it, BQN-style escaping implemented in BQN!

Happy array programming! <3
