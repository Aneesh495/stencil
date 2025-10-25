package stencil.layout
{
    import stencil.core.MathUtil;

    /**
     * Tableau maintains the Simplex matrix equations for the Cassowary linear solver.
     * Maps basic variables to linear expressions over non-basic (parametric) variables.
     */
    public class Tableau
    {
        protected var _rows:Object;      // Variable ID -> Expression
        protected var _columns:Object;   // Variable ID -> Array of basic Variable IDs
        protected var _infeasibleRows:Array; // Array of basic Variables with negative constant

        public function Tableau()
        {
            _rows = {};
            _columns = {};
            _infeasibleRows = [];
        }

        public function get rows():Object { return _rows; }
        public function get columns():Object { return _columns; }

        public function isBasic(v:Variable):Boolean
        {
            return _rows.hasOwnProperty(v.id);
        }

        public function rowFor(v:Variable):Expression
        {
            if (_rows.hasOwnProperty(v.id))
            {
                return _rows[v.id] as Expression;
            }
            return null;
        }

        /**
         * Adds an equation to the tableau: basicVar = expr.
         */
        public function addRow(basicVar:Variable, expr:Expression):void
        {
            _rows[basicVar.id] = expr;

            for (var i:int = 0; i < expr.terms.length; i++)
            {
                var paramVar:Variable = expr.terms[i].variable as Variable;
                insertColumnVar(paramVar, basicVar);
            }

            if (expr.constant < -MathUtil.EPSILON)
            {
                _infeasibleRows.push(basicVar);
            }
        }

        /**
         * Removes a row equation from the tableau.
         */
        public function removeRow(basicVar:Variable):Expression
        {
            if (!_rows.hasOwnProperty(basicVar.id)) return null;

            var expr:Expression = _rows[basicVar.id] as Expression;
            delete _rows[basicVar.id];

            for (var i:int = 0; i < expr.terms.length; i++)
            {
                var paramVar:Variable = expr.terms[i].variable as Variable;
                removeColumnVar(paramVar, basicVar);
            }

            var infIdx:int = _infeasibleRows.indexOf(basicVar);
            if (infIdx != -1)
            {
                _infeasibleRows.splice(infIdx, 1);
            }

            return expr;
        }

        /**
         * Substitutes out a parametric variable across all rows where it appears:
         * row_i = row_i.substitute(varToReplace, replacementExpr)
         */
        public function substituteOut(varToReplace:Variable, replacementExpr:Expression):void
        {
            if (!_columns.hasOwnProperty(varToReplace.id)) return;

            var affectedBasicVarIds:Array = (_columns[varToReplace.id] as Array).slice();
            delete _columns[varToReplace.id];

            for (var i:int = 0; i < affectedBasicVarIds.length; i++)
            {
                var bId:int = affectedBasicVarIds[i];
                var rowExpr:Expression = _rows[bId] as Expression;

                rowExpr.substitute(varToReplace, replacementExpr);

                // Update column references for newly added variables
                for (var j:int = 0; j < replacementExpr.terms.length; j++)
                {
                    var newParam:Variable = replacementExpr.terms[j].variable as Variable;
                    insertColumnVarById(newParam.id, bId);
                }

                // Update infeasibility list
                var bVar:Variable = null; // Basic var lookup
                if (rowExpr.constant < -MathUtil.EPSILON)
                {
                    // Mark infeasible if needed
                }
            }
        }

        protected function insertColumnVar(paramVar:Variable, basicVar:Variable):void
        {
            insertColumnVarById(paramVar.id, basicVar.id);
        }

        protected function insertColumnVarById(paramVarId:int, basicVarId:int):void
        {
            if (!_columns.hasOwnProperty(paramVarId))
            {
                _columns[paramVarId] = [];
            }
            var list:Array = _columns[paramVarId] as Array;
            if (list.indexOf(basicVarId) == -1)
            {
                list.push(basicVarId);
            }
        }

        protected function removeColumnVar(paramVar:Variable, basicVar:Variable):void
        {
            if (!_columns.hasOwnProperty(paramVar.id)) return;
            var list:Array = _columns[paramVar.id] as Array;
            var idx:int = list.indexOf(basicVar.id);
            if (idx != -1)
            {
                list.splice(idx, 1);
                if (list.length == 0)
                {
                    delete _columns[paramVar.id];
                }
            }
        }
    }
}
