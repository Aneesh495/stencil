/**
 * Stencil Studio - Interactive 2D Vector & Computational Geometry Workbench
 * Implements interactive canvas visualization of Bezier calculus, Cassowary solver,
 * Greiner-Hormann polygon clipping, Delaunay/Voronoi, and CRDT replication.
 */

(function () {
  "use strict";

  // State
  const state = {
    mode: "bezier",
    pan: { x: 0, y: 0 },
    zoom: 1.0,
    isPanning: false,
    panStart: { x: 0, y: 0 },
    draggedItem: null,
    fps: 60,
    lastFrameTime: performance.now(),

    // Bezier Mode State
    bezier: {
      p0: { x: 180, y: 480 },
      p1: { x: 260, y: 160 },
      p2: { x: 620, y: 120 },
      p3: { x: 740, y: 520 },
      subdivDepth: 4,
      showCurvature: true,
      showBounds: true,
      showHull: true
    },

    // Cassowary Mode State
    cassowary: {
      containerWidth: 600,
      containerHeight: 280,
      splitRatio: 0.5,
      padding: 24,
      gap: 16
    },

    // Polygon Clipper State
    clipper: {
      op: "intersection",
      polyA: [
        { x: 300, y: 220 },
        { x: 550, y: 200 },
        { x: 600, y: 420 },
        { x: 340, y: 460 }
      ],
      polyB: [
        { x: 420, y: 280 },
        { x: 680, y: 260 },
        { x: 650, y: 520 },
        { x: 400, y: 480 }
      ]
    },

    // Delaunay & Voronoi State
    delaunay: {
      points: [
        { x: 240, y: 220 },
        { x: 480, y: 160 },
        { x: 680, y: 240 },
        { x: 340, y: 420 },
        { x: 560, y: 380 },
        { x: 720, y: 490 },
        { x: 220, y: 540 },
        { x: 460, y: 560 }
      ],
      showTriangles: true,
      showVoronoi: true,
      showCircumcircles: false
    },

    // CRDT Multi-Peer State
    crdt: {
      clockA: [1, 0],
      clockB: [0, 1],
      peerA: {
        x: 320,
        y: 280,
        radius: 45,
        color: "#38bdf8",
        label: "Peer A: Shape"
      },
      peerB: {
        x: 580,
        y: 340,
        width: 110,
        height: 80,
        color: "#818cf8",
        label: "Peer B: Shape"
      },
      cursorA: { x: 360, y: 260 },
      cursorB: { x: 540, y: 320 },
      synced: true
    }
  };

  // DOM Elements
  const canvas = document.getElementById("stage-canvas");
  const ctx = canvas.getContext("2d");
  const tabBtns = document.querySelectorAll(".tab-btn");
  const controlGroups = {
    bezier: document.getElementById("controls-bezier"),
    cassowary: document.getElementById("controls-cassowary"),
    clipper: document.getElementById("controls-clipper"),
    delaunay: document.getElementById("controls-delaunay"),
    crdt: document.getElementById("controls-crdt")
  };

  const statusZoom = document.getElementById("status-zoom");
  const statusPan = document.getElementById("status-pan");
  const statusFps = document.getElementById("status-fps");

  // Resize canvas to fill container
  function resizeCanvas() {
    const rect = canvas.parentElement.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    ctx.scale(dpr, dpr);
    render();
  }

  window.addEventListener("resize", resizeCanvas);

  // Mode Switching
  tabBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      tabBtns.forEach(b => b.classList.remove("active"));
      btn.classList.add("active");
      const mode = btn.dataset.mode;
      state.mode = mode;

      Object.keys(controlGroups).forEach(k => {
        controlGroups[k].classList.toggle("hidden", k !== mode);
      });
      render();
    });
  });

  // Bezier Controls Wiring
  const inputSubdiv = document.getElementById("input-subdiv");
  const valSubdiv = document.getElementById("val-subdiv");
  const checkCurvature = document.getElementById("check-curvature");
  const checkBounds = document.getElementById("check-bounds");
  const checkHull = document.getElementById("check-hull");
  const metricArcLen = document.getElementById("metric-arc-len");
  const metricRoots = document.getElementById("metric-roots");
  const metricSegs = document.getElementById("metric-segs");

  inputSubdiv.addEventListener("input", (e) => {
    state.bezier.subdivDepth = parseInt(e.target.value, 10);
    valSubdiv.textContent = state.bezier.subdivDepth;
    metricSegs.textContent = Math.pow(2, state.bezier.subdivDepth);
    render();
  });

  checkCurvature.addEventListener("change", (e) => {
    state.bezier.showCurvature = e.target.checked;
    render();
  });

  checkBounds.addEventListener("change", (e) => {
    state.bezier.showBounds = e.target.checked;
    render();
  });

  checkHull.addEventListener("change", (e) => {
    state.bezier.showHull = e.target.checked;
    render();
  });

  // Cassowary Controls Wiring
  const inputCassWidth = document.getElementById("input-cass-width");
  const valCassWidth = document.getElementById("val-cass-width");
  const inputCassSplit = document.getElementById("input-cass-split");
  const valCassSplit = document.getElementById("val-cass-split");

  inputCassWidth.addEventListener("input", (e) => {
    state.cassowary.containerWidth = parseInt(e.target.value, 10);
    valCassWidth.textContent = state.cassowary.containerWidth;
    render();
  });

  inputCassSplit.addEventListener("input", (e) => {
    state.cassowary.splitRatio = parseInt(e.target.value, 10) / 100.0;
    valCassSplit.textContent = e.target.value;
    render();
  });

  // Clipper Controls Wiring
  document.querySelectorAll("input[name='clip-op']").forEach(radio => {
    radio.addEventListener("change", (e) => {
      state.clipper.op = e.target.value;
      render();
    });
  });

  document.getElementById("btn-clip-randomize").addEventListener("click", () => {
    const cx = canvas.width / (2 * (window.devicePixelRatio || 1));
    const cy = canvas.height / (2 * (window.devicePixelRatio || 1));
    state.clipper.polyA = [
      { x: cx - 180 + (Math.random() - 0.5) * 40, y: cy - 140 + (Math.random() - 0.5) * 40 },
      { x: cx + 80 + (Math.random() - 0.5) * 40, y: cy - 160 + (Math.random() - 0.5) * 40 },
      { x: cx + 120 + (Math.random() - 0.5) * 40, y: cy + 100 + (Math.random() - 0.5) * 40 },
      { x: cx - 140 + (Math.random() - 0.5) * 40, y: cy + 120 + (Math.random() - 0.5) * 40 }
    ];
    state.clipper.polyB = [
      { x: cx - 60 + (Math.random() - 0.5) * 40, y: cy - 80 + (Math.random() - 0.5) * 40 },
      { x: cx + 190 + (Math.random() - 0.5) * 40, y: cy - 60 + (Math.random() - 0.5) * 40 },
      { x: cx + 160 + (Math.random() - 0.5) * 40, y: cy + 180 + (Math.random() - 0.5) * 40 },
      { x: cx - 80 + (Math.random() - 0.5) * 40, y: cy + 150 + (Math.random() - 0.5) * 40 }
    ];
    render();
  });

  // Delaunay Controls Wiring
  document.getElementById("check-delaunay-tri").addEventListener("change", (e) => {
    state.delaunay.showTriangles = e.target.checked;
    render();
  });
  document.getElementById("check-voronoi-cells").addEventListener("change", (e) => {
    state.delaunay.showVoronoi = e.target.checked;
    render();
  });
  document.getElementById("check-circumcircles").addEventListener("change", (e) => {
    state.delaunay.showCircumcircles = e.target.checked;
    render();
  });

  document.getElementById("btn-delaunay-add").addEventListener("click", () => {
    const w = canvas.parentElement.clientWidth;
    const h = canvas.parentElement.clientHeight;
    for (let i = 0; i < 10; i++) {
      state.delaunay.points.push({
        x: 100 + Math.random() * (w - 200),
        y: 100 + Math.random() * (h - 200)
      });
    }
    render();
  });

  document.getElementById("btn-delaunay-clear").addEventListener("click", () => {
    state.delaunay.points = [
      { x: 240, y: 220 },
      { x: 480, y: 160 },
      { x: 680, y: 240 },
      { x: 340, y: 420 },
      { x: 560, y: 380 }
    ];
    render();
  });

  // CRDT Controls Wiring
  const metricClockA = document.getElementById("metric-clock-a");
  const metricClockB = document.getElementById("metric-clock-b");

  document.getElementById("btn-crdt-mutate-a").addEventListener("click", () => {
    state.crdt.clockA[0]++;
    state.crdt.peerA.x += (Math.random() - 0.5) * 60;
    state.crdt.peerA.y += (Math.random() - 0.5) * 60;
    state.crdt.cursorA.x = state.crdt.peerA.x + 30;
    state.crdt.cursorA.y = state.crdt.peerA.y - 20;
    metricClockA.textContent = `[${state.crdt.clockA[0]}, ${state.crdt.clockA[1]}]`;
    render();
  });

  document.getElementById("btn-crdt-mutate-b").addEventListener("click", () => {
    state.crdt.clockB[1]++;
    state.crdt.peerB.x += (Math.random() - 0.5) * 60;
    state.crdt.peerB.y += (Math.random() - 0.5) * 60;
    state.crdt.cursorB.x = state.crdt.peerB.x - 20;
    state.crdt.cursorB.y = state.crdt.peerB.y + 40;
    metricClockB.textContent = `[${state.crdt.clockB[0]}, ${state.crdt.clockB[1]}]`;
    render();
  });

  document.getElementById("btn-crdt-sync").addEventListener("click", () => {
    const max0 = Math.max(state.crdt.clockA[0], state.crdt.clockB[0]);
    const max1 = Math.max(state.crdt.clockA[1], state.crdt.clockB[1]);
    state.crdt.clockA = [max0, max1];
    state.crdt.clockB = [max0, max1];
    metricClockA.textContent = `[${max0}, ${max1}]`;
    metricClockB.textContent = `[${max0}, ${max1}]`;
    render();
  });

  // Action Buttons
  document.getElementById("btn-reset-view").addEventListener("click", () => {
    state.pan = { x: 0, y: 0 };
    state.zoom = 1.0;
    statusZoom.textContent = "100%";
    statusPan.textContent = "0, 0";
    render();
  });

  document.getElementById("btn-export-svg").addEventListener("click", () => {
    exportCurrentSVG();
  });

  // Canvas Interactions: Pan, Zoom, and Control Point Dragging
  let isSpaceDown = false;
  window.addEventListener("keydown", (e) => {
    if (e.code === "Space") isSpaceDown = true;
  });
  window.addEventListener("keyup", (e) => {
    if (e.code === "Space") isSpaceDown = false;
  });

  canvas.addEventListener("mousedown", (e) => {
    const rect = canvas.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    const mouseY = e.clientY - rect.top;
    const worldX = (mouseX - state.pan.x) / state.zoom;
    const worldY = (mouseY - state.pan.y) / state.zoom;

    if (e.button === 1 || isSpaceDown) {
      state.isPanning = true;
      state.panStart = { x: mouseX - state.pan.x, y: mouseY - state.pan.y };
      return;
    }

    if (e.button === 0) {
      const hit = findHitHandle(worldX, worldY);
      if (hit) {
        state.draggedItem = hit;
      }
    }
  });

  window.addEventListener("mousemove", (e) => {
    const rect = canvas.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    const mouseY = e.clientY - rect.top;

    if (state.isPanning) {
      state.pan.x = mouseX - state.panStart.x;
      state.pan.y = mouseY - state.panStart.y;
      statusPan.textContent = `${Math.round(state.pan.x)}, ${Math.round(state.pan.y)}`;
      render();
      return;
    }

    if (state.draggedItem) {
      const worldX = (mouseX - state.pan.x) / state.zoom;
      const worldY = (mouseY - state.pan.y) / state.zoom;
      state.draggedItem.target.x = worldX;
      state.draggedItem.target.y = worldY;
      render();
    }
  });

  window.addEventListener("mouseup", () => {
    state.isPanning = false;
    state.draggedItem = null;
  });

  canvas.addEventListener("wheel", (e) => {
    e.preventDefault();
    const zoomFactor = e.deltaY < 0 ? 1.1 : 0.9;
    const newZoom = Math.min(Math.max(state.zoom * zoomFactor, 0.2), 5.0);

    const rect = canvas.getBoundingClientRect();
    const mouseX = e.clientX - rect.left;
    const mouseY = e.clientY - rect.top;

    state.pan.x = mouseX - (mouseX - state.pan.x) * (newZoom / state.zoom);
    state.pan.y = mouseY - (mouseY - state.pan.y) * (newZoom / state.zoom);
    state.zoom = newZoom;

    statusZoom.textContent = `${Math.round(state.zoom * 100)}%`;
    statusPan.textContent = `${Math.round(state.pan.x)}, ${Math.round(state.pan.y)}`;
    render();
  }, { passive: false });

  function findHitHandle(wx, wy) {
    const radius = 12 / state.zoom;
    if (state.mode === "bezier") {
      const points = [
        { target: state.bezier.p0, name: "p0" },
        { target: state.bezier.p1, name: "p1" },
        { target: state.bezier.p2, name: "p2" },
        { target: state.bezier.p3, name: "p3" }
      ];
      for (const p of points) {
        const dx = wx - p.target.x;
        const dy = wy - p.target.y;
        if (dx * dx + dy * dy <= radius * radius) return p;
      }
    } else if (state.mode === "clipper") {
      const allPts = [
        ...state.clipper.polyA.map((pt, i) => ({ target: pt, name: `A${i}` })),
        ...state.clipper.polyB.map((pt, i) => ({ target: pt, name: `B${i}` }))
      ];
      for (const p of allPts) {
        const dx = wx - p.target.x;
        const dy = wy - p.target.y;
        if (dx * dx + dy * dy <= radius * radius) return p;
      }
    } else if (state.mode === "delaunay") {
      for (let i = 0; i < state.delaunay.points.length; i++) {
        const pt = state.delaunay.points[i];
        const dx = wx - pt.x;
        const dy = wy - pt.y;
        if (dx * dx + dy * dy <= radius * radius) return { target: pt, name: `D${i}` };
      }
    }
    return null;
  }

  // Computational Geometry Math Functions
  function evalCubicBezier(p0, p1, p2, p3, t) {
    const mt = 1.0 - t;
    const mt2 = mt * mt;
    const mt3 = mt2 * mt;
    const t2 = t * t;
    const t3 = t2 * t;
    return {
      x: mt3 * p0.x + 3 * mt2 * t * p1.x + 3 * mt * t2 * p2.x + t3 * p3.x,
      y: mt3 * p0.y + 3 * mt2 * t * p1.y + 3 * mt * t2 * p2.y + t3 * p3.y
    };
  }

  function evalCubicDerivative(p0, p1, p2, p3, t) {
    const mt = 1.0 - t;
    const d0x = 3 * (p1.x - p0.x);
    const d0y = 3 * (p1.y - p0.y);
    const d1x = 3 * (p2.x - p1.x);
    const d1y = 3 * (p2.y - p1.y);
    const d2x = 3 * (p3.x - p2.x);
    const d2y = 3 * (p3.y - p2.y);
    return {
      x: mt * mt * d0x + 2 * mt * t * d1x + t * t * d2x,
      y: mt * mt * d0y + 2 * mt * t * d1y + t * t * d2y
    };
  }

  function evalCubicSecondDerivative(p0, p1, p2, p3, t) {
    const mt = 1.0 - t;
    const dd0x = 6 * (p2.x - 2 * p1.x + p0.x);
    const dd0y = 6 * (p2.y - 2 * p1.y + p0.y);
    const dd1x = 6 * (p3.x - 2 * p2.x + p1.x);
    const dd1y = 6 * (p3.y - 2 * p2.y + p1.y);
    return {
      x: mt * dd0x + t * dd1x,
      y: mt * dd0y + t * dd1y
    };
  }

  // 5-Point Gauss-Legendre Quadrature for Arc Length
  function computeArcLength(p0, p1, p2, p3) {
    const weights = [0.236926885, 0.478628670, 0.568888889, 0.478628670, 0.236926885];
    const abscissae = [-0.906179846, -0.538469310, 0.0, 0.538469310, 0.906179846];
    let sum = 0.0;
    for (let i = 0; i < 5; i++) {
      const t = 0.5 * abscissae[i] + 0.5;
      const d = evalCubicDerivative(p0, p1, p2, p3, t);
      const speed = Math.sqrt(d.x * d.x + d.y * d.y);
      sum += weights[i] * speed;
    }
    return sum * 0.5;
  }

  // Extrema Calculation for Tight AABB
  function computeTightBounds(p0, p1, p2, p3) {
    const rootsX = solveQuadraticRoots(
      3 * (-p0.x + 3 * p1.x - 3 * p2.x + p3.x),
      6 * (p0.x - 2 * p1.x + p2.x),
      3 * (-p0.x + p1.x)
    );
    const rootsY = solveQuadraticRoots(
      3 * (-p0.y + 3 * p1.y - 3 * p2.y + p3.y),
      6 * (p0.y - 2 * p1.y + p2.y),
      3 * (-p0.y + p1.y)
    );

    let minX = Math.min(p0.x, p3.x);
    let maxX = Math.max(p0.x, p3.x);
    let minY = Math.min(p0.y, p3.y);
    let maxY = Math.max(p0.y, p3.y);

    for (const t of rootsX) {
      if (t > 0 && t < 1) {
        const pt = evalCubicBezier(p0, p1, p2, p3, t);
        minX = Math.min(minX, pt.x);
        maxX = Math.max(maxX, pt.x);
      }
    }
    for (const t of rootsY) {
      if (t > 0 && t < 1) {
        const pt = evalCubicBezier(p0, p1, p2, p3, t);
        minY = Math.min(minY, pt.y);
        maxY = Math.max(maxY, pt.y);
      }
    }

    return { minX, minY, maxX, maxY, rootCount: rootsX.length + rootsY.length };
  }

  function solveQuadraticRoots(a, b, c) {
    const res = [];
    if (Math.abs(a) < 1e-9) {
      if (Math.abs(b) > 1e-9) res.push(-c / b);
      return res;
    }
    const disc = b * b - 4 * a * c;
    if (disc < 0) return res;
    if (Math.abs(disc) < 1e-9) {
      res.push(-b / (2 * a));
      return res;
    }
    const sqrtDisc = Math.sqrt(disc);
    res.push((-b - sqrtDisc) / (2 * a));
    res.push((-b + sqrtDisc) / (2 * a));
    return res;
  }

  // Bowyer-Watson Delaunay Triangulation
  function bowyerWatson(points) {
    if (points.length < 3) return [];

    let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
    points.forEach(p => {
      minX = Math.min(minX, p.x);
      minY = Math.min(minY, p.y);
      maxX = Math.max(maxX, p.x);
      maxY = Math.max(maxY, p.y);
    });

    const dx = (maxX - minX) * 2;
    const dy = (maxY - minY) * 2;
    const midX = (minX + maxX) / 2;
    const midY = (minY + maxY) / 2;

    const stA = { x: midX - 2 * dx, y: midY - dy };
    const stB = { x: midX, y: midY + 2 * dy };
    const stC = { x: midX + 2 * dx, y: midY - dy };

    let triangles = [{ a: stA, b: stB, c: stC }];

    for (const pt of points) {
      const badTriangles = [];
      for (const tri of triangles) {
        const cc = getCircumcircle(tri.a, tri.b, tri.c);
        const distSq = (pt.x - cc.x) * (pt.x - cc.x) + (pt.y - cc.y) * (pt.y - cc.y);
        if (distSq <= cc.rSq) {
          badTriangles.push(tri);
        }
      }

      const polygonEdges = [];
      for (let i = 0; i < badTriangles.length; i++) {
        const t1 = badTriangles[i];
        const edges = [
          { a: t1.a, b: t1.b },
          { a: t1.b, b: t1.c },
          { a: t1.c, b: t1.a }
        ];

        for (const edge of edges) {
          let shared = false;
          for (let j = 0; j < badTriangles.length; j++) {
            if (i === j) continue;
            const t2 = badTriangles[j];
            if (hasEdge(t2, edge)) {
              shared = true;
              break;
            }
          }
          if (!shared) polygonEdges.push(edge);
        }
      }

      triangles = triangles.filter(t => !badTriangles.includes(t));
      for (const edge of polygonEdges) {
        triangles.push({ a: edge.a, b: edge.b, c: pt });
      }
    }

    // Remove triangles containing super-triangle vertices
    return triangles.filter(t => (
      t.a !== stA && t.a !== stB && t.a !== stC &&
      t.b !== stA && t.b !== stB && t.b !== stC &&
      t.c !== stA && t.c !== stB && t.c !== stC
    ));
  }

  function hasEdge(tri, edge) {
    const pts = [tri.a, tri.b, tri.c];
    return pts.includes(edge.a) && pts.includes(edge.b);
  }

  function getCircumcircle(a, b, c) {
    const d = 2 * (a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y));
    if (Math.abs(d) < 1e-9) return { x: 0, y: 0, rSq: 0 };
    const a2 = a.x * a.x + a.y * a.y;
    const b2 = b.x * b.x + b.y * b.y;
    const c2 = c.x * c.x + c.y * c.y;
    const ux = (a2 * (b.y - c.y) + b2 * (c.y - a.y) + c2 * (a.y - b.y)) / d;
    const uy = (a2 * (c.x - b.x) + b2 * (a.x - c.x) + c2 * (b.x - a.x)) / d;
    const rSq = (a.x - ux) * (a.x - ux) + (a.y - uy) * (a.y - uy);
    return { x: ux, y: uy, rSq, r: Math.sqrt(rSq) };
  }

  // Rendering Routines
  function render() {
    ctx.save();
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Grid Background
    drawGrid();

    // Apply Viewport Transform
    ctx.translate(state.pan.x, state.pan.y);
    ctx.scale(state.zoom, state.zoom);

    if (state.mode === "bezier") {
      renderBezierMode();
    } else if (state.mode === "cassowary") {
      renderCassowaryMode();
    } else if (state.mode === "clipper") {
      renderClipperMode();
    } else if (state.mode === "delaunay") {
      renderDelaunayMode();
    } else if (state.mode === "crdt") {
      renderCRDTMode();
    }

    ctx.restore();

    // FPS Meter
    const now = performance.now();
    const delta = now - state.lastFrameTime;
    state.lastFrameTime = now;
    if (delta > 0) {
      state.fps = Math.round(0.9 * state.fps + 0.1 * (1000 / delta));
      statusFps.textContent = state.fps;
    }
  }

  function drawGrid() {
    const w = canvas.parentElement.clientWidth;
    const h = canvas.parentElement.clientHeight;
    const step = 40 * state.zoom;
    const offsetX = state.pan.x % step;
    const offsetY = state.pan.y % step;

    ctx.save();
    ctx.strokeStyle = "#1a1e2b";
    ctx.lineWidth = 1;
    ctx.beginPath();
    for (let x = offsetX; x < w; x += step) {
      ctx.moveTo(x, 0);
      ctx.lineTo(x, h);
    }
    for (let y = offsetY; y < h; y += step) {
      ctx.moveTo(0, y);
      ctx.lineTo(w, y);
    }
    ctx.stroke();

    // Origin Axes
    ctx.strokeStyle = "#2e3447";
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(state.pan.x, 0);
    ctx.lineTo(state.pan.x, h);
    ctx.moveTo(0, state.pan.y);
    ctx.lineTo(w, state.pan.y);
    ctx.stroke();
    ctx.restore();
  }

  function renderBezierMode() {
    const { p0, p1, p2, p3, subdivDepth, showCurvature, showBounds, showHull } = state.bezier;

    // Tight AABB
    if (showBounds) {
      const b = computeTightBounds(p0, p1, p2, p3);
      metricRoots.textContent = b.rootCount;
      ctx.strokeStyle = "rgba(244, 63, 94, 0.4)";
      ctx.lineWidth = 1.5;
      ctx.setLineDash([4, 4]);
      ctx.strokeRect(b.minX, b.minY, b.maxX - b.minX, b.maxY - b.minY);
      ctx.setLineDash([]);

      ctx.fillStyle = "rgba(244, 63, 94, 0.8)";
      ctx.font = "10px monospace";
      ctx.fillText(`Extrema Bounds: [${Math.round(b.minX)}, ${Math.round(b.minY)}] ${Math.round(b.maxX - b.minX)}x${Math.round(b.maxY - b.minY)}`, b.minX, b.minY - 6);
    }

    // Control Polygon Hull
    if (showHull) {
      ctx.strokeStyle = "rgba(100, 116, 139, 0.5)";
      ctx.lineWidth = 1.5;
      ctx.setLineDash([3, 3]);
      ctx.beginPath();
      ctx.moveTo(p0.x, p0.y);
      ctx.lineTo(p1.x, p1.y);
      ctx.lineTo(p2.x, p2.y);
      ctx.lineTo(p3.x, p3.y);
      ctx.stroke();
      ctx.setLineDash([]);
    }

    // Curvature Comb
    if (showCurvature) {
      ctx.strokeStyle = "rgba(56, 189, 248, 0.35)";
      ctx.lineWidth = 1;
      const samples = 48;
      ctx.beginPath();
      for (let i = 0; i <= samples; i++) {
        const t = i / samples;
        const pt = evalCubicBezier(p0, p1, p2, p3, t);
        const d1 = evalCubicDerivative(p0, p1, p2, p3, t);
        const d2 = evalCubicSecondDerivative(p0, p1, p2, p3, t);
        const speedSq = d1.x * d1.x + d1.y * d1.y;
        if (speedSq > 1e-4) {
          const speed = Math.sqrt(speedSq);
          const kappa = (d1.x * d2.y - d1.y * d2.x) / (speed * speedSq);
          const nx = -d1.y / speed;
          const ny = d1.x / speed;
          const combLen = kappa * 2000.0;
          ctx.moveTo(pt.x, pt.y);
          ctx.lineTo(pt.x + nx * combLen, pt.y + ny * combLen);
        }
      }
      ctx.stroke();
    }

    // Bezier Curve Path
    ctx.strokeStyle = "#38bdf8";
    ctx.lineWidth = 3.5;
    ctx.beginPath();
    ctx.moveTo(p0.x, p0.y);
    const steps = Math.pow(2, subdivDepth);
    for (let i = 1; i <= steps; i++) {
      const pt = evalCubicBezier(p0, p1, p2, p3, i / steps);
      ctx.lineTo(pt.x, pt.y);
    }
    ctx.stroke();

    // Arc Length calculation readout
    const arcLen = computeArcLength(p0, p1, p2, p3);
    metricArcLen.textContent = `${arcLen.toFixed(2)} px`;

    // Interactive Control Points
    drawHandle(p0, "#38bdf8", "P0 (Anchor)");
    drawHandle(p1, "#fbbf24", "P1 (Control)");
    drawHandle(p2, "#fbbf24", "P2 (Control)");
    drawHandle(p3, "#38bdf8", "P3 (Anchor)");
  }

  function renderCassowaryMode() {
    const { containerWidth, containerHeight, splitRatio, padding, gap } = state.cassowary;
    const startX = 140;
    const startY = 180;

    // Outer Container
    ctx.strokeStyle = "#4f5b7d";
    ctx.lineWidth = 2;
    ctx.fillStyle = "#161922";
    ctx.fillRect(startX, startY, containerWidth, containerHeight);
    ctx.strokeRect(startX, startY, containerWidth, containerHeight);

    // Label Outer
    ctx.fillStyle = "#94a3b8";
    ctx.font = "11px monospace";
    ctx.fillText(`Container: ${containerWidth} x ${containerHeight} px [FlexRow]`, startX, startY - 10);

    // Compute Balanced Split with Cassowary logic
    const innerW = containerWidth - (padding * 2) - gap;
    const innerH = containerHeight - (padding * 2);
    const box1W = innerW * splitRatio;
    const box2W = innerW * (1.0 - splitRatio);

    const b1X = startX + padding;
    const b1Y = startY + padding;
    const b2X = b1X + box1W + gap;
    const b2Y = startY + padding;

    // Box 1
    ctx.fillStyle = "rgba(56, 189, 248, 0.15)";
    ctx.strokeStyle = "#38bdf8";
    ctx.lineWidth = 2;
    ctx.fillRect(b1X, b1Y, box1W, innerH);
    ctx.strokeRect(b1X, b1Y, box1W, innerH);

    ctx.fillStyle = "#38bdf8";
    ctx.font = "12px sans-serif";
    ctx.fillText("Box A (Left)", b1X + 16, b1Y + 30);
    ctx.font = "10px monospace";
    ctx.fillStyle = "#94a3b8";
    ctx.fillText(`width = ${Math.round(box1W)}px`, b1X + 16, b1Y + 50);
    ctx.fillText(`flex: ${Math.round(splitRatio * 100)}%`, b1X + 16, b1Y + 68);

    // Box 2
    ctx.fillStyle = "rgba(129, 140, 248, 0.15)";
    ctx.strokeStyle = "#818cf8";
    ctx.lineWidth = 2;
    ctx.fillRect(b2X, b2Y, box2W, innerH);
    ctx.strokeRect(b2X, b2Y, box2W, innerH);

    ctx.fillStyle = "#818cf8";
    ctx.font = "12px sans-serif";
    ctx.fillText("Box B (Right)", b2X + 16, b2Y + 30);
    ctx.font = "10px monospace";
    ctx.fillStyle = "#94a3b8";
    ctx.fillText(`width = ${Math.round(box2W)}px`, b2X + 16, b2Y + 50);
    ctx.fillText(`flex: ${Math.round((1 - splitRatio) * 100)}%`, b2X + 16, b2Y + 68);

    // Constraint Dimension Guides
    ctx.strokeStyle = "#34d399";
    ctx.lineWidth = 1;
    ctx.setLineDash([2, 2]);
    ctx.beginPath();
    ctx.moveTo(b1X + box1W, startY + 6);
    ctx.lineTo(b1X + box1W + gap, startY + 6);
    ctx.stroke();
    ctx.setLineDash([]);
    ctx.fillStyle = "#34d399";
    ctx.fillText(`gap: ${gap}px`, b1X + box1W - 8, startY - 4);
  }

  function renderClipperMode() {
    const { polyA, polyB, op } = state.clipper;

    // Draw Poly A
    ctx.strokeStyle = "rgba(56, 189, 248, 0.8)";
    ctx.fillStyle = "rgba(56, 189, 248, 0.12)";
    ctx.lineWidth = 2;
    drawPolygon(polyA, true);

    // Draw Poly B
    ctx.strokeStyle = "rgba(129, 140, 248, 0.8)";
    ctx.fillStyle = "rgba(129, 140, 248, 0.12)";
    ctx.lineWidth = 2;
    drawPolygon(polyB, true);

    // Visual boolean fill simulation
    ctx.save();
    if (op === "intersection") {
      clipPolygonPath(polyA);
      ctx.fillStyle = "rgba(52, 211, 153, 0.35)";
      fillPolygonPath(polyB);
    } else if (op === "union") {
      ctx.fillStyle = "rgba(52, 211, 153, 0.25)";
      fillPolygonPath(polyA);
      fillPolygonPath(polyB);
    } else if (op === "difference") {
      clipPolygonPath(polyA);
      ctx.fillStyle = "rgba(251, 191, 36, 0.35)";
      fillPolygonPath(polyA);
    }
    ctx.restore();

    // Handles for Poly A
    polyA.forEach((pt, i) => drawHandle(pt, "#38bdf8", `A${i}`));
    polyB.forEach((pt, i) => drawHandle(pt, "#818cf8", `B${i}`));

    // Status Banner
    ctx.fillStyle = "#34d399";
    ctx.font = "12px monospace";
    ctx.fillText(`Greiner-Hormann Mode: ${op.toUpperCase()}`, 100, 120);
  }

  function drawPolygon(poly, fill) {
    if (poly.length < 2) return;
    ctx.beginPath();
    ctx.moveTo(poly[0].x, poly[0].y);
    for (let i = 1; i < poly.length; i++) {
      ctx.lineTo(poly[i].x, poly[i].y);
    }
    ctx.closePath();
    if (fill) ctx.fill();
    ctx.stroke();
  }

  function clipPolygonPath(poly) {
    ctx.beginPath();
    ctx.moveTo(poly[0].x, poly[0].y);
    for (let i = 1; i < poly.length; i++) {
      ctx.lineTo(poly[i].x, poly[i].y);
    }
    ctx.closePath();
    ctx.clip();
  }

  function fillPolygonPath(poly) {
    ctx.beginPath();
    ctx.moveTo(poly[0].x, poly[0].y);
    for (let i = 1; i < poly.length; i++) {
      ctx.lineTo(poly[i].x, poly[i].y);
    }
    ctx.closePath();
    ctx.fill();
  }

  function renderDelaunayMode() {
    const { points, showTriangles, showVoronoi, showCircumcircles } = state.delaunay;

    const triangles = bowyerWatson(points);

    // Optional Circumcircles
    if (showCircumcircles) {
      ctx.strokeStyle = "rgba(100, 116, 139, 0.15)";
      ctx.lineWidth = 1;
      triangles.forEach(tri => {
        const cc = getCircumcircle(tri.a, tri.b, tri.c);
        ctx.beginPath();
        ctx.arc(cc.x, cc.y, cc.r, 0, Math.PI * 2);
        ctx.stroke();
      });
    }

    // Delaunay Triangles
    if (showTriangles) {
      ctx.strokeStyle = "rgba(56, 189, 248, 0.4)";
      ctx.fillStyle = "rgba(56, 189, 248, 0.05)";
      ctx.lineWidth = 1.5;
      triangles.forEach(tri => {
        ctx.beginPath();
        ctx.moveTo(tri.a.x, tri.a.y);
        ctx.lineTo(tri.b.x, tri.b.y);
        ctx.lineTo(tri.c.x, tri.c.y);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
      });
    }

    // Dual Voronoi Graph
    if (showVoronoi) {
      ctx.strokeStyle = "#f43f5e";
      ctx.lineWidth = 2;
      for (let i = 0; i < triangles.length; i++) {
        for (let j = i + 1; j < triangles.length; j++) {
          const t1 = triangles[i];
          const t2 = triangles[j];
          let shared = 0;
          if (t1.a === t2.a || t1.a === t2.b || t1.a === t2.c) shared++;
          if (t1.b === t2.a || t1.b === t2.b || t1.b === t2.c) shared++;
          if (t1.c === t2.a || t1.c === t2.b || t1.c === t2.c) shared++;
          if (shared >= 2) {
            const cc1 = getCircumcircle(t1.a, t1.b, t1.c);
            const cc2 = getCircumcircle(t2.a, t2.b, t2.c);
            ctx.beginPath();
            ctx.moveTo(cc1.x, cc1.y);
            ctx.lineTo(cc2.x, cc2.y);
            ctx.stroke();
          }
        }
      }
    }

    // Vertex points
    points.forEach((pt, i) => drawHandle(pt, "#38bdf8", `P${i}`));
  }

  function renderCRDTMode() {
    const { peerA, peerB, cursorA, cursorB } = state.crdt;

    // Peer A Shape: Circle
    ctx.fillStyle = "rgba(56, 189, 248, 0.2)";
    ctx.strokeStyle = peerA.color;
    ctx.lineWidth = 2.5;
    ctx.beginPath();
    ctx.arc(peerA.x, peerA.y, peerA.radius, 0, Math.PI * 2);
    ctx.fill();
    ctx.stroke();

    ctx.fillStyle = "#38bdf8";
    ctx.font = "11px monospace";
    ctx.fillText(`${peerA.label}`, peerA.x - 35, peerA.y + 60);

    // Peer B Shape: Rectangle
    ctx.fillStyle = "rgba(129, 140, 248, 0.2)";
    ctx.strokeStyle = peerB.color;
    ctx.lineWidth = 2.5;
    ctx.fillRect(peerB.x, peerB.y, peerB.width, peerB.height);
    ctx.strokeRect(peerB.x, peerB.y, peerB.width, peerB.height);

    ctx.fillStyle = "#818cf8";
    ctx.font = "11px monospace";
    ctx.fillText(`${peerB.label}`, peerB.x + 10, peerB.y + peerB.height + 18);

    // Presence Cursors
    drawCursor(cursorA, "#38bdf8", "Alice (Peer 1)");
    drawCursor(cursorB, "#818cf8", "Bob (Peer 2)");
  }

  function drawHandle(pt, color, label) {
    ctx.save();
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(pt.x, pt.y, 6 / state.zoom, 0, Math.PI * 2);
    ctx.fill();
    ctx.strokeStyle = "#ffffff";
    ctx.lineWidth = 1.5 / state.zoom;
    ctx.stroke();

    if (label) {
      ctx.font = "10px monospace";
      ctx.fillStyle = "#94a3b8";
      ctx.fillText(label, pt.x + 10 / state.zoom, pt.y - 8 / state.zoom);
    }
    ctx.restore();
  }

  function drawCursor(pos, color, name) {
    ctx.save();
    ctx.translate(pos.x, pos.y);
    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.lineTo(0, 16);
    ctx.lineTo(4, 12);
    ctx.lineTo(10, 16);
    ctx.lineTo(12, 14);
    ctx.lineTo(6, 10);
    ctx.lineTo(12, 10);
    ctx.closePath();
    ctx.fill();

    ctx.fillStyle = color;
    ctx.fillRect(14, 10, name.length * 7 + 10, 18);
    ctx.fillStyle = "#0f1117";
    ctx.font = "10px sans-serif";
    ctx.fillText(name, 19, 23);
    ctx.restore();
  }

  function exportCurrentSVG() {
    let svgContent = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 800" width="1000" height="800">\n`;
    svgContent += `  <rect width="1000" height="800" fill="#0f1117" />\n`;

    if (state.mode === "bezier") {
      const { p0, p1, p2, p3 } = state.bezier;
      svgContent += `  <!-- Stencil Bezier Curve -->\n`;
      svgContent += `  <path d="M ${p0.x} ${p0.y} C ${p1.x} ${p1.y}, ${p2.x} ${p2.y}, ${p3.x} ${p3.y}" fill="none" stroke="#38bdf8" stroke-width="3" />\n`;
    } else if (state.mode === "cassowary") {
      const { containerWidth, containerHeight, splitRatio, padding, gap } = state.cassowary;
      const startX = 140, startY = 180;
      const innerW = containerWidth - (padding * 2) - gap;
      const innerH = containerHeight - (padding * 2);
      const box1W = innerW * splitRatio;
      const box2W = innerW * (1.0 - splitRatio);

      svgContent += `  <rect x="${startX}" y="${startY}" width="${containerWidth}" height="${containerHeight}" fill="#161922" stroke="#4f5b7d" stroke-width="2" />\n`;
      svgContent += `  <rect x="${startX + padding}" y="${startY + padding}" width="${box1W}" height="${innerH}" fill="rgba(56, 189, 248, 0.2)" stroke="#38bdf8" stroke-width="2" />\n`;
      svgContent += `  <rect x="${startX + padding + box1W + gap}" y="${startY + padding}" width="${box2W}" height="${innerH}" fill="rgba(129, 140, 248, 0.2)" stroke="#818cf8" stroke-width="2" />\n`;
    }

    svgContent += `</svg>`;
    const blob = new Blob([svgContent], { type: "image/svg+xml" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `stencil-${state.mode}-export.svg`;
    a.click();
    URL.revokeObjectURL(url);
  }

  // Initial setup
  resizeCanvas();
  render();
})();
