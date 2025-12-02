package stencil.format
{
    import stencil.geom.PathData;
    import stencil.scene.ClipNode;
    import stencil.scene.GroupNode;
    import stencil.scene.ImageNode;
    import stencil.scene.PathNode;
    import stencil.scene.SceneGraph;
    import stencil.scene.SceneNode;
    import stencil.scene.ShapeNode;
    import stencil.scene.TextNode;

    /**
     * Lossless JSON schema serializer and deserializer for Stencil document graphs.
     */
    public class JSONFormat
    {
        public static const SCHEMA_VERSION:String = "1.0.0";

        /**
         * Serializes a SceneGraph to a structured JSON data dictionary.
         */
        public static function exportDocument(scene:SceneGraph):Object
        {
            if (scene == null) return null;

            return {
                schemaVersion: SCHEMA_VERSION,
                timestamp: new Date().time,
                viewportWidth: scene.viewportWidth,
                viewportHeight: scene.viewportHeight,
                backgroundColor: scene.backgroundColor,
                root: scene.toJSON()
            };
        }

        /**
         * Deserializes a SceneGraph from a structured data dictionary.
         */
        public static function importDocument(data:Object):SceneGraph
        {
            if (data == null) return new SceneGraph();

            var w:Number = (data.viewportWidth != null) ? Number(data.viewportWidth) : 1920.0;
            var h:Number = (data.viewportHeight != null) ? Number(data.viewportHeight) : 1080.0;

            var scene:SceneGraph = new SceneGraph("Root", w, h);
            if (data.backgroundColor != null)
            {
                scene.backgroundColor = uint(data.backgroundColor);
            }

            if (data.root != null)
            {
                scene.fromJSON(data.root);
                if (data.root.children is Array)
                {
                    instantiateChildrenRecursive(scene, data.root.children as Array);
                }
            }

            scene.rebuildSpatialIndex();
            return scene;
        }

        private static function instantiateChildrenRecursive(parent:SceneNode, childDataList:Array):void
        {
            for (var i:int = 0; i < childDataList.length; i++)
            {
                var cData:Object = childDataList[i];
                var typeStr:String = (cData.type != null) ? String(cData.type) : "SceneNode";
                var childNode:SceneNode;

                switch (typeStr)
                {
                    case "ShapeNode":
                        childNode = new ShapeNode();
                        break;
                    case "PathNode":
                        childNode = new PathNode();
                        break;
                    case "TextNode":
                        childNode = new TextNode();
                        break;
                    case "ImageNode":
                        childNode = new ImageNode();
                        break;
                    case "GroupNode":
                        childNode = new GroupNode();
                        break;
                    case "ClipNode":
                        childNode = new ClipNode();
                        break;
                    default:
                        childNode = new SceneNode();
                        break;
                }

                childNode.fromJSON(cData);
                parent.addChild(childNode);

                if (cData.children is Array && (cData.children as Array).length > 0)
                {
                    instantiateChildrenRecursive(childNode, cData.children as Array);
                }
            }
        }
    }
}
