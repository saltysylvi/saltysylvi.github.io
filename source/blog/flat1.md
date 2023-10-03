# Flat array programming 1

10/03/2023

Exploring array programming without nested arrays in BQN.

---

In [the latest episode of the Array Cast](https://www.arraycast.com/episodes/episode63-uiua), there was a brief discussion of how you can accomplish a surprising amount with just flat arrays.
Avoiding nesting was necessary in the olden days of APL simply because there were no nested arrays!
As Adám pointed out, these "olden days" were actually when people were making money using APL,
so it must not have been impossible to get work done with only flat arrays.
How did they do it?

Marshall mentioned [a classic paper by Bob Smith](https://dl.acm.org/doi/10.1145/390009.804488) that outlines techniques for simulating a list of lists using only flat lists.
I've been enjoying studying the paper as well as the old [FinnAPL idiom library](https://aplwiki.com/wiki/FinnAPL_idiom_library) to learn more about flat array techniques.
I feel like there's something really beautiful about this old-school style,
so I want to help pass it on to new-school BQN programmers who are perhaps less likely than APL programmers to connect with the APL tradition.

It is also worth noting that avoiding nested arrays often leads to more performant code, so there is a practical as well as aesthetic value to these techniques.
I won't be investigating performance in this post, however.

## Reversing each word in a sentence

In the aforementioned episode of the Array Cast, Conor brought up the problem of reversing each word in a sentence.
He noted that in a nested approach you just split, reverse each, and join.
Surely the flat solution is unwieldly compared to that!
Marshall pointed out that, well no, it's pretty short.
You just find the word starts, sum, and grade down or something like that.
Let's break down both approaches and compare them.

Both approaches will first construct a list that controls how the sentence will be partitioned.
Each space will be considered its own word, since this is a simple way to keep the original spacing after reversing each word.
```
    s ← "here are some words"
    ' '=s
⟨ 0 0 0 0 1 0 0 0 1 0 0 0 0 1 0 0 0 0 0 ⟩
    ∨⟜»' '=s
⟨ 0 0 0 0 1 1 0 0 1 1 0 0 0 1 1 0 0 0 0 ⟩
    p ← +`∨⟜»' '=s
⟨ 0 0 0 0 1 2 2 2 3 4 4 4 4 5 6 6 6 6 6 ⟩
```
We start a new partition on each space and each character after a space.

The nested approach groups `s` using `p`, reverses each, and joins.
```
    p⊔s
⟨ "here" " " "are" " " "some" " " "words" ⟩
    ⌽¨p⊔s
⟨ "ereh" " " "era" " " "emos" " " "sdrow" ⟩
    ∾⌽¨p⊔s
"ereh era emos sdrow"
```

Now the flat approach.
The key is `⍒p`.
```
    p
⟨ 0 0 0 0 1 2 2 2 3 4 4 4 4 5 6 6 6 6 6 ⟩
    ⍒p
⟨ 14 15 16 17 18 13 9 10 11 12 8 5 6 7 4 0 1 2 3 ⟩
    (⍒p)⊏s
"words some are here"
```
Interesting! We've reversed the string, but on the level of words, not characters.

Grade down gives the indices that would stably sort `p` into descending order.
The stability is important! It makes sure the letters in each word stay in order.
For example, the largest values in `p` are all the `6`s, corresponding to the last word.
So those get moved to the front, and since they all tie, they are left in order.
Next comes the `5`, which is the space before the last word.
Then all the `4`s, in original order. Etc.

To reverse each word, we just need to reverse the whole string again.
Or equivalently, reverse `⍒p` before indexing.
```
    ⌽(⍒p)⊏s
"ereh era emos sdrow"
    (⌽⍒p)⊏s
"ereh era emos sdrow"
    s⊏˜⌽⍒p
"ereh era emos sdrow"
```

In terms of character count, it's a tie!
```
    ∾⌽¨p⊔s
    s⊏˜⌽⍒p
```

## Mesh

Here's a cool one from the FinnAPL idiom library.
```
    x ← "abcd"
    y ← "XYZ"
    g ← 0‿0‿1‿0‿1‿1‿0
    (⍋⍋g)⊏x∾y # Mesh
"abXcYZd"
```
[Mesh](https://aplwiki.com/wiki/Mesh) generalizes `∾`: we join two lists `x` and `y` together but not necessarily in order.
A third list `g` specifies the order.
Each `0` in `g` means pick the next element of `x`, and each `1` in `g` means pick the next element of `y`.

How does it work? The `⍋⍋` is the [ordinals pattern](https://mlochbaum.github.io/BQN/doc/order.html#ordinals): it says what rank each element of `g` has, where rank `0` means smallest, `1` means next smallest, etc.
```
   g
⟨ 0 0 1 0 1 1 0 ⟩
   ⍋⍋g
⟨ 0 1 4 2 5 6 3 ⟩
```
The `0`s in `g` get ranks `0` to `3` in the order they appear in `g`, while the `1`s in `g` get ranks `4` to `6` in the order they appear in `g`.
And what do you know, these ranks are exactly the indices in `x∾y` of the elements of `x` and `y` we want to pick.

## Expand

[Expand](https://aplwiki.com/wiki/Expand) is an APL primitive that BQN doesn't have.
Marshall suggests `{𝕩⌾(𝕨⊸/)𝕨≠⊸↑0↑𝕩}` as a replacement in the [BQN-Dyalog APL dictionary](https://mlochbaum.github.io/BQN/doc/fromDyalog.html#for-writing).

```
   1‿0‿0‿1‿0‿1 {𝕩⌾(𝕨⊸/)𝕨≠⊸↑0↑𝕩} 97‿98‿99
⟨ 97 0 0 98 0 99 ⟩
   1‿0‿0‿1‿0‿1 {𝕩⌾(𝕨⊸/)𝕨≠⊸↑0↑𝕩} "ABC"
"A  B C"
```

Basically, expand takes a boolean left argument with as many `1`s as the length of the right argument
and replaces each `1` by the corresponding element of the right argument and each `0` by the fill of the right argument.

The definition above uses `0↑𝕩` to get the fill element, and then `𝕨≠⊸↑` to make a length `≠𝕨` list of fills.
Finally, it uses structural under to plug in the values of `𝕩` where `𝕨` has `1`s.
It's a nice straightforward translation of the idea into code.

This approach doesn't use nested arrays, but the structural under feels icky, and it is sorely lacking both `⍋` and `⍒`, which are clearly the best glyphs.
Thus, using rules I am making up on the spot, I declare it to be not in the flat style.

Let's use mesh to implement expand, but with *style*. 😎

The idea is that expand is just mesh, but with `x` being a list of fills of the right length.
In other words, if we prepend enough fills, then we can use the ordinals trick from mesh to put everything in order. 
```
    (⍋⍋1‿0‿0‿1‿0‿1) ⊏ 0‿0‿0 ∾ 97‿98‿99
⟨ 97 0 0 98 0 99 ⟩
    (⍋⍋1‿0‿0‿1‿0‿1) ⊏ "   " ∾ "ABC"
"A  B C"
```

Using take is an easy way to get enough fills.
If we "over take" from the front we get a result with fills at the end.
If we "over take" from the back we get a result with fills at the front.

```
    10↑97‿98‿99
⟨ 97 98 99 0 0 0 0 0 0 0 ⟩
    ¯10↑97‿98‿99
⟨ 0 0 0 0 0 0 0 97 98 99 ⟩
```

Putting it all together:
```
    (⍋⍋1‿0‿0‿1‿0‿1) ⊏ ¯6↑97‿98‿99
⟨ 97 0 0 98 0 99 ⟩
    1‿0‿0‿1‿0‿1 {(⍋⍋𝕨)⊏(-≠𝕨)↑𝕩} 97‿98‿99
⟨ 97 0 0 98 0 99 ⟩
    1‿0‿0‿1‿0‿1 {(⍋⍋𝕨)⊏(-≠𝕨)↑𝕩} "ABC"
"A  B C"
```

One character shorter and `∞`% more `⍋`s!

## Conclusion

This has been just a first taste of the things you can do in BQN without nested arrays.
A recurring theme is the use of `⍋` and `⍒` to cleverly reorganize a list.
This is a major benefit of the style because `⍋` and `⍒` are really cool.
Next time, we'll put these ideas to use on a simple parsing problem.

Happy flat array programming! <3
