package test.geom
{
    import test.framework.Assert;
    import test.framework.TestCase;
    import stencil.geom.Matrix2D;
    import stencil.geom.Point2D;
    import stencil.core.MathUtil;

    public class Matrix2DTest extends TestCase
    {
        public function Matrix2DTest()
        {
            super("Matrix2DTest");
        }

        override public function getTestNames():Array
        {
            return [
                "testIdentityAndTranslation",
                "testScalingAndRotation",
                "testInversion",
                "testPointTransform",
                "testDecomposition"
            ];
        }

        public function testIdentityAndTranslation():void
        {
            var m:Matrix2D = Matrix2D.identity();
            Assert.fuzzyEquals(1.0, m.a);
            Assert.fuzzyEquals(1.0, m.d);
            Assert.fuzzyEquals(0.0, m.tx);
            Assert.fuzzyEquals(1.0, m.determinant());

            m.translate(50.0, -30.0);
            Assert.fuzzyEquals(50.0, m.tx);
            Assert.fuzzyEquals(-30.0, m.ty);
        }

        public function testScalingAndRotation():void
        {
            var m:Matrix2D = Matrix2D.scaling(2.0, 3.0);
            Assert.fuzzyEquals(6.0, m.determinant());

            var p:Point2D = m.transformPoint(new Point2D(10.0, 20.0));
            Assert.fuzzyEquals(20.0, p.x);
            Assert.fuzzyEquals(60.0, p.y);

            var rot:Matrix2D = Matrix2D.rotation(MathUtil.HALF_PI);
            var pRot:Point2D = rot.transformPoint(new Point2D(1.0, 0.0));
            Assert.fuzzyEquals(0.0, pRot.x, 1e-4);
            Assert.fuzzyEquals(1.0, pRot.y, 1e-4);
        }

        public function testInversion():void
        {
            var m:Matrix2D = Matrix2D.translation(100.0, 50.0);
            m.scale(2.0, 2.0);
            m.rotate(0.5);

            var inv:Matrix2D = m.getInverse();
            var identityProduct:Matrix2D = m.multiply(inv);

            Assert.fuzzyEquals(1.0, identityProduct.a, 1e-4);
            Assert.fuzzyEquals(0.0, identityProduct.b, 1e-4);
            Assert.fuzzyEquals(0.0, identityProduct.c, 1e-4);
            Assert.fuzzyEquals(1.0, identityProduct.d, 1e-4);
            Assert.fuzzyEquals(0.0, identityProduct.tx, 1e-4);
            Assert.fuzzyEquals(0.0, identityProduct.ty, 1e-4);
        }

        public function testPointTransform():void
        {
            var m:Matrix2D = Matrix2D.translation(10.0, 20.0);
            m.scale(2.0, 2.0);

            var pt:Point2D = new Point2D(5.0, 5.0);
            var res:Point2D = m.transformPoint(pt);

            Assert.fuzzyEquals(20.0, res.x);
            Assert.fuzzyEquals(30.0, res.y);
        }

        public function testDecomposition():void
        {
            var m:Matrix2D = Matrix2D.translation(40.0, 80.0);
            m.scale(3.0, 4.0);
            m.rotate(0.75);

            var decomp:Object = m.decompose();
            Assert.fuzzyEquals(40.0, decomp.translation.x);
            Assert.fuzzyEquals(80.0, decomp.translation.y);
            Assert.fuzzyEquals(3.0, decomp.scale.x, 1e-3);
            Assert.fuzzyEquals(4.0, decomp.scale.y, 1e-3);
            Assert.fuzzyEquals(0.75, decomp.rotation, 1e-3);
        }
    }
}
