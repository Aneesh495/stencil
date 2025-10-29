package stencil.layout
{
    /**
     * EditConstraint establishes an interactive drag or resize handle on a layout variable.
     * Allows high frequency suggested value updates during user pointer manipulation.
     */
    public class EditConstraint extends Constraint
    {
        protected var _variable:Variable;

        public function EditConstraint(variable:Variable, strength:Number = 1000000.0, weight:Number = 1.0)
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

        /**
         * Updates the suggested target value for this edit variable.
         */
        public function suggestValue(val:Number):void
        {
            _expression.constant = -val;
        }
    }
}
