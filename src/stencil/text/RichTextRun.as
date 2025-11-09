package stencil.text
{
    /**
     * RichTextRun defines an attributed span of characters within a rich document text model.
     */
    public class RichTextRun
    {
        public var text:String;
        public var fontFamily:String;
        public var fontSize:Number;
        public var fontWeight:String;
        public var fontStyle:String;
        public var color:uint;
        public var letterSpacing:Number;
        public var lineHeight:Number;

        public function RichTextRun(
            text:String = "",
            fontFamily:String = "Inter",
            fontSize:Number = 16.0,
            color:uint = 0xFF000000
        )
        {
            this.text = text;
            this.fontFamily = fontFamily;
            this.fontSize = fontSize;
            this.fontWeight = "normal";
            this.fontStyle = "normal";
            this.color = color;
            this.letterSpacing = 0.0;
            this.lineHeight = 1.4;
        }

        public function clone():RichTextRun
        {
            var r:RichTextRun = new RichTextRun(text, fontFamily, fontSize, color);
            r.fontWeight = fontWeight;
            r.fontStyle = fontStyle;
            r.letterSpacing = letterSpacing;
            r.lineHeight = lineHeight;
            return r;
        }
    }
}
