package stencil.layout
{
    import stencil.core.MathUtil;
    import stencil.core.StencilError;

    /**
     * Pure ActionScript 3 implementation of the Cassowary linear constraint solving algorithm.
     * Uses incremental dual simplex tableau pivoting with multi-priority objective functions.
     */
    public class CassowarySolver extends Tableau
    {
        protected var _constraints:Array;
        protected var _errorMap:Object;     // Constraint -> Array of error variables
        protected var _markerMap:Object;    // Constraint -> marker Variable
        protected var _variables:Array;     // Registered external variables

        public function CassowarySolver()
        {
            super();
            _constraints = [];
            _errorMap = {};
            _markerMap = {};
            _variables = [];
        }

        public function get constraintCount():int
        {
            return _constraints.length;
        }

        public function registerVariable(v:Variable):void
        {
            if (_variables.indexOf(v) == -1)
            {
                _variables.push(v);
            }
        }

        public function hasConstraint(c:Constraint):Boolean
        {
            return _constraints.indexOf(c) != -1;
        }

        /**
         * Adds a constraint to the linear system and pivots to restore optimality.
         */
        public function addConstraint(c:Constraint):void
        {
            if (hasConstraint(c)) return;

            var expr:Expression = c.expression.clone();
            // Substitute any variables currently basic in the tableau
            for (var i:int = 0; i < expr.terms.length; i++)
            {
                var v:Variable = expr.terms[i].variable as Variable;
                if (isBasic(v))
                {
                    expr.substitute(v, rowFor(v));
                }
            }

            // Create marker and error variables
            if (c.isInequality())
            {
                // expr <= 0 -> expr + slack = 0 -> slack = -expr
                var slack:Variable = Variable.createSlack();
                _markerMap[c] = slack;
                expr.multiply(-1.0);

                if (!c.isRequired())
                {
                    var emMinus:Variable = Variable.createError("em");
                    expr.addVariable(emMinus, -1.0);
                    _errorMap[c] = [emMinus];
                }

                if (expr.constant < -MathUtil.EPSILON)
                {
                    addRow(slack, expr);
                    dualOptimize();
                }
                else
                {
                    addRow(slack, expr);
                }
            }
            else // Equality
            {
                if (c.isRequired())
                {
                    var dummy:Variable = Variable.createDummy();
                    _markerMap[c] = dummy;
                    expr.multiply(-1.0);
                    addRow(dummy, expr);
                    dualOptimize();
                }
                else
                {
                    var ep:Variable = Variable.createError("ep");
                    var em:Variable = Variable.createError("em");
                    _errorMap[c] = [ep, em];
                    _markerMap[c] = ep;

                    // expr == 0 -> expr - ep + em == 0 -> ep = expr + em
                    expr.addVariable(em, 1.0);
                    addRow(ep, expr);
                    dualOptimize();
                }
            }

            _constraints.push(c);
            updateExternalVariables();
        }

        /**
         * Removes a previously registered constraint.
         */
        public function removeConstraint(c:Constraint):void
        {
            var idx:int = _constraints.indexOf(c);
            if (idx == -1) return;

            _constraints.splice(idx, 1);
            var marker:Variable = _markerMap[c] as Variable;
            delete _markerMap[c];

            if (marker != null)
            {
                if (isBasic(marker))
                {
                    removeRow(marker);
                }
                else
                {
                    // Pivot marker out of basis
                    var basicVar:Variable = findRowForParametric(marker);
                    if (basicVar != null)
                    {
                        pivot(basicVar, marker);
                        removeRow(marker);
                    }
                }
            }

            dualOptimize();
            updateExternalVariables();
        }

        /**
         * Pivots entering parametric variable with leaving basic variable.
         */
        public function pivot(leaving:Variable, entering:Variable):void
        {
            var row:Expression = removeRow(leaving);

            // Solve row for entering variable:
            // leaving = c0 + coeff*entering + ... -> entering = (leaving - c0 - ...) / coeff
            var coeff:Number = row.getCoefficient(entering);
            row.addVariable(entering, -coeff); // remove entering term
            row.multiply(-1.0 / coeff);
            row.addVariable(leaving, 1.0 / coeff);

            substituteOut(entering, row);
            addRow(entering, row);
        }

        /**
         * Dual Simplex optimization loop: drives infeasibilities (negative row constants) to 0.
         */
        protected function dualOptimize():void
        {
            var iterations:int = 0;
            var maxIterations:int = 500;

            while (iterations++ < maxIterations)
            {
                // Find leaving variable (row with most negative constant)
                var leaving:Variable = null;
                var minConstant:Number = -MathUtil.EPSILON;

                for (var vId:String in _rows)
                {
                    var expr:Expression = _rows[vId] as Expression;
                    if (expr.constant < minConstant)
                    {
                        minConstant = expr.constant;
                        leaving = findVariableById(int(vId));
                    }
                }

                if (leaving == null)
                {
                    // Optimal and feasible
                    break;
                }

                // Ratio test: find entering variable
                var entering:Variable = null;
                var minRatio:Number = Number.MAX_VALUE;
                var leavingExpr:Expression = _rows[leaving.id] as Expression;

                for (var i:int = 0; i < leavingExpr.terms.length; i++)
                {
                    var term:Object = leavingExpr.terms[i];
                    var param:Variable = term.variable as Variable;
                    var c:Number = term.coefficient;

                    if (c > MathUtil.EPSILON)
                    {
                        // Candidate
                        var ratio:Number = Math.abs(c);
                        if (ratio < minRatio)
                        {
                            minRatio = ratio;
                            entering = param;
                        }
                    }
                }

                if (entering == null)
                {
                    // Infeasible system
                    break;
                }

                pivot(leaving, entering);
            }
        }

        protected function findRowForParametric(param:Variable):Variable
        {
            if (!_columns.hasOwnProperty(param.id)) return null;
            var list:Array = _columns[param.id] as Array;
            if (list.length > 0)
            {
                return findVariableById(list[0]);
            }
            return null;
        }

        protected function findVariableById(id:int):Variable
        {
            for (var i:int = 0; i < _variables.length; i++)
            {
                if (_variables[i].id == id) return _variables[i];
            }
            // Check marker map
            for (var k:Object in _markerMap)
            {
                var m:Variable = _markerMap[k] as Variable;
                if (m.id == id) return m;
            }
            return null;
        }

        /**
         * Copies solved values from tableau back to external variables.
         */
        public function updateExternalVariables():void
        {
            for (var i:int = 0; i < _variables.length; i++)
            {
                var v:Variable = _variables[i];
                if (isBasic(v))
                {
                    v.value = (_rows[v.id] as Expression).constant;
                }
                else
                {
                    v.value = 0.0;
                }
            }
        }
    }
}
