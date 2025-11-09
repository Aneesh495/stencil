package stencil.style
{
    import stencil.core.ICloneable;
    import stencil.core.ISerializable;
    import stencil.core.MathUtil;

    /**
     * Color provides 32-bit packed ARGB color operations with color space conversions (RGB, HSL, HSV),
     * gamma expansion, linear interpolation, and WCAG 2.1 relative luminance and contrast ratio calculations.
     */
    public class Color implements ICloneable, ISerializable
    {
        public var value:uint; // 0xAARRGGBB

        public function Color(value:uint = 0xFF000000)
        {
            this.value = value;
        }

        public static function fromARGB(a:uint, r:uint, g:uint, b:uint):Color
        {
            var packed:uint = (((a & 0xFF) << 24) >>> 0) |
                              ((r & 0xFF) << 16) |
                              ((g & 0xFF) << 8) |
                              (b & 0xFF);
            return new Color(packed);
        }

        public static function fromRGBA(r:uint, g:uint, b:uint, a:Number = 1.0):Color
        {
            var aByte:uint = Math.round(MathUtil.clamp(a, 0.0, 1.0) * 255);
            return fromARGB(aByte, r, g, b);
        }

        public static function fromFloats(r:Number, g:Number, b:Number, a:Number = 1.0):Color
        {
            return fromARGB(
                Math.round(MathUtil.clamp(a, 0.0, 1.0) * 255),
                Math.round(MathUtil.clamp(r, 0.0, 1.0) * 255),
                Math.round(MathUtil.clamp(g, 0.0, 1.0) * 255),
                Math.round(MathUtil.clamp(b, 0.0, 1.0) * 255)
            );
        }

        public static function fromHex(hexStr:String):Color
        {
            if (hexStr == null || hexStr.length == 0) return new Color(0xFF000000);
            if (hexStr.charAt(0) == "#") hexStr = hexStr.substr(1);

            if (hexStr.length == 3)
            {
                var r3:uint = parseInt(hexStr.charAt(0) + hexStr.charAt(0), 16);
                var g3:uint = parseInt(hexStr.charAt(1) + hexStr.charAt(1), 16);
                var b3:uint = parseInt(hexStr.charAt(2) + hexStr.charAt(2), 16);
                return fromARGB(255, r3, g3, b3);
            }
            else if (hexStr.length == 6)
            {
                var r6:uint = parseInt(hexStr.substr(0, 2), 16);
                var g6:uint = parseInt(hexStr.substr(2, 2), 16);
                var b6:uint = parseInt(hexStr.substr(4, 2), 16);
                return fromARGB(255, r6, g6, b6);
            }
            else if (hexStr.length == 8)
            {
                var a8:uint = parseInt(hexStr.substr(0, 2), 16);
                var r8:uint = parseInt(hexStr.substr(2, 2), 16);
                var g8:uint = parseInt(hexStr.substr(4, 2), 16);
                var b8:uint = parseInt(hexStr.substr(6, 2), 16);
                return fromARGB(a8, r8, g8, b8);
            }
            return new Color(0xFF000000);
        }

        public function get alpha():Number { return ((value >>> 24) & 0xFF) / 255.0; }
        public function get red():Number { return ((value >>> 16) & 0xFF) / 255.0; }
        public function get green():Number { return ((value >>> 8) & 0xFF) / 255.0; }
        public function get blue():Number { return (value & 0xFF) / 255.0; }

        public function get a():uint { return (value >>> 24) & 0xFF; }
        public function get r():uint { return (value >>> 16) & 0xFF; }
        public function get g():uint { return (value >>> 8) & 0xFF; }
        public function get b():uint { return value & 0xFF; }

        public static function fromHSL(h:Number, s:Number, l:Number, a:Number = 1.0):Color
        {
            var r:Number, g:Number, b:Number;
            if (s == 0)
            {
                r = g = b = l;
            }
            else
            {
                var q:Number = l < 0.5 ? l * (1.0 + s) : l + s - l * s;
                var p:Number = 2.0 * l - q;
                r = hueToRGB(p, q, h + 1.0/3.0);
                g = hueToRGB(p, q, h);
                b = hueToRGB(p, q, h - 1.0/3.0);
            }
            return fromFloats(r, g, b, a);
        }

        private static function hueToRGB(p:Number, q:Number, t:Number):Number
        {
            if (t < 0) t += 1.0;
            if (t > 1) t -= 1.0;
            if (t < 1.0/6.0) return p + (q - p) * 6.0 * t;
            if (t < 1.0/2.0) return q;
            if (t < 2.0/3.0) return p + (q - p) * (2.0/3.0 - t) * 6.0;
            return p;
        }

        /**
         * Computes WCAG 2.1 relative luminance for sRGB color space:
         * L = 0.2126 * R_lin + 0.7152 * G_lin + 0.0722 * B_lin
         */
        public function relativeLuminance():Number
        {
            var rLin:Number = linearize(red);
            var gLin:Number = linearize(green);
            var bLin:Number = linearize(blue);
            return 0.2126 * rLin + 0.7152 * gLin + 0.0722 * bLin;
        }

        private static function linearize(val:Number):Number
        {
            if (val <= 0.04045)
            {
                return val / 12.92;
            }
            return Math.pow((val + 0.055) / 1.055, 2.4);
        }

        /**
         * Calculates WCAG contrast ratio between this color and another color.
         * Ratio = (L1 + 0.05) / (L2 + 0.05), range [1.0, 21.0].
         */
        public function contrastRatio(other:Color):Number
        {
            var l1:Number = this.relativeLuminance();
            var l2:Number = other.relativeLuminance();
            var brighter:Number = Math.max(l1, l2);
            var darker:Number = Math.min(l1, l2);
            return (brighter + 0.05) / (darker + 0.05);
        }

        public function lerp(other:Color, t:Number):Color
        {
            var aNew:Number = MathUtil.lerp(alpha, other.alpha, t);
            var rNew:Number = MathUtil.lerp(red, other.red, t);
            var gNew:Number = MathUtil.lerp(green, other.green, t);
            var bNew:Number = MathUtil.lerp(blue, other.blue, t);
            return fromFloats(rNew, gNew, bNew, aNew);
        }

        public function toHexString(includeAlpha:Boolean = false):String
        {
            var hex:String = "";
            if (includeAlpha)
            {
                var aHex:String = a.toString(16);
                if (aHex.length < 2) aHex = "0" + aHex;
                hex += aHex;
            }
            var rHex:String = r.toString(16);
            if (rHex.length < 2) rHex = "0" + rHex;
            var gHex:String = g.toString(16);
            if (gHex.length < 2) gHex = "0" + gHex;
            var bHex:String = b.toString(16);
            if (bHex.length < 2) bHex = "0" + bHex;
            return "#" + hex + rHex + gHex + bHex;
        }

        public function clone():Object
        {
            return new Color(value);
        }

        public function toJSON():Object
        {
            return { value: value, hex: toHexString(true) };
        }

        public function fromJSON(data:Object):void
        {
            if (data != null && data.value != null)
            {
                value = uint(data.value);
            }
        }

        public function toString():String
        {
            return "Color(" + toHexString(true) + ")";
        }
    }
}
