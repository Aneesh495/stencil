package test.framework
{
    /**
     * Base unit test case contract providing lifecycle hooks and test method execution.
     */
    public class TestCase
    {
        public var name:String;

        public function TestCase(name:String = "")
        {
            this.name = (name.length > 0) ? name : getClassName();
        }

        public function setUp():void
        {
        }

        public function tearDown():void
        {
        }

        public function getTestNames():Array
        {
            return [];
        }

        public function runTest(testName:String):void
        {
            setUp();
            try
            {
                if (this.hasOwnProperty(testName) && this[testName] is Function)
                {
                    this[testName]();
                }
            }
            finally
            {
                tearDown();
            }
        }

        protected function getClassName():String
        {
            return "TestCase";
        }
    }
}
