package stencil.style
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;

    /**
     * DropShadowFilter encapsulates analytical Gaussian drop shadow and inner shadow parameters.
     */
    public class DropShadowFilter implements ICloneable, ISerializable
    {
        public var offsetX:Number;
        public var offsetY:Number;
        public var blurRadius:Number;
        public var spread:Number;
        public var color:Color;
        public var isInner:Boolean;

        public function DropShadowFilter(
            offsetX:Number = 0.0,
            offsetY:Number = 4.0,
            blurRadius:Number = 12.0,
            spread:Number = 0.0,
            color:Color = null,
            isInner:Boolean = false
        )
        {
            this.offsetX = offsetX;
            this.offsetY = offsetY;
            this.blurRadius = Math.max(0.0, blurRadius);
            this.spread = spread;
            this.color = (color != null) ? (color.clone() as Color) : Color.fromRGBA(0, 0, 0, 0.25);
            this.isInner = isInner;
        }

        public function clone():Object
        {
            return new DropShadowFilter(offsetX, offsetY, blurRadius, spread, color.clone() as Color, isInner);
        }

        public function toJSON():Object
        {
            return {
                offsetX: offsetX,
                offsetY: offsetY,
                blurRadius: blurRadius,
                spread: spread,
                color: color.toJSON(),
                isInner: isInner
            };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null)
            {
                if (data.offsetX != null) offsetX = Number(data.offsetX);
                if (data.offsetY != null) offsetY = Number(data.offsetY);
                if (data.blurRadius != null) blurRadius = Number(data.blurRadius);
                if (data.spread != null) spread = Number(data.spread);
                if (data.isInner != null) isInner = Boolean(data.isInner);
                if (data.color != null)
                {
                    color = new Color();
                    color.fromJSON(data.color);
                }
            }
        }
    }
}
