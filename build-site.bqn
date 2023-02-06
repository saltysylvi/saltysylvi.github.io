Md2html ← {filename 𝕊 lines:
    lines ∾↩ <""
    lines (∾{'<':"&lt;"; '>':"&gt;"; '&':"&amp;"; ⋈𝕩}¨)¨↩
    title ← ∾⟨"<title>", 2↓⊑lines, "</title>"⟩
    css ← ∾⟨"<link href=""", ∾(1-˜+´'/'=filename)⥊<"../", "main.css"" rel=""stylesheet"">"⟩
    b ← t∨≠`t ← "```"⊸≡¨lines
    lines ("<pre>"‿"</pre>"⥊˜≠)⌾(t⊸/)↩
    lines {o←(>⟜»∨>⟜«)≠`⊸∨t←'`'=𝕩 ⋄ ∾⍟(1<≡)(¬<`o<t)/("<code>"‿"</code>"⥊˜≠)⌾(o⊸/)𝕩}¨⌾((¬b)⊸/)↩
    h ← 0<l ← {+´∧`'#'=𝕩}¨ lines
    lines ↩ l { o‿c←"<h"‿"</h"∾¨<('0'+𝕨)∾">" ⋄ (o⊸∾ ·∾⟜c (𝕨+1)⊸↓)⍟(𝕨>0) 𝕩 }¨ lines
    lines (∾⟜"<br>" ¯2⊸↓)⍟("  "≡¯2⊸↑)¨↩
    lines "<hr>"¨⌾((hr←"---"⊸≡¨lines)⊸/)↩
    p ← hr<b<h<""⊸≢¨lines
    "<p>"‿"</p>"{lines↩𝕨⊸∾¨⌾(𝕩⊸⊏)lines}¨<˘⍉∘‿2⥊/p≠0»p
    lines ↩ {𝕊 line:
        o‿c ← (<line)∊¨"[("‿"])"
        g ← (3∾˜c-˜+`o+c)⊔line
        i ← (↕3)+⌜˜/{𝕊a‿b‿c: ("["≡1↑a)∧(""≡b)∧"("≡1↑c}˘3↕g
        E ← (∾⟜".html" ¯3⊸↓)⍟(".md"≡¯3⊸↑)
        A ← {a‿·‿b: (∾⟨"<a href=""",E ¯1↓1↓b,""">",¯1↓1↓a,"</a>"⟩)‿""‿""}
        ∾(≢⥊A˘)⌾(i⊸⊏)g
    }¨ lines
    ⟨"<!DOCTYPE html>","<html lang=""en"">","<head>","<meta charset=""utf-8"">",
    "<meta name=""viewport"" content=""width=device-width, initial-scale=0.5"">",
    title, css, "</head>", "<body>"⟩∾lines∾⟨"</body>", "</html>"⟩
}
sourceFiles ← ∾{(".md"≡¯3⊸↑)¨⊸/ (𝕩∾'/')⊸∾¨•file.List 𝕩}¨ "source"‿"source/blog"
outFiles ← (∾⟜"html" ¯2 ↓ ·"docs"⊸∾ ⊐⟜'/'⊸↓)¨ sourceFiles
outFiles •FLines⟜(Md2html⟜•FLines)¨ sourceFiles
