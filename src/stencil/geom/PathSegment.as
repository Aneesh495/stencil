package stencil.geom
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;

    /**
     * PathSegment represents an individual instruction in a compound vector path.
     */
    public class PathSegment implements ICloneable, ISerializable
    {
        public var command:int;
        public var points:Array; // Array of Point2D

        public function PathSegment(command:int = 1, points:Array = null)
        {
            this.command = command;
            this.points = (points != null) ? points : [];
        }

        public function get endPoint():Point2D
        {
            if (points.length > 0)
            {
                return points[points.length - 1] as Point2D;
            }
            return null;
        }

        public function clone():Object
        {
            var pts:Array = [];
            for (var i:int = 0; i < points.length; i++)
            {
                pts.push((points[i] as Point2D).clone());
            }
            return new PathSegment(command, pts);
        }

        public function toJSON():Object
        {
            var rawPts:Array = [];
            for (var i:int = 0; i < points.length; i++)
            {
                rawPts.push((points[i] as Point2D).toJSON());
            }
            return {
                command: command,
                points: rawPts
            };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                command = int(data.command);
                points = [];
                if (data.points is Array)
                {
                    var arr:Array = data.points as Array;
                    for (var i:int = 0; i < arr.length; i++)
                    {
                        var p:Point2D = new Point2D();
                        p.fromJSON(arr[i]);
                        points.push(p);
                    }
                }
            }
        }

        public function toString():String
        {
            return "PathSegment(" + PathCommand.toString(command) + ", pts=" + points.length + ")";
        }
    }
}
