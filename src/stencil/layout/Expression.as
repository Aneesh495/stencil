package stencil.layout
{
    import stencil.core.MathUtil;

    /**
     * Expression represents a linear combination: constant + sum(c_i * v_i).
     * Provides algebraic operations, term simplifications, and variable substitution.
     */
    public class Expression
    {
        public var constant:Number;
        public var terms:Array; // Array of { variable: Variable, coefficient: Number }

        public function Expression(constant:Number = 0.0)
        {
            this.constant = constant;
            this.terms = [];
        }

        public static function fromVariable(v:Variable, coefficient:Number = 1.0):Expression
        {
            var expr:Expression = new Expression(0.0);
            expr.addVariable(v, coefficient);
            return expr;
        }

        public function addVariable(v:Variable, coefficient:Number = 1.0):Expression
        {
            if (MathUtil.fuzzyZero(coefficient)) return this;

            for (var i:int = 0; i < terms.length; i++)
            {
                var term:Object = terms[i];
                if (term.variable === v)
                {
                    term.coefficient += coefficient;
                    if (MathUtil.fuzzyZero(term.coefficient))
                    {
                        terms.splice(i, 1);
                    }
                    return this;
                }
            }

            terms.push({ variable: v, coefficient: coefficient });
            return this;
        }

        public function addExpression(expr:Expression, factor:Number = 1.0):Expression
        {
            this.constant += expr.constant * factor;
            for (var i:int = 0; i < expr.terms.length; i++)
            {
                var term:Object = expr.terms[i];
                addVariable(term.variable as Variable, term.coefficient * factor);
            }
            return this;
        }

        public function multiply(factor:Number):Expression
        {
            this.constant *= factor;
            for (var i:int = 0; i < terms.length; i++)
            {
                terms[i].coefficient *= factor;
            }
            return this;
        }

        public function divide(divisor:Number):Expression
        {
            if (!MathUtil.fuzzyZero(divisor))
            {
                return multiply(1.0 / divisor);
            }
            return this;
        }

        public function getCoefficient(v:Variable):Number
        {
            for (var i:int = 0; i < terms.length; i++)
            {
                if (terms[i].variable === v)
                {
                    return terms[i].coefficient;
                }
            }
            return 0.0;
        }

        public function hasVariable(v:Variable):Boolean
        {
            return !MathUtil.fuzzyZero(getCoefficient(v));
        }

        /**
         * Replaces variable v with expression expr wherever it appears:
         * this = this - coeff * v + coeff * expr
         */
        public function substitute(v:Variable, expr:Expression):void
        {
            var coeff:Number = getCoefficient(v);
            if (MathUtil.fuzzyZero(coeff)) return;

            // Remove term for v
            for (var i:int = 0; i < terms.length; i++)
            {
                if (terms[i].variable === v)
                {
                    terms.splice(i, 1);
                    break;
                }
            }

            // Add scaled expression
            addExpression(expr, coeff);
        }

        public function clone():Expression
        {
            var copy:Expression = new Expression(this.constant);
            for (var i:int = 0; i < terms.length; i++)
            {
                copy.terms.push({
                    variable: terms[i].variable,
                    coefficient: terms[i].coefficient
                });
            }
            return copy;
        }

        public function toString():String
        {
            var parts:Array = [];
            for (var i:int = 0; i < terms.length; i++)
            {
                parts.push(terms[i].coefficient + "*" + terms[i].variable.name);
            }
            if (constant != 0.0 || parts.length == 0)
            {
                parts.push(String(constant));
            }
            return parts.join(" + ");
        }
    }
}
