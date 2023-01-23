# Parsing nested lists in BQN

01/23/2023

Three ways to parse the nested lists from Advent of Code 2022 day 13 in BQN.

---

[Advent of Code 2022 day 13](https://adventofcode.com/2022/day/13) requires you to parse nested lists like 
```
   [1,[2,[3,[4,[5,6,7]]]],8,9]
```

This post covers three different ways to handle the problem:  
1. "Cheating" by using `•BQN` to do the heavy lifting  
2. Writing a conventional recursive descent parser  
3. Writing an array-style parser

We'll also do some simple benchmarking to compare the three approaches.

## The Data

We'll be using my advent of code input file to test the different approaches on.
Here's the first six lines:

```
   •Show¨ 6 ↑ input ← •FLines "13.txt"
"[[[[8,7,8,5,4],6,[4,6]]],[6,[[]]],[]]"
"[[[[8,0,0,7,1],[1],8]]]"
⟨⟩
"[[[5,8,[4,9,2],7,[8,0]],[9,5,[5,5]],[9,[3,3,8,4,8],[0,6]],5,3],[8,10,[[8,7,6,1,8],5,0,6,[5,1]],[7,[1],6],[6,2,1,[],[1,0,6,5]]],[1,1,[[2]]],[]]"
"[[10,4,[],7,[[10,1]]],[[4,2]],[[[5],[],[],[]],[4,5,[2,4,9]]],[[8,[],[1,3,9,7]],4,7]]"
⟨⟩
```

The lists come in pairs, with each pair separated by a blank line.
Since the problem requires you to compare pairs of lists,
a suitable format for working with the data is to parse it all into one list of pairs of lists.
Thus we can turn the problem into parsing one giant list.

```
   data ← ']'∾˜ '['∾ ¯1↓∾(3|↕≠input) {0𝕊𝕩: ∾'['‿𝕩‿','; 1𝕊𝕩: 𝕩∾"],"; 2𝕊𝕩: 𝕩}¨ input
```

The lines come in groups of three: the first list, the second list, and then a blank line.
The first line of each group needs an opening bracket added to the beginning (to open the pair) and a comma added to the end (to separate the two lists in the pair).
The second line of each group needs a closing bracket at the end (to close the pair) and a comma after (to separate it from the next pair).
The blank lines are fine as is.
Then we join all the lines together and drop the final trailing comma.
Finally, we need to wrap the whole thing in one more set of brackets, to make it all one big list.

## Using `•BQN`

This approach is undoubtedly the easiest, and it's what I used to solve the problem in December.
The idea is that the notation is almost valid BQN; we just need to replace the square brackets with angle brackets.
Then we can use the system function `•BQN` to "eval" the string into a BQN list.

```
   a ← "[1,2,[],[3,4]]"
   a + ('⟨'-'[') × '['=a
"⟨1,2,⟨],⟨3,4]]"
   "[⟨" (⊢ + -˜´∘⊣ × ⊏⊸=) a
"⟨1,2,⟨],⟨3,4]]"
```

Here's the idea behind replacing a character with another character using a small example.
I've written both an explicit expression and a tacit function.
We take the difference between the new character and the old character,
since adding this to the old character changes it into the new one.
Then we use a mask of old character locations to make sure the addition happens only at those locations.

Now to write our parser, we just replace both kinds of square brackets with the respective angle brackets and call `•BQN`.

```
   R ← ⊢ + -˜´∘⊣ × ⊏⊸=
   Parser1 ← •BQN "]⟩" R "[⟨" R ⊢
```

Let's try it out.

```
   Parser1 data
Segmentation fault (core dumped)
```

Uh oh! Well, here's a strike against this approach.

I'm not sure what's going on to be honest.
When I solved the problem in Decemeber I didn't do the "turn it all into one giant list" approach,
and instead parsed the individual lines.
So let's do that here.

```
   data2 ← (<¯1⊸↓)˘∘‿3⥊input∾<""
```

This complicated-looking line just works the data into a list of pairs of strings.
First we append a blank line to the end, to complete the last group of 3 lines.
Then we use a computed reshape to make an array with 3 columns.
Finally, on each row of the array we drop the the blank line and enclose the two remaining lines.

Now we just have to parse each string to get the final result.

```
   bqn ← Parser1¨¨ data2
   ⊑bqn
┌─
· ┌─                                                  ┌─
  · ┌─                              ┌─           ⟨⟩   · ┌─
    · ⟨ ⟨ 8 7 8 5 4 ⟩ 6 ⟨ 4 6 ⟩ ⟩   · 6 ⟨ ⟨⟩ ⟩          · ⟨ ⟨ 8 0 0 7 1 ⟩ ⟨ 1 ⟩ 8 ⟩
                                  ┘            ┘                                    ┘
                                                    ┘                                 ┘
                                                                                        ┘
    2↑input
⟨ "[[[[8,7,8,5,4],6,[4,6]]],[6,[[]]],[]]" "[[[[8,0,0,7,1],[1],8]]]" ⟩
```

Looks alright!
Let's do a quick benchmark.

```
   100 Parser1¨¨•_timed data2
0.074279465
```

Around 3/4 of a second for each run. So slow!

## Recursive descent

This is not meant to be an introductory tutorial on recursive descent parsing.
Rather, I want to show that "normal" algorithms are applicable in BQN.
In fact, [Singeli](https://github.com/mlochbaum/Singeli) uses a [recursive descent parser](https://github.com/mlochbaum/Singeli/blob/master/singeli.bqn#L147).

We assume that the input is error-free and proceed in a classic two-stage tokenize-then-parse fashion.

### Tokenizing

The token types are opening brackets, closing brackets, and numbers.
We get rid of the commas, after we've used them to delimit the numbers.
The tokenizer is actually array-style, I guess, since we just use `⊔` to split the string up.

Behold!

```
   T ← (1-˜≠⟜','×·+`∊⟜"[]"∨·(»⊸<)∊⟜('0'+↕10))⊸⊔
   a ← "[999,2,[],[31,4167]]"
   T a
⟨ "[" "999" "2" "[" "]" "[" "31" "4167" "]" "]" ⟩
```

Okay, okay, springing that tacit tokenizer on you is a joke.
Let's break it down.
The overall strategy is to create a mask of token starting points.
Then we're pretty much a sum scan and a group away from success.

Each opening bracket and closing bracket starts a new group.
However, a digit starts a new group iff it is not preceded by a digit.

```
   d ← '0'+↕10
"0123456789"
   a∊d
⟨ 0 1 1 1 0 1 0 0 0 0 0 1 1 0 1 1 1 1 0 0 ⟩
```

We start by finding a mask of digits in the string.

```
   (»a∊d)≍a∊d
┌─
╵ 0 0 1 1 1 0 1 0 0 0 0 0 1 1 0 1 1 1 1 0
  0 1 1 1 0 1 0 0 0 0 0 1 1 0 1 1 1 1 0 0
                                          ┘
   (»a∊d)<a∊d
⟨ 0 1 0 0 0 1 0 0 0 0 0 1 0 0 1 0 0 0 0 0 ⟩
   »⊸<a∊d
⟨ 0 1 0 0 0 1 0 0 0 0 0 1 0 0 1 0 0 0 0 0 ⟩
   a≍»⊸<a∊d
┌─
╵ '[' '9' '9' '9' ',' '2' ',' '[' ']' ',' '[' '3' '1' ',' '4' '1' '6' '7' ']' ']'
  0   1   0   0   0   1   0   0   0   0   0   1   0   0   1   0   0   0   0   0
                                                                                  ┘
```

Comparing with the shifted mask lets us check if the preceding character was also a digit.
The use of `<` is a little BQN trick.
For booleans `p` and `q`, `p<q` is true iff `p` is 0 and `q` is 1.
So now we have the start points of the number tokens.

```
   (a∊"[]")∨»⊸<a∊d
⟨ 1 1 0 0 0 1 0 1 1 0 1 1 0 0 1 0 0 0 1 1 ⟩
   a≍(a∊"[]")∨»⊸<a∊d
┌─
╵ '[' '9' '9' '9' ',' '2' ',' '[' ']' ',' '[' '3' '1' ',' '4' '1' '6' '7' ']' ']'
  1   1   0   0   0   1   0   1   1   0   1   1   0   0   1   0   0   0   1   1
                                                                                  ┘
```

To get the rest of the token start points, we just `∨` in all the bracket locations.

```
   +`(a∊"[]")∨»⊸<a∊d
⟨ 1 2 2 2 2 3 3 4 5 5 6 7 7 7 8 8 8 8 9 10 ⟩
   a≍+`(a∊"[]")∨»⊸<a∊d
┌─
╵ '[' '9' '9' '9' ',' '2' ',' '[' ']' ',' '[' '3' '1' ',' '4' '1' '6' '7' ']' ']'
  1   2   2   2   2   3   3   4   5   5   6   7   7   7   8   8   8   8   9   10
                                                                                  ┘
```

Taking a sum scan gives us a different number for each token, but each comma gets lumped in with the previous token.

```
   (','≠a)×+`(a∊"[]")∨»⊸<a∊d
⟨ 1 2 2 2 0 3 0 4 5 0 6 7 7 0 8 8 8 8 9 10 ⟩
   a≍(','≠a)×+`(a∊"[]")∨»⊸<a∊d
┌─
╵ '[' '9' '9' '9' ',' '2' ',' '[' ']' ',' '[' '3' '1' ',' '4' '1' '6' '7' ']' ']'
  1   2   2   2   0   3   0   4   5   0   6   7   7   0   8   8   8   8   9   10
                                                                                  ┘
```

Multiplying by a mask of non-commas zeros out the commas.

```
   1-˜(','≠a)×+`(a∊"[]")∨»⊸<a∊d
⟨ 0 1 1 1 ¯1 2 ¯1 3 4 ¯1 5 6 6 ¯1 7 7 7 7 8 9 ⟩
   (1-˜(','≠a)×+`(a∊"[]")∨»⊸<a∊d)⊔a
⟨ "[" "999" "2" "[" "]" "[" "31" "4167" "]" "]" ⟩
```

We subtract 1 to drop the commas when we group and give the first group index 0.
Finally, we group and voila!

Getting from here to my definition of `T` is just standard tacit refactoring stuff.
And to be honest `T` is hard for me to read, so I probably wouldn't write it that way.
But we already have it, so let's continue to parsing.

### Parsing

Now it's just standard recursive descent stuff.
Here's a sketch of the grammar.

```
Value → List | Number
List  → "[" Value* "]"
```

We write one function each for parsing values, lists, and numbers.

```
   ParseVal ← {"["≡⊑𝕩 ? ParseLst 𝕩; ParseNum 𝕩}
   ParseNum ← {⟨10⊸×⊸+˜´⌽'0'-˜⊑𝕩, 1↓𝕩⟩}
   ParseLst ← {
    rslt←⟨⟩
    val‿rest ← ⟨@,1↓𝕩⟩
    {𝕤⋄val‿rest↩ParseVal rest ⋄ rslt∾↩<val}•_while_{𝕤⋄"]"≢⊑rest}@
    ⟨rslt, 1↓rest⟩
   }
```

The basic idea is that a value is a list if it starts with "[", otherwise it's a number.
To parse a number, we just do a standard string-to-number-left-fold thing on the first element,
and we return that number along with the rest of the tokens.
To parse a list, we build up a list `rslt` by repeatedly parsing a value off the front of the list
until we hit a "]".
Then we return `rslt` and the rest of the tokens.
Gotta be careful to drop the brackets in the right spots and to enclose the value before appending to `rslt`!

To parse a list, we tokenize, parse the list, and then take the value from the `⟨value, tokens⟩` pair the parser returns.

```
   Parser2 ← ⊑∘ParseLst∘T
   Parser2 "[999,2,[],[31,4167]]"
⟨ 999 2 ⟨⟩ ⟨ 31 4167 ⟩ ⟩
```

It works!

```
   bqn ≡ Parser2¨¨ data2
1
```

It agrees with the parsing we did earlier using `•BQN`,

```
   bqn ≡ Parser2 data
1
```

and works on the "one giant string" approach.

```
   100 Parser2•_timed data
0.007146561
   100 Parser2¨¨•_timed data2
0.006849455
```

Not to mention it's around 10x as fast as using `•BQN`.

## Array-style parsing

Using array techniques, we can achieve even faster parsing.
Both the [self-hosted compiler](https://github.com/mlochbaum/BQN/blob/master/src/c.bqn) and the [bqn-libs json parser](https://github.com/mlochbaum/bqn-libs/blob/master/json.bqn) use an array style.
The following ideas come from studying the json parser.
(I haven't looked at the compiler in any depth.)

The fundamental idea for handling nesting is to reorder the tokens by depth.
Once we've done that, there's a sense in which we've already mostly parsed the tokens!
(At least for a simple case like these nested lists.)

Here's our running example:

```
   tok ← T "[1,2,[3,4,[5,6]],7,8,[9,10]]"
⟨ "[" "1" "2" "[" "3" "4" "[" "5" "6" "]" "]" "7" "8" "[" "9" "10" "]" "]" ⟩
```

Let's find the depth.

```
   o ← "["⊸≡¨tok
   c ← "]"⊸≡¨tok
   tok≍+`o-c
┌─
╵ "[" "1" "2" "[" "3" "4" "[" "5" "6" "]" "]" "7" "8" "[" "9" "10" "]" "]"
  1   1   1   2   2   2   3   3   3   2   1   1   1   2   2   2    1   0
                                                                           ┘
```

Opening brackets increase depth by 1 at the bracket, and closing brackets decrease depth by 1 at the bracket.

We can use `⍋` to reorder the tokens according to their depths.

```
   (⍋+`o-c)⊏tok
⟨ "]" "[" "1" "2" "]" "7" "8" "]" "[" "3" "4" "]" "[" "9" "10" "[" "5" "6" ⟩
```

This is really weird-looking at first, but once you learn how to read it, it's nicer to work with than the original order.

Each closing bracket is like a nested list waiting to be filled, or an arrow pointing to a sublist.
Each opening bracket signals the start of a new sublist.
The list being pointed to by a closing bracket is the next unused sublist.

If we replace each closing bracket with a `↓` and each opening bracket with a `∘`, just for pictorial purposes,
we can arrange the list into the follow diagram.

```
0 ↓
1 ∘  1  2  ↓  7  8  ↓
2          ∘ 3 4 ↓  ∘ 9 10
3                ∘ 5 6
```

The downward arrows represent sublists, and the circles represent list starting points.
The numbers in the first column are the depths.
The first closing bracket is the only token with depth zero, and it points at the whole list.
The element between 2 and 7 and the last element are each sublists, the first of which has its own sublist.

We almost have an algorithm that goes something like this:
for each closing bracket, find the next unused sublist and replace the closing bracket with the sublist.

For example, we might build the list this way:
```
] → 1 2 ] 7 8 ] → 1 2 ⟨3 4 ]⟩ 7 8 ⟨9 10⟩ → 1 2 ⟨3 4 ⟨5 6⟩⟩ 7 8 ⟨9 10⟩
```

How can we turn this into code?

Instead of ordering by depth, we can go further and split by depth.

```
   (+`o-c)⊔tok
⟨ ⟨ "]" ⟩ ⟨ "[" "1" "2" "]" "7" "8" "]" ⟩ ⟨ "[" "3" "4" "]" "[" "9" "10" ⟩ ⟨ "[" "5" "6" ⟩ ⟩
```

And then perhaps we can use some kind of fold to fill in the "gaps" in each list with the lists from the next element.
Going left to right would build the list "top down" like the example above.
One snag with this approach is that at each step we have to search at a different depth for the closing brackets.
Sure, we know exactly what depth to search at, but we can eliminate this complication entirely by going right to left.
This builds the list bottom up, so at every step we are plugging sublists into a list at the outermost depth.

This would look something like:
```
5 6 → ⟨3 4 ⟨5 6⟩⟩ ⟨9 10⟩ → 1 2 ⟨3 4 ⟨5 6⟩⟩ 7 8 ⟨9 10⟩
```

Here is the complete idea. We're going to perform a right fold. 
At each step, the operand to the fold splits up the right argument at the opening brackets
and then plugs the resulting lists into the closing brackets of the left argument.

Thus we need two functions: one to split up the right argument on opening brackets and one to plug the lists into the closing brackets.

Now we can write some code.

```
   # split up based on [
   Split ← {m←"["⊸≡¨𝕩 ⋄ 1⊸↓¨(1-˜+`m)⊔𝕩}
   Split "["‿"3"‿"4"‿"]"‿"["‿"9"‿"10"
⟨ ⟨ "3" "4" "]" ⟩ ⟨ "9" "10" ⟩ ⟩

   # replace "]" in 𝕩 with 𝕨
   Replace ← {m←"]"⊸≡¨𝕩 ⋄ 𝕨⌾(m⊸/)𝕩}
   ⟨"3"‿"4"‿"]", "9"‿"10"⟩ Replace "["‿"1"‿"2"‿"]"‿"7"‿"8"‿"]"
⟨ "[" "1" "2" ⟨ "3" "4" "]" ⟩ "7" "8" ⟨ "9" "10" ⟩ ⟩

   {(Split 𝕩) Replace 𝕨}´ (+`o-c)⊔tok
┌─
· ┌─
  · "1" "2" ⟨ "3" "4" ⟨ "5" "6" ⟩ ⟩ "7" "8" ⟨ "9" "10" ⟩
                                                         ┘
                                                           ┘
   
   Replace˜⟜Split´(+`o-c)⊔tok
┌─
· ┌─
  · "1" "2" ⟨ "3" "4" ⟨ "5" "6" ⟩ ⟩ "7" "8" ⟨ "9" "10" ⟩
                                                         ┘
                                                           ┘
```

It works!
The whole thing is inside a singleton list because of that left-most closing bracket,
so we'll need to apply `⊑` at the end.
Also, we've still got to turn strings into numbers at the end.
We can write a string to number function and apply it at depth 1,
but there's one small catch that's not apparent from our example so far:
if we parse an empty list, then applying our string to number function at depth 1 will apply it to that empty list.
So we need to check for empty input to the string to number function.

Other than that, we just need to package this together into a parser.

```
   ToNum ← {⟨⟩≡𝕩 ? ⟨⟩ ; 10⊸×⊸+˜´⌽𝕩-'0'}
   Parser3 ← {ToNum⚇1 ⊑ Replace˜⟜Split´ (+`("["⊸≡¨𝕩)-"]"⊸≡¨𝕩)⊔𝕩}∘T
   Parser3 "[1,2,[3,4,[5,6]],7,8,[9,10]]"
┌─
· 1 2 ⟨ 3 4 ⟨ 5 6 ⟩ ⟩ 7 8 ⟨ 9 10 ⟩
                                   ┘
   bqn ≡ Parser3 data
1
   bqn ≡ Parser3¨¨ data2
1
```

Looking good.
Let's see how fast it is.

```
   •Show 100 Parser3•_timed data
0.015287862
   •Show 100 Parser3¨¨•_timed data2
0.014943577
```

Oof! It's twice as slow as the conventional parser!

That's okay because this was really just a warm-up to get us in the array mood.
Even though what we have now is slow, the concepts we used will help us write a fast parser.
And isn't it kind of amazing how we parsed a recursive data structure with just some arithmetic and primitives like `⊔` and folding?
I think it's cool.

Anyway, we can make significant improvements.
First of all, have you been feeling the nagging pain of using lists of strings instead of just a string?
It's so annoying writing `"["⊸≡¨tok` instead of just `'['=tok`, and it's probably slower too.
Let's try to keep our representations "flatter".

So the new idea is that the tokenizer will just output a string, meaning that each token is now a single character.
This leaves no room for the values of the tokens (the numbers themselves), just the token types,
so actually the tokenizer will output a string and a list of numbers.

```
   a ← "[1,2,[3,4,[5,6]],7,8,[9,10]]" # example string
   a≍n ← a∊'0'+↕10 # numbers
┌─
╵ '[' '1' ',' '2' ',' '[' '3' ',' '4' ',' '[' '5' ',' '6' ']' ']' ',' '7' ',' '8' ',' '[' '9' ',' '1' '0' ']' ']'
  0   1   0   1   0   0   1   0   1   0   0   1   0   1   0   0   0   1   0   1   0   0   1   0   1   1   0   0
                                                                                                                  ┘
   a≍ns ← »⊸<n # number starts
┌─
╵ '[' '1' ',' '2' ',' '[' '3' ',' '4' ',' '[' '5' ',' '6' ']' ']' ',' '7' ',' '8' ',' '[' '9' ',' '1' '0' ']' ']'
  0   1   0   1   0   0   1   0   1   0   0   1   0   1   0   0   0   1   0   1   0   0   1   0   1   0   0   0
                                                                                                                  ┘
   (1-˜n×+`ns)⊔a # numbers as strings
⟨ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ⟩
   num ← 10⊸×⊸+˜´∘⌽¨ '0'-˜(1-˜n×+`ns)⊔a # numbers
⟨ 1 2 3 4 5 6 7 8 9 10 ⟩
```

This is the idea behind the part of the tokenizer that extracts the numbers into one flat list.

```
   a≍f ← ns∨a∊"[]" # first characters of tokens as mask
┌─
╵ '[' '1' ',' '2' ',' '[' '3' ',' '4' ',' '[' '5' ',' '6' ']' ']' ',' '7' ',' '8' ',' '[' '9' ',' '1' '0' ']' ']'
  1   1   0   1   0   1   1   0   1   0   1   1   0   1   1   1   0   1   0   1   0   1   1   0   1   0   1   1
                                                                                                                  ┘
   f/a # first character of each token as string
"[12[34[56]]78[91]]"
   tok ← '0'¨⌾((f/n)⊸/)f/a # replace numbers with 0
"[00[00[00]]00[00]]"
```

Here is the second part of the tokenizer.
We get the first characters of each token by adding in the brackets to the number starts.
Then we replace all the numbers with 0.
The idea is that this string now represents the token types with the brackets standing for themselves
and the 0s standing for a number type token.
The numbers themselves are separated out as we showed previously.
Any character would do to represent the numbers,
but I chose 0 because it's what the json parser does and it reminds me of a number.

Putting it all together:

```
   Tokenize ← {
     n ← 𝕩∊'0'+↕10
     ns ← »⊸<n
     num ← 10⊸×⊸+˜´∘⌽¨ '0'-˜(1-˜n×+`ns)⊔𝕩
     f ← ns∨𝕩∊"[]"
     tok ← '0'¨⌾((f/n)⊸/)f/𝕩
     tok‿num
   }
   Tokenize "[1,2,[3,4,[5,6]],7,8,[9,10]]"
⟨ "[00[00[00]]00[00]]" ⟨ 1 2 3 4 5 6 7 8 9 10 ⟩ ⟩
```

Now for parsing we're going to build the list from the bottom up again, using the same depth ordering ideas.
We obviously can't operate only on the token types (the string the tokenizer produces);
we need to incorporate the token values (the numbers) at some point.
The way we'll do that is operating on the token types to produce indices that we use to select from a list of values.

So if we were trying to produce the final result list, which in a depth-based token-types-only representation would look like `00]00]`,
we need to somehow say that the first 0 stands for 1, the second 0 for 2, the first closed bracket for the whole list `⟨3,4,⟨5,6⟩⟩`,
the third 0 for 7, the fourth 0 for 8, and the final closed bracket for the whole list `⟨9,10⟩`.
Then we could just grab all the values we mentioned and put them together as `⟨1,2,⟨3,4,⟨5,6⟩⟩,7,8,⟨9,10⟩⟩`.

The way we'll be able to reference a whole sublist like `⟨3,4,⟨5,6⟩⟩` is by building from the bottom up, as previously mentioned,
so that by the time we need to use a value, we've already built it.
At the beginning, the values we have are just the numbers themselves.
We start with the deepest list `⟨5,6⟩`, which we can build by indexing into the list of values (which again at this point is just numbers).
Then we append this to the list of values.
Now in a future step where we need to build `⟨3,4,⟨5,6⟩⟩`, all three elements of this list already reside in our list of values,
and all we need to do is index into the list of values to assemble them into a new value that gets appended to the end.

So let's start by trying to organize the tokens so we can build the values in the correct order.

```
   o ← '['=tok
   c ← ']'=tok
   tok≍+`o-c # depth
┌─
╵ '[' '0' '0' '[' '0' '0' '[' '0' '0' ']' ']' '0' '0' '[' '0' '0' ']' ']'
  1   1   1   2   2   2   3   3   3   2   1   1   1   2   2   2   1   0
                                                                          ┘
   g ← ⍋+`('['=tok)-']'=tok # depth ordering indices
⟨ 17 0 1 2 10 11 12 16 3 4 5 9 13 14 15 6 7 8 ⟩
   u ← g⊏tok # tokens reordered by depth
"][00]00][00][00[00"
```

Here's that same reorder by depth trick we've already discussed,
but this time it's a little less painful to write since we just have a string instead of a list of strings.

Here's the next big idea.

```
   u≍r ← +`'['=u # sublists in depth ordering
┌─
╵ ']' '[' '0' '0' ']' '0' '0' ']' '[' '0' '0' ']' '[' '0' '0' '[' '0' '0'
  0   1   1   1   1   1   1   1   2   2   2   2   3   3   3   4   4   4
                                                                          ┘
```

By taking a sum scan of a mask of opening bracket locations in the depth ordering we can give a number to each sublist of the list.
This is the order we have to construct values in, with higher numbers going first.
It's reminiscent of how we split the on opening brackets in our earlier approach.

Now what we need are indices that tell us where to pull the values from. 
For example, we start with list 4 (the `[00` at the end), so we need to know that those 0s are associated with indices 4 and 5,
since `4‿5 ⊏ num` is the `5‿6` we want.
Then later when constructing list 2, which looks like `[00]`, we need to know that the 0s are associated with indices 2 and 3,
and the closing bracket is associated with index 10, since (after appending `5‿6` to a list of values `vals` at index 10) we have `2‿3‿10 ⊏ vals` giving `⟨3,4,⟨5,6⟩⟩`.

Here we go.

```
   tok≍f ← tok∊"0]" # mask of "values": numbers and sublists
┌─
╵ '[' '0' '0' '[' '0' '0' '[' '0' '0' ']' ']' '0' '0' '[' '0' '0' ']' ']'
  0   1   1   0   1   1   0   1   1   1   1   1   1   0   1   1   1   1
                                                                          ┘
   (f/tok)≍(f/'0'=tok)+2×f/']'=tok # gives numbers 1 and sublists 2
┌─
╵ '0' '0' '0' '0' '0' '0' ']' ']' '0' '0' '0' '0' ']' ']'
  1   1   1   1   1   1   2   2   1   1   1   1   2   2
                                                          ┘
   vi ← ⍋⍋(f/'0'=tok)+2×f/']'=tok # value indices
⟨ 0 1 2 3 4 5 10 11 6 7 8 9 12 13 ⟩
   (f/tok)≍vi
┌─
╵ '0' '0' '0' '0' '0' '0' ']' ']' '0' '0' '0' '0' ']' ']'
  0   1   2   3   4   5   10  11  6   7   8   9   12  13
                                                          ┘
```

Here we filter away the opening brackets, keeping only those tokens that represent values: 0 for numbers and ] for sublists.
Then we assign each value a number working left to right, but with numbers always coming before sublists.
That `⍋⍋` is the ordinals pattern, which shows which index the element would end up at if sorted.
(You can read about that [here](https://mlochbaum.github.io/BQN/doc/order.html#ordinals).)

This is close to what we want.
The 0s each have been associated with the proper index.
However, the closing brackets (representing sublists) have not.

We need to bring in our previous work `r` where we numbered the lists.
But `r` is in depth ordering and `vi` is in the original ordering, so we put `r` back into original ordering and call it `l`.

```
   tok≍l ← (⍋g)⊏r # sublist index
┌─
╵ '[' '0' '0' '[' '0' '0' '[' '0' '0' ']' ']' '0' '0' '[' '0' '0' ']' ']'
  1   1   1   2   2   2   4   4   4   2   1   1   1   3   3   3   1   0
                                                                          ┘
```

We invert the permutation `g` with `⍋` to translate from the depth ordering back to the original ordering.
We call the resulting numbers the "sublist index" here.
(It's really a pain to name a new idea. I don't wanna name things! That's why I'm a BQN programmer.)

We can use `l` to fix `vi` by finding the sublist index associated with each closing bracket.
If we just take the sublist index at a closing bracket, we get the sublist index associated with the list containing it.
So we need the sublist index at the token before the closing bracket to get the index of the sublist itself.

```
   c/l
⟨ 2 1 1 0 ⟩
   c/»l
⟨ 4 2 3 1 ⟩
```

Here we show `c/l` and `c/»l`. The first element of `c/l` is 2, indicating that the first closing bracket (which closes `⟨5,6⟩`) represents a sublist contained in the sublist with index 2 (i.e. `⟨3,4,⟨5,6⟩⟩`).
The first element of `c/»l`, however, is 4, indicating that the sublist `⟨5,6⟩` is itself sublist number 4.
That's the number we want.

```
   (≠num)+≠⊸-c/»l
⟨ 10 12 11 13 ⟩
```

Sublist number 4 is the first sublist to be constructed, and after being constructed and appended to the value list it has index 10.
The arithmetic above adjusts the sublist indices to become indices into the value list.
We subtract each sublist index from the number of sublists to invert the order, and then add the result to the number of numbers,
to offset the indices correctly.

```
   nv ← ≠num
   i ← vi ⊏ (↕nv) ∾ nv+≠⊸-c/»l # Adjust for sublist ordering
⟨ 0 1 2 3 4 5 10 12 6 7 8 9 11 13 ⟩
   (f/tok)≍i
┌─
╵ '0' '0' '0' '0' '0' '0' ']' ']' '0' '0' '0' '0' ']' ']'
  0   1   2   3   4   5   10  12  6   7   8   9   11  13
                                                          ┘
```

From here, it's not hard to complete the value indices list.
We append the value indices just calculated for the sublists to the list `↕≠num`, which are the value indices for the numbers.
Since both `vi` and `c»l` reference the closing brackets in the original left to right order, indexing into this list with `vi` pulls everything out in the correct order.

```
   ⌽(1-˜f/l)⊔i
⟨ ⟨ 4 5 ⟩ ⟨ 8 9 ⟩ ⟨ 2 3 10 ⟩ ⟨ 0 1 12 6 7 11 ⟩ ⟩
```

We group these value indices `i` using the sublist indices from `l` and reverse the result to finally complete the task of arranging the value indices.
We use `1-˜f/l` instead of just `l` because we need to remove the opening brackets and drop the final closing bracket.
Now we can see the first element contains indices 4 and 5, which correspond to the values 5 and 6.
The third element contains the indices 2, 3, and 10, which correspond to values 3, 4, and `⟨5,6⟩`.
Etc. 

All that's left to do is the indexing and appending described earlier.

```
   vals ← num
   {vals∾↩<𝕩⊏vals⋄@}¨ ⌽(1-˜f/l)⊔i
   ¯1⊑vals
┌─
· 1 2 ⟨ 3 4 ⟨ 5 6 ⟩ ⟩ 7 8 ⟨ 9 10 ⟩
                                   ┘
```

It works!
The list of values `vals` starts off as just the numbers `num`.
With each application of the block function we index into `vals` and append the result to `vals`.
The `⋄@` is at the end of the block both to signal that we are using the block for side-effects only
and to not waste time and space building a list of results.

We're not quite done yet!
There is one final wrinkle that our example so far hasn't made clear.
We need to ensure that the result of `(1-˜f/l)⊔i` always has as many elements as there are closing brackets
(even if some or all of them are empty) in order to accomodate empty lists.
This is roughly because each closing bracket represents a sublist value,
so we always need to build at least that many values.

Thus we change `1-˜f/l` to `(+´c)∾˜1-˜f/l` to append the number of closing brackets to the end.
Group has the option of using a left argument with an extra last element relative to right argument,
and this last element sets the minimum number of elements of the result.

Let's put it all together.

```
   Parser4 ← {
     tok‿num ← Tokenize 𝕩
     g ← ⍋+`('['=tok)-(c←']'=tok) # depth ordering indices
     r ← +`'['=g⊏tok # sublists in depth ordering
     l ← (⍋g)⊏r # sublist index
     f ← tok∊"0]" # mask of "values": numbers and sublists
     vi ← ⍋⍋(f/'0'=tok)+2×f/c # value indices
     nv ← ≠num
     i ← vi ⊏ (↕nv) ∾ nv+≠⊸-c/»l # Adjust for sublist ordering
     vals ← num
     {vals∾↩<𝕩⊏vals⋄@}¨ ⌽((+´c)∾˜1-˜f/l)⊔i
     ¯1⊑vals
   }
   •Show Parser4 "[1,2,[3,4,[5,6]],7,8,[9,10]]"
┌─
· 1 2 ⟨ 3 4 ⟨ 5 6 ⟩ ⟩ 7 8 ⟨ 9 10 ⟩
                                   ┘

   •Show bqn ≡ Parser4 data
1
   •Show bqn ≡ Parser4¨¨ data2
1

   •Show 100 Parser4•_timed data
0.004316795
   •Show 100 Parser4¨¨•_timed data2
0.005003989
```

It works, and it's really fast! It's also the only parser that's faster on the one big string approach.

## Final Comparison

Using `•BQN` is definitely the easiest, but it is slow and has problems parsing large lists, at least on my machine.

For a little more effort (at least if you're already familiar with recursive descent) we can get a much more performant parser.
Probably should be your method of choice if `•BQN` is too slow.

A well-written array style parser is the fastest (and coolest obviously), but wow is it confusing to implement!
For this Advent of Code problem it's certainly not worth the trouble.
I mean, even just using `•BQN` works fine honestly.
If we had to parse way more data, or reuse this parser many times, the array method would start to make sense.
Also if the lists had very very deep nesting, the recursive parser would hit the maximum recursion limit and fail.

Here's a little table recapping the time in seconds it took each method to parse my input file.
Each time is the average of 100 runs.

```
          |   data         data2
------------------------------------
•BQN      | N/A          0.074279465
Recursive | 0.007146561  0.006849455
Array v1  | 0.015287862  0.014943577
Array v2  | 0.004316795  0.005003989
```

Happy parsing! <3
