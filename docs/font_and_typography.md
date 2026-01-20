# Font Parsing, Shaping, and Typography Engine

The `stencil.text` package provides a typography subsystem capable of binary font parsing, Unicode character shaping, and optimal paragraph line breaking.

## 1. Binary SFNT Font Table Parsing (`SFNTParser`)

TrueType (`.ttf`) and OpenType (`.otf`) fonts use the SFNT container format. Stencil decodes these binary structures directly using `ByteArrayUtil`:

### SFNT Offset Table & Directory
The font binary begins with an offset table specifying the scaler type (`0x00010000` for TrueType or `0x4F54544F` for OpenType CFF), table count, search range, entry selector, and range shift. Following the offset table is the table directory, where each 16-byte record identifies a 4-byte ASCII tag, checksum, byte offset, and length.

```
+--------------------------------------------------------+
| SFNT Offset Table (12 bytes)                           |
+--------------------------------------------------------+
| Table Record 0: 'cmap' (16 bytes: tag, check, off, len)|
| Table Record 1: 'head' (16 bytes: tag, check, off, len)|
| Table Record 2: 'hhea' (16 bytes: tag, check, off, len)|
| Table Record 3: 'maxp' (16 bytes: tag, check, off, len)|
+--------------------------------------------------------+
| Table Data Buffers ...                                 |
+--------------------------------------------------------+
```

### Table Decoders
- **`head` (Font Header)**: Decodes `unitsPerEm` (typically 1000 or 2048), font creation/modification timestamps, bounding box `[xMin, yMin, xMax, yMax]`, and `indexToLocFormat` (16-bit short vs 32-bit long glyph offsets).
- **`hhea` (Horizontal Header)**: Extracts typographic ascent, descent, line gap, maximum advance width, and `numOfLongHorMetrics`.
- **`maxp` (Maximum Profile)**: Reads `numGlyphs`, maximum points, and maximum contours.
- **`cmap` (Character to Glyph Index Mapping)**: Parses Format 4 sub-tables (segmented mapping for 16-bit Unicode BPM) with parallel arrays (`endCode`, `startCode`, `idDelta`, and `idRangeOffset`) to resolve Unicode codepoints to glyph indices in $O(\log S)$ time via binary search.

---

## 2. Text Shaping Pipeline (`TextShaper`)

Text rendering maps a sequence of Unicode characters to positioned glyph instances:

1. **Character Code Point Normalization**: Maps UTF-8 / UTF-16 code units into 32-bit scalar values, resolving surrogate pairs.
2. **Glyph Index Lookup**: Queries the font's parsed `cmap` table. Missing characters map to fallback index 0 (`.notdef`).
3. **Advance Metric Accumulation**: Reads each glyph's unscaled advance width from the horizontal metrics table and scales it by $\frac{\text{fontSize}}{\text{unitsPerEm}}$.
4. **Kerning Application**: Scans adjacent glyph pairs $(G_i, G_{i+1})$ in the `kern` table or GPOS pair-adjustment table to apply proportional horizontal spacing corrections.
5. **Position Cache Generation**: Outputs a `TextLayoutResult` containing absolute $(x, y)$ positions, cluster bounds, and selection hit-test indices.

---

## 3. Knuth-Plass Dynamic Programming Line Breaker

Unlike naive first-fit or greedy line breaking algorithms that produce uneven margins and unsightly rivers of white space, Stencil implements the Knuth-Plass line breaking algorithm. It balances line tightness across entire paragraphs using dynamic programming.

### Box, Glue, and Penalty Model
Paragraph content is decomposed into three structural primitives:
- **Box**: An unbreakable piece of content with fixed width (words or inline shapes).
- **Glue**: Flexible whitespace between boxes, defined by ideal width $w$, stretchability $y$, and shrinkability $z$.
- **Penalty**: Legal breakpoint opportunities with an associated cost $p$:
  - $p = -\infty$: Mandatory break (explicit newline `\n`).
  - $p = \infty$: Forbidden break.
  - $0 < p < \infty$: Discretionary hyphenation or punctuation break.

### Adjustment Ratio and Demerits
For a candidate line spanning from breakpoint $i$ to breakpoint $j$, the total content width $W$ is compared against the target line measure $L$:

- If $W < L$ (line needs expansion), adjustment ratio:
  
  $$r = \frac{L - W}{\sum \text{stretch}}$$
  
- If $W > L$ (line needs compression), adjustment ratio:
  
  $$r = \frac{L - W}{\sum \text{shrink}}$$

Lines with $r < -1$ are invalid (content would collide). For valid lines, demerits are computed based on badness:

$$d = \begin{cases} (1 + 100 |r|^3 + p)^2 & \text{if } p \ge 0 \\ (1 + 100 |r|^3)^2 - p^2 & \text{if } -\infty < p < 0 \end{cases}$$

An additional penalty is added if adjacent lines have incompatible tightness classifications (e.g. tight line followed immediately by a loose line).

### Dynamic Programming Formulation
Let $C[j]$ be the minimum accumulated demerits from paragraph start to breakpoint $j$:

$$C[j] = \min_{0 \le i < j} \left( C[i] + d(i, j) \right)$$

Stencil calculates $C[j]$ sequentially, pruning candidates that exceed an acceptable threshold. Once the paragraph terminal is reached, the optimal sequence of line breaks is recovered by backtracking through active predecessor links.
