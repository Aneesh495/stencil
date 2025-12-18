package test.framework
{
    /**
     * TestRunner coordinates automated test suite execution and collects test metrics.
     */
    public class TestRunner
    {
        protected var _suites:Array;
        protected var _passed:int;
        protected var _failed:int;
        protected var _errors:Array;

        public function TestRunner()
        {
            _suites = [];
            _passed = 0;
            _failed = 0;
            _errors = [];
        }

        public function get passed():int { return _passed; }
        public function get failed():int { return _failed; }
        public function get total():int { return _passed + _failed; }

        public function addSuite(suite:TestCase):void
        {
            if (suite != null)
            {
                _suites.push(suite);
            }
        }

        public function run():Boolean
        {
            _passed = 0;
            _failed = 0;
            _errors = [];

            for (var i:int = 0; i < _suites.length; i++)
            {
                var suite:TestCase = _suites[i] as TestCase;
                var tests:Array = suite.getTestNames();

                for (var j:int = 0; j < tests.length; j++)
                {
                    var testName:String = tests[j];
                    try
                    {
                        suite.runTest(testName);
                        _passed++;
                    }
                    catch (err:Error)
                    {
                        _failed++;
                        _errors.push({
                            suite: suite.name,
                            test: testName,
                            message: err.message
                        });
                    }
                }
            }

            return _failed == 0;
        }

        public function printReport():String
        {
            var lines:Array = [];
            lines.push("==================================================");
            lines.push("           STENCIL VERIFICATION SUITE             ");
            lines.push("==================================================");
            lines.push("Total Tests: " + total);
            lines.push("Passed:      " + _passed);
            lines.push("Failed:      " + _failed);

            if (_failed > 0)
            {
                lines.push("--------------------------------------------------");
                lines.push("FAILURES:");
                for (var i:int = 0; i < _errors.length; i++)
                {
                    var err:Object = _errors[i];
                    lines.push("  [" + err.suite + " :: " + err.test + "] " + err.message);
                }
            }
            lines.push("==================================================");
            return lines.join("\n");
        }
    }
}
