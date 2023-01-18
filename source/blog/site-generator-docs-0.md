# A site generator in 28 lines of BQN

01/17/2023

Explaining the script that generates this site.

---

To me, BQN's self-hosted compiler is one of the most intriguing array-language programs ever written.
Since learning of it, I've been interested in learning how to write parsers in the array style.
Even though Marshall warns that it's probably [not a good idea](https://mlochbaum.github.io/BQN/implementation/codfns.html#is-it-a-good-idea), I enjoy BQN, parsers, and a good challenge.

To that end, I wrote my own super minimal and janky markdown processor to generate this site.
Since I did it as a learning exercise,
I decided not to look at the markdown processor used to generate the BQN doc pages,
though I do intend to study it eventually.

Getting my script working was a doozy,
and I'm not even trying to do anything that complicated compared to a "real" compiler.

## Features

build-site.bqn currently supports fairly standard markdown syntax for:  
- headings (e.g. # Heading 1)  
- paragraphs (consecutive lines of text)  
- horizontal dividers (using ---)  
- links (display in square brackets followed by target in parens)  
- inline code (delimited with backticks)  
- code blocks (triple backticks)  
- line breaks (double space at the end of line)

There's currently no support for lists, bold/italics, or escaping the special markdown syntax
(as you might be able to guess from above).
It's particularly annoying that I can't write backtick for BQN's scan except in a code block.
Like I said, it's super minimal and janky.

## build-site.bqn docs

The following is an explanation of how the script works,
mostly for myself, so that I can understand it later.

This site is built with a bqn script `build-site.bqn`.
The script transforms the markdown files in the `source` directory into the html files in the `docs` directory.

Here is the complete code listing:

```
Md2html ← {filename 𝕊 lines:
    lines ∾↩ <""
    lines (∾{'<':"&lt;"; '>':"&gt;"; '&':"&amp;"; ⋈𝕩}¨)¨↩
    title ← ∾⟨"<title>", 2↓⊑lines, "</title>"⟩
    css ← ∾⟨"<link href=""", ∾(1-˜+´'/'=filename)⥊<"../", "main.css"" rel=""stylesheet"">"⟩
    b ← t∨≠`t ← "```"⊸≡¨lines
    lines ("<pre>"‿"</pre>"⥊˜≠)⌾(t⊸/)↩
    lines {∾⍟(1<≡)("<code>"‿"</code>"⥊˜≠)⌾(('`'=𝕩)⊸/)𝕩}¨⌾((¬b)⊸/)↩
    h ← 0<l ← {+´∧`'#'=𝕩}¨ lines
    lines ↩ l { o‿c←"<h"‿"</h"∾⌜<('0'+𝕨)∾">" ⋄ (o⊸∾ ·∾⟜c (𝕨+1)⊸↓)⍟(𝕨>0) 𝕩 }¨ lines
    lines (∾⟜"<br>" ¯2⊸↓)⍟("  "≡¯2⊸↑)¨↩
    lines "<hr>"¨⌾((hr←"---"⊸≡¨lines)⊸/)↩
    p ← hr<b<h<""⊸≢¨lines
    "<p>"‿"</p>"{lines↩𝕨⊸∾¨⌾(𝕩⊸⊏)lines}¨<˘⍉∘‿2⥊/p≠0»p
    lines ↩ {𝕊 line:
        o‿c ← (<line)∊⌜"[("‿"])"
        g ← (c-˜+`o+c)⊔line
        a ← {𝕊a‿b‿c: ("["≡1↑a)∧(""≡b)∧"("≡1↑c}˘3↕g
        E ← (∾⟜".html" ¯3⊸↓)⍟(".md"≡¯3⊸↑)
        P ← {a‿·‿b: (∾⟨"<a href=""",E ¯1↓1↓b,""">",¯1↓1↓a,"</a>"⟩)‿""‿""}
        ∾{⥊P˘∘‿3⥊𝕩}⌾(((≠g)↑/⁼⥊(/a)+⌜↕3)⊸/)g
    }⍟(∨´"]("⊸⍷)¨ lines
    ⟨"<!DOCTYPE html>","<html lang=""en"">","<head>","<meta charset=""utf-8"">",
    title, css, "</head>", "<body>"⟩∾lines∾⟨"</body>", "</html>"⟩
}
sourceFiles ← ∾{(".md"≡¯3⊸↑)¨⊸/ (𝕩∾'/')⊸∾¨•file.List 𝕩}¨ "source"‿"source/blog"
outFiles ← (∾⟜"html" ¯2 ↓ ·"docs"⊸∾ ⊐⟜'/'⊸↓)¨ sourceFiles
outFiles •FLines⟜(Md2html⟜•FLines)¨ sourceFiles
```

### Reading and writing files

Let's start with the last three lines:

```
sourceFiles ← ∾{(".md"≡¯3⊸↑)¨⊸/ (𝕩∾'/')⊸∾¨•file.List 𝕩}¨ "source"‿"source/blog"
outFiles ← (∾⟜"html" ¯2 ↓ ·"docs"⊸∾ ⊐⟜'/'⊸↓)¨ sourceFiles
outFiles •FLines⟜(Md2html⟜•FLines)¨ sourceFiles
```

The first line generates a list of all the source file paths.
We have to manually tell that block function each directory to look in,
here "source" and "source/blog".

```
   sourceFiles ← ∾{(".md"≡¯3⊸↑)¨⊸/ (𝕩 ∾'/')⊸∾¨•file.List 𝕩 }¨ "source"‿"source/blog"
⟨ "source/array-programming.md" "source/index.md" "source/blog/index.md" "source/blog/site-generator-docs-0.md" ⟩
```

We use `•file.List` to list the contents of the directory.
Then we prepend the directory name and a forward slash to each file name.
Then we use a filtering pattern `Predicate¨⊸/` to pick out the markdown files.
We do this to each directory, generating a list of lists,
so we use a final `∾` on the left of the block to join the lists.

The second line generates a list of all the output file paths.

```
   outFiles ← (∾⟜"html" ¯2 ↓ ·"docs"⊸∾ ⊐⟜'/'⊸↓)¨ sourceFiles
⟨ "docs/array-programming.html" "docs/index.html" "docs/blog/index.html" "docs/blog/site-generator-docs-0.html" ⟩
```

The first bit changes the directory from "source" to "docs".
We drop up to the first slash and prepend "docs".
The second part changes the extension.
We drop "md" from the end, and append "html".

The third line opens each source file, converts it from markdown to html, and writes it to the corresponding output file.

```
   outFiles •FLines⟜(Md2html⟜•FLines)¨ sourceFiles
```

The function `Md2html` converts a markdown file to an html file.
It takes the file name as its left argument and the file contents (as a list of lines) as its right argument.
`Md2html⟜•FLines filename` is just what we need to pass the filename and its contents as the left and right arguments respectively.

All that gets passed as the right argument to another `•FLines` call, this time with the output file as a left argument.
Dyadic `•FLines` writes its right argument to the location specified by its left argument.
So this finishes the task of writing the converted files.

### Converting markdown to html

We'll just go line by line through the `Md2html` function.

```
Md2html ← {filename 𝕊 lines:
```

First we have the name and header.
As previously mentioned, this function takes a filename as the left argument,
and its content as a right argument.
The filename gets passed in so I can link to the `main.css` file appropriately.

```
    lines ∾↩ <""
```

The next line just adds an empty line at the end.
We need to enclose `<` the empty line, or else the join will do nothing.
Since empty lines delimit paragraphs, this makes the logic easier for making sure every paragraph gets closed later.
That funky syntax is just like `x += 5` in js.

```
    lines (∾{'<':"&lt;"; '>':"&gt;"; '&':"&amp;"; ⋈𝕩}¨)¨↩
```

This line escapes <, >, and & characters.
The idea is just to call a function on each character that replaces the special characters with their escapes
and replaces nonspecial characters with a string containing just the character (using `⋈`), and then join together all the strings.
We have to do that `⋈𝕩` thing instead of just `𝕩`, otherwise if a line had no special characters the join `∾` would fail.
The funky syntax is an extension of the `x += 5` idea, but to monadic functions.
`x F↩` is the same as `x ↩ F x`.

```
    title ← ∾⟨"<title>", 2↓⊑lines, "</title>"⟩
```

This line grabs the title for later, assuming that the very first line of the file is the title.
We drop two characters, assuming that they are '`# `' for making the first line an h1.

```
    css ← ∾⟨"<link href=""", ∾(1-˜+´'/'=filename)⥊<"../", "main.css"" rel=""stylesheet"">"⟩
```

Now we create the bit of html that links to the css.
The only complicated part is just counting the number of slashes in the filename
to calculate how many `../` to put before `main.css`.
For example, for files in the docs directory it's just `main.css`, 
but for files in the blog subdirectory, it's `../main.css`.

```
    b ← t∨≠`t ← "```"⊸≡¨lines
    lines ("<pre>"‿"</pre>"⥊˜≠)⌾(t⊸/)↩
```

These two lines create code blocks.

First we make a mask `t` for all the lines that are just three backticks.
The `≠` scan trick converts this to a mask of the code blocks themselves,
including the opening backticks, but excluding the closing backticks.
Since we want to include those closing backticks as well, we put them back by `∨`ing with `t`.
Thus `b` is a mask of lines that are part of a code block.
We'll use that later.

The second line uses structural under to grab the triple backticks lines with `t⊸/`,
and then turn them into alternating opening and closing `pre` tags.

Here's a demo of the `≠` scan trick:

```
   q ← '''="here is 'a quote' and 'another quote'" # mask of single quotes
⟨ 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 ⟩
   ≠`q # ≠` trick
⟨ 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 0 ⟩
   q∨≠`q # putting in the closing quotes
⟨ 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 ⟩
```

Pretty neat!

```
    lines {∾⍟(1<≡)("<code>"‿"</code>"⥊˜≠)⌾(('`'=𝕩)⊸/)𝕩}¨⌾((¬b)⊸/)↩
```

This line handles in-line code.
The inner part has a similar structure to the last line:
use structural under to replace all the backticks with alternating opening and closing `code` tags.
But then since we now have a mixed list of strings and characters we've got the join `∾` it together again.
But we only do that when there actually is a string in the list (i.e. depth is > 1 or `1<≡`),
otherwise the join would fail.
Then finally that whole thing happens in a structural under that makes sure we only try this on lines
that are not inside a code block.

```
    h ← 0<l ← {+´∧`'#'=𝕩}¨ lines
    lines ↩ l { o‿c←"<h"‿"</h"∾⌜<('0'+𝕨)∾">" ⋄ (o⊸∾ ·∾⟜c (𝕨+1)⊸↓)⍟(𝕨>0) 𝕩 }¨ lines
```

These two lines create headers.
The tricky bit of the first line is using an `∧` scan to get a mask of leading `#`s from a mask of all `#`s.
`l` is the heading level, including 0 for nonheadings.
`h` is a mask of which lines are headings.
The second line does some fancy table `⌜` stuff and character arithmetic to generate the correct opening and closing tags, `o` and `c`. Then the second part of that line drops all the `#`s and surrounds the line in tags, but only if the line is actually a heading.

```
    lines (∾⟜"<br>" ¯2⊸↓)⍟("  "≡¯2⊸↑)¨↩
```

This line puts line breaks after lines that end with two spaces.
Pretty self-explanatory.

```
    lines "<hr>"¨⌾((hr←"---"⊸≡¨lines)⊸/)↩
```

This line turns lines consisting solely of "---" into horizontal dividers.
We keep a mask `hr` of where the dividers are,
which is why we use the arguably more awkward structural under instead of a repeat `⍟` as above.

```
    p ← hr<b<h<""⊸≢¨lines
    "<p>"‿"</p>"{lines↩𝕨⊸∾¨⌾(𝕩⊸⊏)lines}¨<˘⍉∘‿2⥊/p≠0»p
```

These two lines create paragraphs.
`p` is a mask of which lines are inside a paragraph.
We use the trick that for booleans `p<q` is true iff `p` is `0` and `q` is `1`.
In other words, `p<q` is the same as `(¬p)∧q`.
In other, other words, when `p` and `q` are masks, `p<q` is like "`q` without `p`".
So a line is in a paragraph if it's not blank or a header or a horizontal divider or in a code block.

The second line uses `p≠0»p` to turn the mask of lines in a paragraph
into a mask of lines that start or end a paragraph.
The next bit, `<˘⍉∘‿2⥊/`, converts from a mask to a list of indices
and then restructures the indices into a list of two lists, the first containing the start indices,
and the second containing the end indices.
Then the block function uses these indices to prepend the appropriate tag to each line.

```
    lines ↩ {𝕊 line:
        o‿c ← (<line)∊⌜"[("‿"])"
        g ← (c-˜+`o+c)⊔line
        a ← {𝕊a‿b‿c: ("["≡1↑a)∧(""≡b)∧"("≡1↑c}˘3↕g
        E ← (∾⟜".html" ¯3⊸↓)⍟(".md"≡¯3⊸↑)
        P ← {a‿·‿b: (∾⟨"<a href=""",E ¯1↓1↓b,""">",¯1↓1↓a,"</a>"⟩)‿""‿""}
        ∾{⥊P˘∘‿3⥊𝕩}⌾(((≠g)↑/⁼⥊(/a)+⌜↕3)⊸/)g
    }⍟(∨´"]("⊸⍷)¨ lines
```

This mess creates links.
We call the big block function on every line that contains `](`, since only those lines can contain links.
We do that since if we called it on a line with no parens or brackets we get an error.

Now how does the block work?

The first line does some fancy table work to create a mask `o` of opening parens and brackets and a mask `c` of closing parens and brackets.

The second line uses some standard left-arg-of-group arithmetic stuff to split up the line wherever
there's a paren or bracket. So `"foo (bar) [baz]"` would become `⟨"foo ", "(bar)", " ", "[baz]"⟩`.
The split up line is called `g`.

The third line takes `g` and uses windows `↕` to look at every sublist of 3 consecutive items.
The block function there checks if the first item starts with an opening bracket,
the second item is empty, and the third item starts with an opening paren.
This is the form a markdown link will have after being split up.
We get a mask `a` of link start locations in `g`.

The fourth line is a pretty self-explantory file extension changer for internal site links.

The fifth line creates a function `P` that takes a length 3 list like `⟨"[name]", "", "(link)"⟩` and converts it to an html style link.
The thing to note here is that `P` returns a length 3 list with the link and then two empty strings,
so that we can use it with cells `˘` and under `⌾` more readily.
When we join the result together at the end, the two empty strings wash away.

Finally, the sixth line does a heroic structural under on `g` to apply `P` just where its needed, and then the results are joined together.
The most confusing part is the left argument of the `/` used in the structural under.
`⥊(/a)+⌜↕3` converts the link mask to indices and adds `0`, `1`, `2` to each link start location
in order to give us the indices of all parts of the link.
But we need a mask to use with `/`, so we convert back to a mask with `/⁼`
and over-take to make sure with get a `≠g` length result.
The left argument of `⌾` shapes it back up into a something-by-3 array to apply `P`.

As I often feel when writing BQN, it's hard to tell if this is clever or just awful.
I'll have to see how the "official" BQN markdown parser does it.

```
    ⟨"<!DOCTYPE html>","<html lang=""en"">","<head>","<meta charset=""utf-8"">",
    title, css, "</head>", "<body>"⟩∾lines∾⟨"</body>", "</html>"⟩
}
```

Finally, these two lines just put the appropriate html stuff before and after the body,
including the title and css stuff we calculated earlier.
Not much to explain here.

And that's it! <3
