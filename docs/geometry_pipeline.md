# Computational Geometry Pipeline

The `stencil.geom` package contains pure mathematical routines designed for precision, numerical stability, and high execution speed in vector processing.

## 1. Parametric Bezier Calculus

### Cubic Formulation
A cubic Bezier curve defined by control points $P_0, P_1, P_2, P_3$ is parameterized over $t \in [0, 1]$:

$$B(t) = (1-t)^3 P_0 + 3(1-t)^2 t P_1 + 3(1-t) t^2 P_2 + t^3 P_3$$

### First & Second Derivatives
Velocity and acceleration vectors are derived analytically:

$$B'(t) = 3(1-t)^2 (P_1 - P_0) + 6(1-t)t (P_2 - P_1) + 3t^2 (P_3 - P_2)$$

$$B''(t) = 6(1-t) (P_2 - 2P_1 + P_0) + 6t (P_3 - 2P_2 + P_1)$$

### Signed Curvature
Curvature $\kappa(t)$ measures the rate of tangent turning:

$$\kappa(t) = \frac{x'(t) y''(t) - y'(t) x''(t)}{\left(x'(t)^2 + y'(t)^2\right)^{3/2}}$$

Curvature comb visualization evaluates this formula across uniform parameter intervals to inspect fairness and inflection points ($\kappa(t) = 0$).

### Arc Length via Gauss-Legendre Quadrature
Because the arc length integral $L = \int_0^1 \|B'(t)\| dt$ has no elementary closed form for general cubic curves, Stencil evaluates it using a 5-point Gauss-Legendre quadrature:

$$L \approx \frac{1}{2} \sum_{i=1}^5 w_i \left\| B'\left(\frac{1}{2}\xi_i + \frac{1}{2}\right) \right\|$$

The predefined weights $w_i$ and nodes $\xi_i$ yield precision exceeding $10^{-6}$ for typical spline segments.

### Tight Axis-Aligned Bounding Box (AABB)
The naive bounding box of the control polygon $P_0..P_3$ overestimates the true curve bounds. Stencil solves for the exact extrema by finding parameter values $t$ where $x'(t) = 0$ or $y'(t) = 0$:

$$a_x = 3(-x_0 + 3x_1 - 3x_2 + x_3)$$
$$b_x = 6(x_0 - 2x_1 + x_2)$$
$$c_x = 3(-x_0 + x_1)$$

Roots are found via the quadratic formula $t = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$. Real roots strictly within $(0, 1)$ are evaluated to establish tight bounds $[x_{\min}, y_{\min}, x_{\max}, y_{\max}]$.

---

## 2. Polygon Processing & Clipping

### Shoelace Formula & Orientation
For a polygon with vertices $(x_0, y_0), \dots, (x_{n-1}, y_{n-1})$:

$$A = \frac{1}{2} \sum_{i=0}^{n-1} (x_i y_{i+1} - x_{i+1} y_i)$$

The signed area determines winding order: positive area indicates counter-clockwise (CCW) winding, while negative area indicates clockwise (CW) winding.

### Andrew's Monotone Chain Convex Hull
Given an arbitrary set of 2D points, Stencil computes the minimum enclosing convex polygon in $O(N \log N)$ time:
1. Sort points lexicographically by $x$ (then $y$).
2. Construct the lower hull by adding points and popping non-left turns (cross product $\le 0$).
3. Construct the upper hull in reverse order.
4. Concatenate lower and upper hulls omitting duplicate endpoints.

### Greiner-Hormann Boolean Operations
Stencil implements arbitrary polygon clipping (Intersection, Union, Difference, XOR):
1. **Intersection Phase**: Find all intersections between edges of subject polygon $S$ and clip polygon $C$. Collinear edge segments are perturbed by $10^{-7}$ to avoid degenerate edge-crossing singularities.
2. **Double Linked List Insertion**: Intersections are inserted into both polygons as linked nodes, sorted by distance along each edge.
3. **Entry/Exit Marking**: Starting from a known inside/outside point, alternating traversal flags marks whether an intersection enters or exits the partner polygon.
4. **Contour Extraction**: Traversal weaves between $S$ and $C$ at intersection vertices according to the specified boolean operator.

---

## 3. Delaunay Triangulation & Voronoi Dual

### Bowyer-Watson Incremental Algorithm
1. Initialize an enclosing super-triangle containing all input points.
2. For each point $P$:
   - Identify all triangles whose circumcircle contains $P$ using the exact determinant test:
     
     $$\Delta = \begin{vmatrix} A_x - P_x & A_y - P_y & (A_x - P_x)^2 + (A_y - P_y)^2 \\ B_x - P_x & B_y - P_y & (B_x - P_x)^2 + (B_y - P_y)^2 \\ C_x - P_x & C_y - P_y & (C_x - P_x)^2 + (C_y - P_y)^2 \end{vmatrix} > 0$$
     
   - Remove bad triangles to create a polygonal star-shaped cavity.
   - Retriangulate the cavity by connecting each cavity edge to $P$.
3. Discard all triangles sharing vertices with the initial super-triangle.

### Voronoi Graph Extraction
The Voronoi diagram is extracted as the geometric dual of the Delaunay triangulation:
- Triangle circumcenters become Voronoi vertices.
- Adjacent triangles sharing a Delaunay edge connect their circumcenters to form a Voronoi edge.

---

## 4. 2D Bounding Volume Hierarchy (SpatialBVH)

To maintain 60 FPS viewport rendering over scenes with tens of thousands of vector shapes, `SpatialBVH` organizes AABBs in a binary tree:
- **Build Strategy**: Recursive top-down spatial median split. At each level, elements are sorted along the longest axis of their combined bounds and partitioned into equal halves.
- **Surface Area Heuristic (SAH)**: Leaf nodes store up to 4 elements.
- **Frustum Culling**: Viewport queries test the camera AABB against node bounding boxes, pruning disjoint subtrees and achieving $O(\log N)$ query time.
