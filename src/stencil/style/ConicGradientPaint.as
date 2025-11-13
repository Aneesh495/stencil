package stencil.style
{
    import stencil.core.MathUtil;
    import stencil.geom.Point2D;

    /**
     * ConicGradientPaint creates angular sweep gradients interpolated clockwise around a center pivot.
     */
    public class ConicGradientPaint extends Paint
    {
        public var center:Point2D;
        public var startAngle:Number; // in radians
        public var stops:Array;

        public function ConicGradientPaint(
            center:Point2D = null,
            startAngle:Number = 0.0,
            stops:Array = null,
            opacity:Number = 1.0
        )
        {
            super(opacity);
            this.center = (center != null) ? (center.clone() as Point2D) : new Point2D(0.0, 0.0);
            this.startAngle = startAngle;
            this.stops = (stops != null) ? stops : [];
        }

        public function addStop(offset:Number, color:Color):void
        {
            stops.push(new GradientStop(offset, color));
            sortStops();
        }

        public function sortStops():void
        {
            stops.sort(function(a:GradientStop, b:GradientStop):int {
                if (a.offset < b.offset) return -1;
                if (a.offset > b.offset) return 1;
                return 0;
            });
        }

        public function sample(x:Number, y:Number):Color
        {
            var dx:Number = x - center.x;
            var dy:Number = y - center.y;
            var theta:Number = Math.atan2(dy, dx) - startAngle;

            theta = MathUtil.normalizeAngle(theta);
            var t:Number = theta / MathUtil.TWO_PI;

            return sampleNormalized(t);
        }

        public function sampleNormalized(t:Number):Color
        {
            if (stops.length == 0) return new Color(0xFF000000);
            if (stops.length == 1) return (stops[0] as GradientStop).color.clone() as Color;

            t = MathUtil.clamp(t, 0.0, 1.0);

            var firstStop:GradientStop = stops[0] as GradientStop;
            if (t <= firstStop.offset) return firstStop.color.clone() as Color;

            var lastStop:GradientStop = stops[stops.length - 1] as GradientStop;
            if (t >= lastStop.offset) return lastStop.color.clone() as Color;

            for (var i:int = 0; i < stops.length - 1; i++)
            {
                var s0:GradientStop = stops[i] as GradientStop;
                var s1:GradientStop = stops[i + 1] as GradientStop;
                if (t >= s0.offset && t <= s1.offset)
                {
                    var range:Number = s1.offset - s0.offset;
                    var localT:Number = (range > 0.0) ? ((t - s0.offset) / range) : 0.0;
                    return s0.color.lerp(s1.color, localT);
                }
            }

            return lastStop.color.clone() as Color;
        }

        override public function clone():Object
        {
            var stopCopies:Array = [];
            for (var i:int = 0; i < stops.length; i++)
            {
                stopCopies.push((stops[i] as GradientStop).clone());
            }
            return new ConicGradientPaint(center.clone() as Point2D, startAngle, stopCopies, opacity);
        }

        override public function toJSON():Object
        {
            var data:Object = super.toJSON();
            data.type = "ConicGradientPaint";
            data.center = center.toJSON();
            data.startAngle = startAngle;
            var stopArr:Array = [];
            for (var i:int = 0; i < stops.length; i++)
            {
                stopArr.push((stops[i] as GradientStop).toJSON());
            }
            data.stops = stopArr;
            return data;
        }

        override public function fromJSON(data:Object):void
        {
            super.fromJSON(data);
            if (data != null)
            {
                if (data.center != null) center.fromJSON(data.center);
                if (data.startAngle != null) startAngle = Number(data.startAngle);
                stops = [];
                if (data.stops is Array)
                {
                    var arr:Array = data.stops as Array;
                    for (var i:int = 0; i < arr.length; i++)
                    {
                        var s:GradientStop = new GradientStop();
                        s.fromJSON(arr[i]);
                        stops.push(s);
                    }
                }
            }
        }
    }
}
