package test.layout
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.layout.CassowarySolver;
    import stencil.layout.Constraint;
    import stencil.layout.EditConstraint;
    import stencil.layout.Expression;
    import stencil.layout.Strength;
    import stencil.layout.Variable;

    public class CassowarySolverTest extends TestCase
    {
        public function CassowarySolverTest()
        {
            super("CassowarySolverTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testSimpleEquality",
                "testCoupledVariables",
                "testInequalities",
                "testEditConstraint"
            ];
        }

        public function testSimpleEquality():void
        {
            var solver:CassowarySolver = new CassowarySolver();
            var x:Variable = new Variable("x", 0.0);
            solver.registerVariable(x);

            // x + 20 == 100 -> x == 80
            var expr:Expression = Expression.fromVariable(x, 1.0);
            expr.constant = -80.0;
            var c:Constraint = new Constraint(expr, Constraint.OP_EQ, Strength.REQUIRED);

            solver.addConstraint(c);
            Assert.fuzzyEquals(80.0, x.value);
        }

        public function testCoupledVariables():void
        {
            var solver:CassowarySolver = new CassowarySolver();
            var x:Variable = new Variable("x", 0.0);
            var y:Variable = new Variable("y", 0.0);
            solver.registerVariable(x);
            solver.registerVariable(y);

            // Equation 1: x + y == 100
            var e1:Expression = Expression.fromVariable(x, 1.0);
            e1.addVariable(y, 1.0);
            e1.constant = -100.0;
            solver.addConstraint(new Constraint(e1, Constraint.OP_EQ, Strength.REQUIRED));

            // Equation 2: x - y == 20
            var e2:Expression = Expression.fromVariable(x, 1.0);
            e2.addVariable(y, -1.0);
            e2.constant = -20.0;
            solver.addConstraint(new Constraint(e2, Constraint.OP_EQ, Strength.REQUIRED));

            Assert.fuzzyEquals(60.0, x.value);
            Assert.fuzzyEquals(40.0, y.value);
        }

        public function testInequalities():void
        {
            var solver:CassowarySolver = new CassowarySolver();
            var x:Variable = new Variable("x", 10.0);
            solver.registerVariable(x);

            // x >= 50 -> 50 - x <= 0
            var ineq:Expression = Expression.fromVariable(x, -1.0);
            ineq.constant = 50.0;
            solver.addConstraint(new Constraint(ineq, Constraint.OP_LEQ, Strength.REQUIRED));

            Assert.fuzzyEquals(50.0, x.value);
        }

        public function testEditConstraint():void
        {
            var solver:CassowarySolver = new CassowarySolver();
            var p:Variable = new Variable("p", 25.0);
            solver.registerVariable(p);

            var edit:EditConstraint = new EditConstraint(p, Strength.STRONG);
            solver.addConstraint(edit);

            edit.suggestValue(150.0);
            solver.addConstraint(edit); // Re-solve
            Assert.fuzzyEquals(150.0, p.value);
        }
    }
}
