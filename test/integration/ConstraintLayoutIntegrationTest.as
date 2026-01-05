package test.integration
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.layout.CassowarySolver;
    import stencil.layout.Constraint;
    import stencil.layout.EditConstraint;
    import stencil.layout.Expression;
    import stencil.layout.Strength;
    import stencil.layout.Variable;
    import stencil.scene.ShapeNode;

    public class ConstraintLayoutIntegrationTest extends TestCase
    {
        public function ConstraintLayoutIntegrationTest()
        {
            super("ConstraintLayoutIntegrationTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testResponsiveCardLayout"
            ];
        }

        public function testResponsiveCardLayout():void
        {
            var solver:CassowarySolver = new CassowarySolver();

            var containerWidth:Variable = new Variable("containerW", 800.0);
            var leftCardWidth:Variable = new Variable("leftCardW", 0.0);
            var rightCardWidth:Variable = new Variable("rightCardW", 0.0);

            solver.registerVariable(containerWidth);
            solver.registerVariable(leftCardWidth);
            solver.registerVariable(rightCardWidth);

            // Constraint 1: leftCardWidth == rightCardWidth (equal split)
            var eqSplit:Expression = Expression.fromVariable(leftCardWidth, 1.0);
            eqSplit.addVariable(rightCardWidth, -1.0);
            solver.addConstraint(new Constraint(eqSplit, Constraint.OP_EQ, Strength.REQUIRED));

            // Constraint 2: leftCardWidth + rightCardWidth + 40 (gap) == containerWidth
            var totalSum:Expression = Expression.fromVariable(leftCardWidth, 1.0);
            totalSum.addVariable(rightCardWidth, 1.0);
            totalSum.addVariable(containerWidth, -1.0);
            totalSum.constant = 40.0;
            solver.addConstraint(new Constraint(totalSum, Constraint.OP_EQ, Strength.REQUIRED));

            // Drag container width to 840
            var edit:EditConstraint = new EditConstraint(containerWidth, Strength.STRONG);
            solver.addConstraint(edit);
            edit.suggestValue(840.0);
            solver.addConstraint(edit);

            // Each card should be (840 - 40) / 2 = 400
            Assert.fuzzyEquals(400.0, leftCardWidth.value);
            Assert.fuzzyEquals(400.0, rightCardWidth.value);
        }
    }
}
