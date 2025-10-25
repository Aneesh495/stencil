package stencil.layout
{
    /**
     * Constraint defines a linear equality or inequality relation in the Cassowary system.
     * Normalized to: expression OP 0, where OP is EQ, LEQ, or GEQ.
     */
    public class Constraint
    {
        public static const OP_EQ:int  = 1;
        public static const OP_LEQ:int = 2;
        public static const OP_GEQ:int = 3;

        protected var _expression:Expression;
        protected var _operator:int;
        protected var _strength:Number;
        protected var _weight:Number;

        public function Constraint(
            expression:Expression,
            operator:int = 1,
            strength:Number = 1000000.0,
            weight:Number = 1.0
        )
        {
            _expression = expression.clone();
            _operator = operator;
            _strength = strength;
            _weight = weight;
        }

        public static function equals(
            lhs:Expression,
            rhs:Expression,
            strength:Number = 1000000.0,
            weight:Number = 1.0
        ):Constraint
        {
            // lhs == rhs -> lhs - rhs == 0
            var expr:Expression = lhs.clone();
            expr.addExpression(rhs, -1.0);
            return new Constraint(expr, OP_EQ, strength, weight);
        }

        public static function lessOrEqual(
            lhs:Expression,
            rhs:Expression,
            strength:Number = 1000000.0,
            weight:Number = 1.0
        ):Constraint
        {
            // lhs <= rhs -> lhs - rhs <= 0
            var expr:Expression = lhs.clone();
            expr.addExpression(rhs, -1.0);
            return new Constraint(expr, OP_LEQ, strength, weight);
        }

        public static function greaterOrEqual(
            lhs:Expression,
            rhs:Expression,
            strength:Number = 1000000.0,
            weight:Number = 1.0
        ):Constraint
        {
            // lhs >= rhs -> lhs - rhs >= 0
            var expr:Expression = lhs.clone();
            expr.addExpression(rhs, -1.0);
            return new Constraint(expr, OP_GEQ, strength, weight);
        }

        public function get expression():Expression { return _expression; }
        public function get operator():int { return _operator; }
        public function get strength():Number { return _strength; }
        public function get weight():Number { return _weight; }

        public function isRequired():Boolean
        {
            return _strength >= Strength.REQUIRED;
        }

        public function isEquality():Boolean
        {
            return _operator == OP_EQ;
        }

        public function isInequality():Boolean
        {
            return _operator == OP_LEQ || _operator == OP_GEQ;
        }
    }
}
