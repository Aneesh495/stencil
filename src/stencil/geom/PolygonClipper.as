package stencil.geom
{
    import stencil.core.MathUtil;

    /**
     * Greiner-Hormann 2D polygon boolean clipping engine.
     * Computes intersection, union, difference, and symmetric difference (XOR) of arbitrary polygons.
     */
    public class PolygonClipper
    {
        public static const OP_INTERSECTION:int = 1;
        public static const OP_UNION:int = 2;
        public static const OP_DIFFERENCE:int = 3;
        public static const OP_XOR:int = 4;

        /**
         * Computes intersection of subject and clip polygons: Subject AND Clip.
         */
        public static function intersect(subject:Polygon2D, clip:Polygon2D):Array
        {
            return clipOperation(subject, clip, OP_INTERSECTION);
        }

        /**
         * Computes union of subject and clip polygons: Subject OR Clip.
         */
        public static function union(subject:Polygon2D, clip:Polygon2D):Array
        {
            return clipOperation(subject, clip, OP_UNION);
        }

        /**
         * Computes difference of subject and clip polygons: Subject SUB Clip.
         */
        public static function difference(subject:Polygon2D, clip:Polygon2D):Array
        {
            return clipOperation(subject, clip, OP_DIFFERENCE);
        }

        /**
         * Computes symmetric difference of subject and clip polygons: Subject XOR Clip.
         */
        public static function xor(subject:Polygon2D, clip:Polygon2D):Array
        {
            var diff1:Array = difference(subject, clip);
            var diff2:Array = difference(clip, subject);
            return diff1.concat(diff2);
        }

        private static function clipOperation(subj:Polygon2D, clip:Polygon2D, op:int):Array
        {
            if (subj == null || subj.vertexCount < 3) return [];
            if (clip == null || clip.vertexCount < 3)
            {
                if (op == OP_UNION || op == OP_DIFFERENCE) return [subj.clone() as Polygon2D];
                return [];
            }

            // Quick AABB disjoint test
            var subjBounds:Rect2D = subj.bounds();
            var clipBounds:Rect2D = clip.bounds();

            if (!subjBounds.intersects(clipBounds))
            {
                if (op == OP_UNION)
                {
                    return [subj.clone() as Polygon2D, clip.clone() as Polygon2D];
                }
                else if (op == OP_DIFFERENCE)
                {
                    return [subj.clone() as Polygon2D];
                }
                else
                {
                    return [];
                }
            }

            // Build circular linked lists for subject and clip
            var subjList:Array = buildNodeList(subj);
            var clipList:Array = buildNodeList(clip);

            // Find all edge-edge intersections
            var hasIntersections:Boolean = findIntersections(subjList, clipList);

            if (!hasIntersections)
            {
                // One polygon may be fully contained in the other
                var subjInClip:Boolean = clip.containsPoint(subj.vertices[0] as Point2D);
                var clipInSubj:Boolean = subj.containsPoint(clip.vertices[0] as Point2D);

                if (subjInClip)
                {
                    if (op == OP_INTERSECTION) return [subj.clone() as Polygon2D];
                    if (op == OP_UNION) return [clip.clone() as Polygon2D];
                    if (op == OP_DIFFERENCE) return [];
                }
                else if (clipInSubj)
                {
                    if (op == OP_INTERSECTION) return [clip.clone() as Polygon2D];
                    if (op == OP_UNION) return [subj.clone() as Polygon2D];
                    if (op == OP_DIFFERENCE)
                    {
                        // Outer polygon with hole
                        return [subj.clone() as Polygon2D];
                    }
                }
                else
                {
                    // Disjoint
                    if (op == OP_UNION) return [subj.clone() as Polygon2D, clip.clone() as Polygon2D];
                    if (op == OP_DIFFERENCE) return [subj.clone() as Polygon2D];
                    return [];
                }
            }

            // Mark entry and exit flags
            markEntryExit(subjList, clip);
            markEntryExit(clipList, subj);

            // Traverse and build result polygons
            return extractResultPolygons(subjList, op);
        }

        private static function buildNodeList(poly:Polygon2D):Array
        {
            var list:Array = [];
            var n:int = poly.vertexCount;
            for (var i:int = 0; i < n; i++)
            {
                var pt:Point2D = poly.vertices[i] as Point2D;
                list.push({
                    pt: pt.clone() as Point2D,
                    next: null,
                    prev: null,
                    intersect: false,
                    entry: false,
                    visited: false,
                    alpha: 0.0,
                    neighbor: null
                });
            }

            for (var j:int = 0; j < n; j++)
            {
                list[j].next = list[(j + 1) % n];
                list[j].prev = list[(j - 1 + n) % n];
            }

            return list;
        }

        private static function findIntersections(subjList:Array, clipList:Array):Boolean
        {
            var foundAny:Boolean = false;
            var sCurrent:Object = subjList[0];
            var sStart:Object = sCurrent;

            do {
                if (!sCurrent.intersect)
                {
                    var cCurrent:Object = clipList[0];
                    var cStart:Object = cCurrent;

                    do {
                        if (!cCurrent.intersect)
                        {
                            var inter:Object = lineSegmentIntersection(
                                sCurrent.pt, sCurrent.next.pt,
                                cCurrent.pt, cCurrent.next.pt
                            );

                            if (inter != null && inter.valid)
                            {
                                foundAny = true;
                                insertIntersection(sCurrent, cCurrent, inter.pt, inter.alphaS, inter.alphaC);
                            }
                        }
                        cCurrent = cCurrent.next;
                    } while (cCurrent !== cStart);
                }
                sCurrent = sCurrent.next;
            } while (sCurrent !== sStart);

            return foundAny;
        }

        private static function insertIntersection(
            sNode:Object,
            cNode:Object,
            pt:Point2D,
            alphaS:Number,
            alphaC:Number
        ):void
        {
            var isNode:Object = {
                pt: pt,
                next: null,
                prev: null,
                intersect: true,
                entry: false,
                visited: false,
                alpha: alphaS,
                neighbor: null
            };

            var icNode:Object = {
                pt: pt.clone() as Point2D,
                next: null,
                prev: null,
                intersect: true,
                entry: false,
                visited: false,
                alpha: alphaC,
                neighbor: isNode
            };
            isNode.neighbor = icNode;

            // Insert into subject list sorted by alpha
            insertSorted(sNode, isNode);
            // Insert into clip list sorted by alpha
            insertSorted(cNode, icNode);
        }

        private static function insertSorted(baseNode:Object, newNode:Object):void
        {
            var curr:Object = baseNode;
            while (curr.next.intersect && curr.next.alpha < newNode.alpha)
            {
                curr = curr.next;
            }
            newNode.next = curr.next;
            newNode.prev = curr;
            curr.next.prev = newNode;
            curr.next = newNode;
        }

        private static function markEntryExit(list:Array, otherPoly:Polygon2D):void
        {
            var curr:Object = list[0];
            var start:Object = curr;
            var inside:Boolean = otherPoly.containsPoint(curr.pt);

            do {
                if (curr.intersect)
                {
                    curr.entry = !inside;
                    inside = !inside;
                }
                curr = curr.next;
            } while (curr !== start);
        }

        private static function extractResultPolygons(subjList:Array, op:int):Array
        {
            var results:Array = [];
            var curr:Object = subjList[0];
            var start:Object = curr;

            do {
                if (curr.intersect && !curr.visited)
                {
                    var poly:Polygon2D = new Polygon2D();
                    var pCurr:Object = curr;

                    do {
                        pCurr.visited = true;
                        poly.addVertex(pCurr.pt.clone() as Point2D);

                        if (op == OP_INTERSECTION)
                        {
                            if (pCurr.entry)
                            {
                                pCurr = pCurr.next;
                            }
                            else
                            {
                                pCurr = pCurr.neighbor ? pCurr.neighbor.next : pCurr.next;
                            }
                        }
                        else if (op == OP_UNION)
                        {
                            if (!pCurr.entry)
                            {
                                pCurr = pCurr.next;
                            }
                            else
                            {
                                pCurr = pCurr.neighbor ? pCurr.neighbor.next : pCurr.next;
                            }
                        }
                        else // OP_DIFFERENCE
                        {
                            if (!pCurr.entry)
                            {
                                pCurr = pCurr.next;
                            }
                            else
                            {
                                pCurr = pCurr.neighbor ? pCurr.neighbor.prev : pCurr.prev;
                            }
                        }
                    } while (pCurr != null && pCurr !== curr && !pCurr.visited && poly.vertexCount < 1000);

                    if (poly.vertexCount >= 3)
                    {
                        results.push(poly);
                    }
                }
                curr = curr.next;
            } while (curr !== start);

            return results;
        }

        private static function lineSegmentIntersection(
            p1:Point2D, p2:Point2D,
            p3:Point2D, p4:Point2D
        ):Object
        {
            var d:Number = (p4.y - p3.y) * (p2.x - p1.x) - (p4.x - p3.x) * (p2.y - p1.y);
            if (MathUtil.fuzzyZero(d))
            {
                return null; // Parallel or collinear
            }

            var ua:Number = ((p4.x - p3.x) * (p1.y - p3.y) - (p4.y - p3.y) * (p1.x - p3.x)) / d;
            var ub:Number = ((p2.x - p1.x) * (p1.y - p3.y) - (p2.y - p1.y) * (p1.x - p3.x)) / d;

            if (ua > 0.0001 && ua < 0.9999 && ub > 0.0001 && ub < 0.9999)
            {
                var ix:Number = p1.x + ua * (p2.x - p1.x);
                var iy:Number = p1.y + ua * (p2.y - p1.y);
                return {
                    valid: true,
                    pt: new Point2D(ix, iy),
                    alphaS: ua,
                    alphaC: ub
                };
            }

            return null;
        }
    }
}
