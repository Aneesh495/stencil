package stencil.style
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;

    /**
     * GradientStop defines a normalized position offset and color sample within a gradient shader.
     */
    public class GradientStop implements ICloneable, ISerializable
    {
        public var offset:Number; // 0.0 to 1.0
        public var color:Color;

        public function GradientStop(offset:Number = 0.0, color:Color = null)
        {
            this.offset = offset;
            this.color = (color != null) ? (color.clone() as Color) : new Color(0xFF000000);
        }

        public function clone():Object
        {
            return new GradientStop(offset, color.clone() as Color);
        }

        public function toJSON():Object
        {
            return { offset: offset, color: color.toJSON() };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                offset = Number(data.offset);
                color = new Color();
                color.fromJSON(data.color);
            }
        }
    }
}
