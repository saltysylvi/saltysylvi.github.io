# BQN "macros" with `•Decompose`

02/04/2023

Using `•Decompose` to create functions with access to the syntax tree of their arguments.

---

I just learned about the BQN system function [`•Decompose`](https://mlochbaum.github.io/BQN/spec/system.html#operation-properties), and it's really cool.
As its name suggests, `•Decompose` breaks down a compound function, giving access to the parts of the function and specifying how they were combined.
In other words, it grants us access to the syntax tree of a tacit function, sort of like a Lisp macro.

This is a powerful ability!
It allows us to do dark magic in opposition to BQN's "no magic" design philosophy.

There are limitations, however.
`•Decompose` only does something useful with tacit functions. 
It doesn't delay evaluation of its argument or anything like that.
So if we call it on `2+2` it only sees `4`.
Also we can't pass it something with invalid syntax like `4+`.

In this blog post, I demonstrate two uses of `•Decompose`:
alternate train semantics and symbolic differentiation.

## Using `•Decompose`

`•Decompose` breaks down a function and returns a list.
The first element of the list is a code indicating what kind of structure the function has.
The rest of the elements are the components of the function.
Here are a couple examples:

```
   •Decompose ⊑⟨+´÷≠⟩
⟨ 3 +´ ÷ ≠ ⟩
```

3 indicates that the original function was a 3-train.

```
   •Decompose ⊑⟨|∘-⟩
⟨ 5 | ∘ - ⟩
```

5 indicates that the original function was a 2-modifier applied to two functions.

Note that `•Decompose` is a function and not a modifier, so we need to pass it a function with a subject role.
Putting a function in a list and then extracting it from the list with `⊑` is one way to do that.

Also note that `•Decompose` only breaks down one level of a function.
For example, it did not further break down `+´` in the first example.

Here is the full list of codes and what they mean:
```
Code  Kind
----  ----
-1    Non-operation
0     Primitive
1     Other
2     2-train
3     3-train
4     1-modifier
5     2-modifier
```

Codes -1, 0, and 1 correspond to things that are not compound functions.

With those preliminaries out the way,
let's write a helper function that handles breaking a function down all the way into its AST (abstract syntax tree), as well as an inverse that handles reassembling an AST into a function.

```
   AST ← {
     𝕊: {2>⊑𝕩 ? 1⊑𝕩; AST¨⌾(1⊸↓)𝕩} •Decompose 𝕩;
     𝕊⁼: U ← AST⁼¨ 1⊸↓
       {
         0=≡𝕩 ? 𝕩 ;
         2=⊑𝕩 ? g‿h←U𝕩 ⋄ G H;
         3=⊑𝕩 ? f‿g‿h←U𝕩 ⋄ F G H;
         4=⊑𝕩 ? f‿r←U𝕩 ⋄ F _r;
         5=⊑𝕩 ? f‿r‿g←U𝕩 ⋄ F _r_ G
       } 𝕩
   }
```

The function `AST` recursively decomposes its argument.
The base case is when the code given by `•Decompose` is less than 2, i.e. no decomposition can be done. 
In this case it just returns the un-decomposable thing, which is always the second element of the result of `•Decompose`.
In every other case, `AST` calls itself on each component of the function, i.e. every element of the result of `•Decompose` besides the first element which is the code.

The inverse is a little fancier.
The base case is when the argument is not a list, in which case we return the argument unchanged.
Otherwise, we recursively call the inverse on each subtree to turn them back into functions/modifiers, and then we combine the values depending on the code.
Since the result of `AST⁼` has a subject role, we need a bit of cross-role gymnastics to turn the results back into functions/modifiers so we can combine them.

```
   AST ⊑⟨+´⌾(×˜)⟩
⟨ 5 ⟨ 4 + ´ ⟩ ⌾ ⟨ 4 × ˜ ⟩ ⟩
   AST⁼ ⟨5,⟨4,+,´⟩,⌾,⟨4,×,˜⟩⟩
+´⌾(×˜)
```

Looks good!

The beauty of using the `𝕊⁼` header is that we can now write a tree transformation `T` and call `T⌾AST` on a function to turn it into an AST, operate on the AST with `T`, and then turn it back into a function, without needing to write the reassembly code each time.

Onward to examples!

## Alternate Train Semantics

One of the minor problems with BQN is that [trains don't like monads](https://mlochbaum.github.io/BQN/commentary/problems.html#trains-dont-like-monads).
In particular, it's slightly awkward to write a long chain of monads in tacit form.
We've got to write a bunch of `∘`s or `·`s.

We're gonna make a one modifier, `_c` ("c" for compose? chain? you decide!), 
that applies to trains and turns them into a sequence of monads.

We can accomplish this by turning 3-trains `F G H` into nested 2-trains `F(G H)`.

Here's the tree transforming function:
```
   T ← {
     ⟨2,g,h⟩: ⟨2, T g, T h⟩;
     ⟨3,f,g,h⟩: ⟨2, T f, ⟨2, T g, T h⟩⟩;
     ⟨4,f,r⟩: ⟨4, T f, r⟩;
     ⟨5,f,r,g⟩: ⟨5, T f, r, T g⟩;
     𝕩: 𝕩
   }
```

BQN's basic pattern matching makes functions like these a joy to write.

```
   T⌾AST ⊑⟨⌽ +` 1⊸+ 2⊸× ↕⟩
⌽(+`(1⊸+(2⊸×↕)))
```

We can see that it has indeed transformed the train into a bunch of nested 2-trains.

Next, let's package this up as a 1-modifier.

```
   _c ← {T⌾AST 𝕗}
   (⌽ +` 1⊸+ 2⊸× ↕)_c 6
⟨ 36 25 16 9 4 1 ⟩
```

To make a 1-modifier, we simply call `T⌾AST` on `𝕗`, the operand in a subject role.
The result of a 1-modifier always has a function role, so that's all we need to do.
The example shows it works. Neat!
But we can go even further in perverting BQN...

What if instead of a right-to-left application of monads, we made it a left-to-right application?
We can even put the argument on the left side!

To do this we write just write another simple tree transforming function.
```
   T ← {
     ⟨2,g,h⟩: ⟨2, T h, T g⟩;
     ⟨3,f,g,h⟩: ⟨2, T h, ⟨2, T g, T f⟩⟩;
     ⟨4,f,r⟩: ⟨4, T f, r⟩;
     ⟨5,f,r,g⟩: ⟨5, T f, r, T g⟩;
     𝕩: 𝕩
   }
   _c ← {(T⌾AST 𝕗){𝔽}𝕨}
```

`T` is pretty much what we had before, but with all the 2-trains getting reversed.
In `_c` we now use the block 1-modifier `{𝔽}` to give `T⌾AST 𝕗` a function role so that we can apply it to the left argument `𝕨`.

```
   6 (↕ 2⊸× 1⊸+ +` ⌽)_c@
⟨ 36 25 16 9 4 1 ⟩
```

Now we can put the argument on the left and write a sequence of functions in left-to-right order!
Very cool.
Note that we still need a right argument, so we just put a `@` at the end.

Is this useful?
I don't know. Maybe.
While I love a good left to right data pipeline,
this probably does more harm than good by being magic and confusing.

## Symbolic Differentiation

Another use of `•Decompose` is writing a symbolic differentiation 1-modifier, for uh, math reasons I guess.

Our modifier will work on the following functions:  
constants with and without `˙`;  
monads `⊢`, `-`, `÷`, and `⋆`;  
partially applied dyads `+`, `-`, `×`, `÷`, and `⋆`;  
2-trains;  
3-trains with `+`, `-`, `×`, and `÷` as the middle function.

We could add more cases, but we're just making a proof of concept here.

```
   T ← {
     ⟨4, f, r⟩: {r=⊑⟨˙⟩ ? 0}; # constants
     ⟨5,f,r,g⟩: { # partially applied dyads
       r‿g≡⊸‿+ ? 1;
       r‿f≡⟜‿+ ? 1;
       r‿g≡⊸‿- ? ¯1;
       r‿f≡⟜‿- ? 1;
       r‿g≡⊸‿× ? f;
       r‿f≡⟜‿× ? g;
       r‿g≡⊸‿÷ ? -f÷⋆⟜2;
       r‿f≡⟜‿÷ ? 1÷g;
       r‿g≡⊸‿⋆ ? (⋆⁼f)⊸× f⊸⋆;
       r‿f≡⟜‿⋆ ? g×⋆⟜(g-1)
     };
     ⟨2,f,g⟩: ⟨3, T g, ×, ⟨2, T f, g⟩⟩; # 2-trains
     ⟨3,f,g,h⟩: { # 3-trains
       g=⊑⟨+⟩ ? ⟨3, T f, +, T h⟩;
       g=⊑⟨-⟩ ? ⟨3, T f, -, T g⟩;
       g=⊑⟨×⟩ ? ⟨3, ⟨3, h, ×, T f⟩, +, ⟨3, f, ×, T h⟩⟩;
       g=⊑⟨÷⟩ ? ⟨3, ⟨3, ⟨3, h, ×, T f⟩, -, ⟨3, f, ×, T h⟩⟩, ÷, ⟨2, ⋆⟜2, h⟩⟩
     };
     𝕩: { # monads
       𝕩=⊑⟨⊢⟩ ? 1;
       𝕩=⊑⟨-⟩ ? ¯1;
       𝕩=⊑⟨÷⟩ ? -1÷⋆⟜2;
       𝕩=⊑⟨⋆⟩ ? ⋆;
       0 # everything else presumed 0
     }𝕩
   }

   _d ← {T⌾AST 𝕗}
```

Here's the tree transforming function `T` and a 1-modifier that applies `T⌾AST` to a function.
(By the way, is anybody else getting a craving for some toast?)
Unfortunately, we can't directly write cases like `⟨3,f,+,g⟩` because BQN doesn't allow functions in lists in case headers.
I'm not sure why, to be honest.

The code should be straightforward if you remember your calculus.
The only catches are that we assume the left operand of `⊸` and the right operand of `⟜` are numbers,
and we assume that the derivative of any non-compound argument that isn't `⊢`, `-`, `÷`, or `⋆` is 0.
Better code would of course be more careful about these things.

Let's try it out.

```
   ⋆⟜2 _d
2×⋆⟜1
```

Yup, using more conventional notation, the derivative of `x^2` is `2x`.
The code we wrote isn't smart enough to know that `x^1` is `x`.

```
   (⋆⟜2 +⟜1)_d
1×((2×⋆⟜1)+⟜1)
   (⋆⟜2 +⟜1)_d _d
(((2×⋆⟜1)+⟜1)×0{𝔽})+1×1×(((⋆⟜1×0{𝔽})+2×1×⋆⟜0)+⟜1)
```

The derivative of `(x+1)^2` is `2(x+1)`.
Again, our code doesn't simplify away the `1×` or `⋆⟜1` so the result is cluttered.
Taking a second derivative, we can see just how bad it really is.
But if you study that monstrous expression long enough, you can confirm it is indeed just 2.

```
   ((((2×⋆⟜1)+⟜1)×0{𝔽})+1×1×(((⋆⟜1×0{𝔽})+2×1×⋆⟜0)+⟜1)) ↕10
⟨ 2 2 2 2 2 2 2 2 2 2 ⟩
```

Let use `_d` to write a root finder using [Newton's method](https://en.wikipedia.org/wiki/Newton%27s_method).

```
   _newton_ ← {-⟜(𝔽÷𝔽_d)⍟𝕘 𝕩}
```

The left operand to `_newton_` is the function to find a root of,
and the right operand is the number of iterations.
The argument to the resulting function is the intial guess. 

Let's find some roots!

```
   (-⟜2 ⋆⟜2)_newton_ 20 1
1.414213562373095
   √2
1.414213562373095
   (⋆⟜2-+⟜1)_newton_ 20 1
1.618033809079597
   (1+√5)÷2
1.618033988749895
```

Here we've calculated the square root of 2 and the golden ratio using the fact that the former is a root of `x^2-2` and the latter is a root of `x^2-(x+1)`.
Neato.

So, is this useful?
In its current state, not very.
But I could see far more sophisticated code built on this idea being useful.
For example, somebody could implement efficient reverse-mode automatic differentiation for quickly prototyping machine learning models or something like that.

That's all for now. Happy array programming! <3
