package stencil.style
{
    /**
     * SolidPaint fills geometries with a uniform single color.
     */
    public class SolidPaint extends Paint
    {
        public var color:Color;

        public function SolidPaint(color:Color = null, opacity:Number = 1.0)
        {
            super(opacity);
            this.color = (color != null) ? (color.clone() as Color) : new Color(0xFF000000);
        }

        override public function clone():Object
        {
            return new SolidPaint(color.clone() as Color, opacity);
        }

        override public function toJSON():Object
        {
            var data:Object = super.toJSON();
            data.type = "SolidPaint";
            data.color = color.toJSON();
            return data;
        }

        override public function fromJSON(data:Object):void
        {
            super.fromJSON(data);
            if (data != null && data.color != null)
            {
                color = new Color();
                color.fromJSON(data.color);
            }
        }
    }
}
