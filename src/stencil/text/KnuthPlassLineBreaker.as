package stencil.text
{
    /**
     * Knuth-Plass optimal paragraph line breaking algorithm.
     * Evaluates boxes, glues, and penalties using dynamic programming to eliminate ragged lines.
     */
    public class KnuthPlassLineBreaker
    {
        public static const TYPE_BOX:int     = 1;
        public static const TYPE_GLUE:int    = 2;
        public static const TYPE_PENALTY:int = 3;

        public static const INFINITY:Number = 100000000.0;

        /**
         * Represents a typographic node: Box, Glue, or Penalty.
         */
        public static function makeBox(width:Number, value:String = ""):Object
        {
            return { type: TYPE_BOX, width: width, value: value };
        }

        public static function makeGlue(width:Number, stretch:Number, shrink:Number):Object
        {
            return { type: TYPE_GLUE, width: width, stretch: stretch, shrink: shrink };
        }

        public static function makePenalty(width:Number, penalty:Number, flagged:Boolean = false):Object
        {
            return { type: TYPE_PENALTY, width: width, penalty: penalty, flagged: flagged };
        }

        /**
         * Breaks a stream of nodes into optimal line breaks for a given line width.
         * Returns an array of line breakpoint indices.
         */
        public static function breakParagraph(nodes:Array, lineWidth:Number, tolerance:Number = 1.0):Array
        {
            if (nodes == null || nodes.length == 0 || lineWidth <= 0) return [];

            var n:int = nodes.length;
            // Precompute cumulative sums of width, stretch, shrink
            var cumWidth:Array = new Array(n + 1);
            var cumStretch:Array = new Array(n + 1);
            var cumShrink:Array = new Array(n + 1);

            cumWidth[0] = 0.0;
            cumStretch[0] = 0.0;
            cumShrink[0] = 0.0;

            for (var i:int = 0; i < n; i++)
            {
                var node:Object = nodes[i];
                cumWidth[i + 1] = cumWidth[i] + Number(node.width);
                cumStretch[i + 1] = cumStretch[i] + (node.type == TYPE_GLUE ? Number(node.stretch) : 0.0);
                cumShrink[i + 1] = cumShrink[i] + (node.type == TYPE_GLUE ? Number(node.shrink) : 0.0);
            }

            // Dynamic programming arrays
            // minDemerits[i]: minimum total demerits for breaking up to node i
            var minDemerits:Array = new Array(n + 1);
            var prevBreak:Array = new Array(n + 1);

            for (var k:int = 0; k <= n; k++)
            {
                minDemerits[k] = INFINITY;
                prevBreak[k] = -1;
            }
            minDemerits[0] = 0.0;

            // Iterate over all potential candidate breakpoints
            for (var j:int = 1; j <= n; j++)
            {
                var candNode:Object = nodes[j - 1];
                // Feasible breakpoint if penalty < INFINITY or glue following a box
                var isFeasible:Boolean = false;
                if (candNode.type == TYPE_PENALTY && candNode.penalty < INFINITY)
                {
                    isFeasible = true;
                }
                else if (candNode.type == TYPE_GLUE && j > 1 && nodes[j - 2].type == TYPE_BOX)
                {
                    isFeasible = true;
                }
                else if (j == n)
                {
                    isFeasible = true;
                }

                if (!isFeasible) continue;

                // Test prior breakpoints
                for (var prev:int = 0; prev < j; prev++)
                {
                    if (minDemerits[prev] >= INFINITY) continue;

                    var w:Number = cumWidth[j] - cumWidth[prev];
                    var s:Number = cumStretch[j] - cumStretch[prev];
                    var sh:Number = cumShrink[j] - cumShrink[prev];

                    var diff:Number = lineWidth - w;
                    var r:Number = 0.0;

                    if (diff > 0.0)
                    {
                        r = (s > 0.0) ? (diff / s) : INFINITY;
                    }
                    else if (diff < 0.0)
                    {
                        r = (sh > 0.0) ? (diff / sh) : -INFINITY;
                    }

                    if (r < -1.0)
                    {
                        // Overfull line: cannot shrink further
                        continue;
                    }

                    // Compute badness
                    var badness:Number = 100.0 * Math.pow(Math.abs(r), 3.0);
                    var penalty:Number = (candNode.type == TYPE_PENALTY) ? candNode.penalty : 0.0;
                    var demerits:Number;

                    if (penalty >= 0)
                    {
                        demerits = Math.pow(1.0 + badness + penalty, 2.0);
                    }
                    else if (penalty > -INFINITY)
                    {
                        demerits = Math.pow(1.0 + badness, 2.0) - Math.pow(penalty, 2.0);
                    }
                    else
                    {
                        demerits = Math.pow(1.0 + badness, 2.0);
                    }

                    var totalDemerits:Number = minDemerits[prev] + demerits;
                    if (totalDemerits < minDemerits[j])
                    {
                        minDemerits[j] = totalDemerits;
                        prevBreak[j] = prev;
                    }
                }
            }

            // Backtrack optimal line break indices
            var breaks:Array = [];
            var curr:int = n;

            while (curr > 0 && prevBreak[curr] != -1)
            {
                breaks.unshift(curr);
                curr = prevBreak[curr];
            }

            return breaks;
        }
    }
}
