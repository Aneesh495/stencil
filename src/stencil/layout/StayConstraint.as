package stencil.layout
{
    /**
     * StayConstraint anchors a variable to its current value with default weak or medium strength.
     * Prevents unconstrained layout elements from drifting arbitrarily during solve passes.
     */
    public class StayConstraint extends Constraint
    {
        protected var _variable:Variable;

        public function StayConstraint(variable:Variable, strength:Number = 1.0, weight:Number = 1.0)
        {
            var expr:Expression = Expression.fromVariable(variable, 1.0);
            expr.constant = -variable.value;
            super(expr, Constraint.OP_EQ, strength, weight);
            _variable = variable;
        }

        public function get variable():Variable
        {
            return _variable;
        }
    }
}
