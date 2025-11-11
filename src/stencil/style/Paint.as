package stencil.style
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;

    /**
     * Base class for surface shaders, solid fills, and multi-stop gradient paints.
     */
    public class Paint implements ICloneable, ISerializable
    {
        public var opacity:Number;

        public function Paint(opacity:Number = 1.0)
        {
            this.opacity = opacity;
        }

        public function clone():Object
        {
            return new Paint(opacity);
        }

        public function toJSON():Object
        {
            return { type: "Paint", opacity: opacity };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null && data.opacity != null)
            {
                opacity = Number(data.opacity);
            }
        }
    }
}
