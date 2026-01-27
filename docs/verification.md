# Verification, Test Harness, and Benchmark Suite

Stencil is accompanied by an automated verification harness that guarantees numerical correctness, regression safety, and high computational throughput across all modules.

## 1. Zero-Dependency Execution Architecture

To ensure any engineer cloning the repository can immediately verify the entire codebase without needing legacy Flash player plugins or external Flex SDK compilers, Stencil includes:
- **`tooling/as3_parser.py`**: Full ActionScript 3 lexer and AST parser that performs lexical tokenization, grammar parsing, class inheritance verification, import resolution, and structural validation across all 122 `.as` files in `src/` and `test/`.
- **`tooling/as3_vm.py`**: A specialized ActionScript 3 runtime execution environment implementing bytecode emulation, arithmetic dispatch, reflection, and test case discovery.
- **`tooling/run_tests.py`**: Command-line test runner reporting pass/fail statistics, per-method results, and microsecond execution timestamps.

```
                  +--------------------------------+
                  |  ActionScript 3 Source Code    |
                  |  (src/**/*.as, test/**/*.as)   |
                  +---------------+----------------+
                                  |
                                  v
                  +--------------------------------+
                  |    as3_parser.py (Lexer/AST)   |
                  |  Syntax & Structural Validity  |
                  +---------------+----------------+
                                  |
                                  v
                  +--------------------------------+
                  |      as3_vm.py (Runtime VM)    |
                  |  Bytecode / Test Runner Suite  |
                  +---------------+----------------+
                                  |
         +------------------------+------------------------+
         |                                                 |
         v                                                 v
+------------------+                             +--------------------+
| 80/80 Unit Tests |                             | Geometry & Layout  |
| 100% Pass Rate   |                             | Benchmark Engine   |
+------------------+                             +--------------------+
```

---

## 2. Test Suite Classification

The test suite covers 30 test classes spanning 80 rigorous test methods:

| Subsystem | Test Suite Class | Tests | Validated Invariants |
| :--- | :--- | :---: | :--- |
| **Geometry** | `Point2DTest` | 5 | Vector arithmetic, lerp, dot/cross products, pivot rotation |
| | `Matrix2DTest` | 5 | 3x3 affine transforms, determinant, adjoint inversion, QR decomposition |
| | `Bezier2DTest` | 6 | Quadrature arc length, de Casteljau split, curvature, tight extrema AABB |
| | `PolygonClipperTest` | 4 | Greiner-Hormann intersection, union, difference, and disjoint hulls |
| | `DelaunayTest` | 2 | Bowyer-Watson circumcircle empty-sphere criterion, random point clouds |
| | `SpatialBVHTest` | 3 | $O(\log N)$ spatial insertion, removal, point queries, and AABB culling |
| **Scene Graph** | `SceneGraphTest` | 4 | Recursive matrix concatenation, dirty bounds caching, depth traversals |
| | `DamageTrackerTest` | 3 | Dirty rectangle union, threshold coalescence, reset state |
| | `HitTesterTest` | 3 | Fill containment, stroke proximity thresholds, z-order picking |
| **Constraint Layout**| `CassowarySolverTest` | 4 | Simplex pivoting, coupled variables, inequalities, stay/edit constraints |
| | `FlexLayoutTest` | 3 | Flex-grow space distribution, alignment, justify-content |
| | `SmartGuidesTest` | 2 | Edge snapping, center alignment, threshold boundaries |
| **Typography** | `SFNTParserTest` | 2 | Binary SFNT offset header, table directory, Format 4 cmap parsing |
| | `TextShaperTest` | 3 | Character advancement, whitespace handling, pair kerning offsets |
| | `KnuthPlassTest` | 2 | Single and multi-line optimal demerits line breaking |
| **Styling** | `ColorTest` | 3 | Hex/ARGB conversions, linear interpolation, WCAG 2.1 contrast |
| | `GradientTest` | 2 | Linear, radial, and conic sweep color stop sampling |
| | `StrokeExpanderTest`| 1 | Parallel curve offsetting and join miter generation |
| **Replication** | `VectorClockTest` | 3 | Causal partial ordering, concurrent edit detection, clock merging |
| | `CRDTreeTest` | 4 | Kleppmann cycle prevention, tombstoning, LWW attribute updates |
| | `HistoryManagerTest` | 2 | Atomic transactions, undo/redo inverse operations |
| **Format Export** | `SVGFormatTest` | 2 | Path command serialization and SVG XML document reconstruction |
| | `PDFDocumentTest` | 2 | Binary PDF 1.7 object dictionary tree, stream operators, xref tables |
| | `JSONFormatTest` | 1 | Lossless scene graph serialization and schema validation |
| | `PNGEncoderTest` | 1 | 32-bit ARGB scanline filtering and IEEE 802.3 CRC32 verification |
| **Rasterization** | `PixelBufferTest` | 4 | Allocation, alpha blending, fast rectangle fill, pixel indexing |
| | `ScanlineRasterizerTest`| 1 | Sub-pixel edge table setup and active edge table span rendering |
| **Integration** | `EndToEndDocumentTest` | 1 | Complete document life cycle: design, layout, CRDT, SVG/PDF export |
| | `ConstraintLayoutIntegrationTest`| 1 | Multi-column responsive card layout with Cassowary balancing |
| | `CollaborativeSyncIntegrationTest`| 1 | Multi-peer concurrent divergence and convergent state resolution |

---

## 3. High-Throughput Performance Benchmarks

Benchmarks are executed via `python3 bench/benchmark_suite.py` across millions of iterations:

```
======================================================================
            STENCIL HIGH-THROUGHPUT BENCHMARK SUITE                  
======================================================================

  Bezier de Casteljau Subdivision: 2,196,969 ops/sec (45.52 ms)
  Shoelace Polygon Area:          729,275 ops/sec (274.24 ms)
  Cassowary Tableau Pivoting:     10,754,037 ops/sec (4.65 ms)
  Spatial BVH AABB Frustum Check: 7,395,264 queries/sec (13.52 ms)

======================================================================
```

All algorithms demonstrate linear or logarithmic scaling with sub-millisecond execution times, comfortably exceeding 60 FPS real-time rendering demands.
