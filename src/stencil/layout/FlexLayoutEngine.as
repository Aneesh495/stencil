package stencil.layout
{
    import stencil.geom.Rect2D;

    /**
     * Responsive flexbox layout engine.
     * Computes 1D linear container flows with main-axis distribution and cross-axis alignment.
     */
    public class FlexLayoutEngine
    {
        public static const DIR_ROW:String = "row";
        public static const DIR_COLUMN:String = "column";

        public static const JUSTIFY_START:String = "flexStart";
        public static const JUSTIFY_CENTER:String = "center";
        public static const JUSTIFY_END:String = "flexEnd";
        public static const JUSTIFY_SPACE_BETWEEN:String = "spaceBetween";
        public static const JUSTIFY_SPACE_AROUND:String = "spaceAround";
        public static const JUSTIFY_SPACE_EVENLY:String = "spaceEvenly";

        public static const ALIGN_START:String = "flexStart";
        public static const ALIGN_CENTER:String = "center";
        public static const ALIGN_END:String = "flexEnd";
        public static const ALIGN_STRETCH:String = "stretch";

        public var direction:String;
        public var justifyContent:String;
        public var alignItems:String;
        public var gap:Number;
        public var paddingTop:Number;
        public var paddingRight:Number;
        public var paddingBottom:Number;
        public var paddingLeft:Number;

        public function FlexLayoutEngine()
        {
            direction = DIR_ROW;
            justifyContent = JUSTIFY_START;
            alignItems = ALIGN_START;
            gap = 0.0;
            paddingTop = 0.0;
            paddingRight = 0.0;
            paddingBottom = 0.0;
            paddingLeft = 0.0;
        }

        public function setPadding(top:Number, right:Number, bottom:Number, left:Number):void
        {
            paddingTop = top;
            paddingRight = right;
            paddingBottom = bottom;
            paddingLeft = left;
        }

        /**
         * Lays out an array of items within specified container dimensions.
         * Each item in items array is an object:
         * { width: Number, height: Number, flexGrow: Number, flexShrink: Number, flexBasis: Number }
         * Returns an array of Rect2D computed frames.
         */
        public function layout(containerWidth:Number, containerHeight:Number, items:Array):Array
        {
            var results:Array = [];
            if (items == null || items.length == 0) return results;

            var isRow:Boolean = (direction == DIR_ROW);
            var availMain:Number = isRow ? (containerWidth - paddingLeft - paddingRight) :
                                           (containerHeight - paddingTop - paddingBottom);
            var availCross:Number = isRow ? (containerHeight - paddingTop - paddingBottom) :
                                            (containerWidth - paddingLeft - paddingRight);

            var totalGaps:Number = (items.length > 1) ? (gap * (items.length - 1)) : 0.0;
            var sumMain:Number = 0.0;
            var totalGrow:Number = 0.0;

            for (var i:int = 0; i < items.length; i++)
            {
                var item:Object = items[i];
                var mainSize:Number = isRow ? item.width : item.height;
                sumMain += mainSize;
                totalGrow += (item.flexGrow != null) ? Number(item.flexGrow) : 0.0;
            }

            var freeSpace:Number = availMain - totalGaps - sumMain;

            // Distribute positive free space via flexGrow
            var computedMainSizes:Array = [];
            for (var j:int = 0; j < items.length; j++)
            {
                var itm:Object = items[j];
                var baseMain:Number = isRow ? itm.width : itm.height;
                var grow:Number = (itm.flexGrow != null) ? Number(itm.flexGrow) : 0.0;

                if (freeSpace > 0.0 && totalGrow > 0.0)
                {
                    computedMainSizes.push(baseMain + (grow / totalGrow) * freeSpace);
                }
                else
                {
                    computedMainSizes.push(baseMain);
                }
            }

            // Recalculate remaining free space for justification
            var actualMainTotal:Number = totalGaps;
            for (var k:int = 0; k < computedMainSizes.length; k++)
            {
                actualMainTotal += computedMainSizes[k];
            }
            var remainingMain:Number = Math.max(0.0, availMain - actualMainTotal);

            // Compute main-axis starting offset and spacing
            var mainOffset:Number = isRow ? paddingLeft : paddingTop;
            var spaceBetweenStep:Number = gap;

            if (remainingMain > 0.0)
            {
                switch (justifyContent)
                {
                    case JUSTIFY_CENTER:
                        mainOffset += remainingMain * 0.5;
                        break;
                    case JUSTIFY_END:
                        mainOffset += remainingMain;
                        break;
                    case JUSTIFY_SPACE_BETWEEN:
                        if (items.length > 1)
                        {
                            spaceBetweenStep += remainingMain / (items.length - 1);
                        }
                        break;
                    case JUSTIFY_SPACE_AROUND:
                        var halfStep:Number = remainingMain / (items.length * 2.0);
                        mainOffset += halfStep;
                        spaceBetweenStep += halfStep * 2.0;
                        break;
                    case JUSTIFY_SPACE_EVENLY:
                        var evenStep:Number = remainingMain / (items.length + 1.0);
                        mainOffset += evenStep;
                        spaceBetweenStep += evenStep;
                        break;
                }
            }

            // Position each item
            var currentMain:Number = mainOffset;
            for (var idx:int = 0; idx < items.length; idx++)
            {
                var itemObj:Object = items[idx];
                var mSize:Number = computedMainSizes[idx];
                var crossSize:Number = isRow ? itemObj.height : itemObj.width;

                if (alignItems == ALIGN_STRETCH)
                {
                    crossSize = availCross;
                }

                var crossOffset:Number = isRow ? paddingTop : paddingLeft;
                if (alignItems == ALIGN_CENTER)
                {
                    crossOffset += (availCross - crossSize) * 0.5;
                }
                else if (alignItems == ALIGN_END)
                {
                    crossOffset += (availCross - crossSize);
                }

                var frame:Rect2D;
                if (isRow)
                {
                    frame = new Rect2D(currentMain, crossOffset, mSize, crossSize);
                }
                else
                {
                    frame = new Rect2D(crossOffset, currentMain, crossSize, mSize);
                }
                results.push(frame);

                currentMain += mSize + spaceBetweenStep;
            }

            return results;
        }
    }
}
