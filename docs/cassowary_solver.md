# Cassowary Simplex Constraint Solver

Stencil incorporates an implementation of the Cassowary linear arithmetic constraint solver algorithm in ActionScript 3 (`stencil.layout.CassowarySolver`). The solver powers dynamic layout balancing, responsive component resizing, and geometric snapping.

## 1. Problem Formulation

Layout relationships in Stencil are represented as systems of linear equalities and inequalities over real-valued variables:

$$\sum_{j=1}^n a_{ij} v_j = c_i \quad \text{or} \quad \sum_{j=1}^n a_{ij} v_j \le c_i$$

Where:
- $v_j$ are geometric parameters (e.g. `x`, `y`, `width`, `height`, `centerX`).
- $a_{ij}$ are scalar coefficients.
- $c_i$ is a constant offset.

### Constraint Strengths
Constraints are organized into a strict hierarchical priority system:
1. `REQUIRED` ($1.0 \times 10^9$): Inviolable mathematical invariants (e.g. `box.right == box.left + box.width`, or `box.width >= 0`). If violated, the solver detects an unsatisfiable condition.
2. `STRONG` ($1.0 \times 10^6$): User-directed layout intents (e.g. alignment rules and explicit user setpoints).
3. `MEDIUM` ($1.0 \times 10^3$): Automatic flow rules, flex distributions, and smart guide snaps.
4. `WEAK` ($1.0$): Default resting positions and stay constraints that preserve stability when degrees of freedom remain.

---

## 2. Tableau Representation & Slack Variables

Inequalities are converted into equalities by introducing non-negative slack variables $s_i \ge 0$:

$$a \cdot x \le b \implies a \cdot x + s = b$$

Soft constraints (non-required) introduce positive and negative error variables $e_i^+, e_i^- \ge 0$ to quantify deviation from the ideal goal:

$$a \cdot x = b \implies a \cdot x + e_i^- - e_i^+ = b$$

The objective function minimizes the weighted sum of error variables according to their constraint strength:

$$\min \sum_i w_i (e_i^+ + e_i^-)$$

The solver maintains a Simplex tableau divided into:
- **Basic Variables**: Expressed on the left side of tableau equations ($v_B = c + \sum k_i v_{NB}$).
- **Parametric (Non-Basic) Variables**: Independent variables that take the value zero in the current basic feasible solution.

---

## 3. Dual-Simplex Pivoting

When a constraint is added or modified, the basic solution may become infeasible ($c < 0$ for a restricted basic variable). The solver restores feasibility using dual-simplex pivoting:

1. **Select Leaving Variable**: Choose a basic variable $v_B$ whose constant term in the tableau is negative ($c < 0$).
2. **Ratio Test for Entering Variable**: Choose a parametric variable $v_{NB}$ that minimizes the pivoting ratio to maintain optimality of the objective function.
3. **Tableau Pivot Operation**:
   - Solve the row equation of $v_B$ for $v_{NB}$.
   - Substitute $v_{NB}$ into all other rows of the tableau, including the objective function row.
   - Swap $v_B$ and $v_{NB}$ between the basic and non-basic sets.

---

## 4. Interactive Edit and Stay Constraints

Continuous UI dragging requires high-throughput updates without reconstructing the entire constraint matrix every frame.

### Stay Constraints
Stay constraints ($v = v_{\text{current}}$ at `WEAK` strength) are automatically placed on free variables. This prevents objects from jumping or drifting unpredictably when other constraints are adjusted.

### Edit Constraints
When an element handle is dragged:
1. An edit constraint is registered via `addEditVar(variable, strength)`.
2. Two edit-specific artificial variables are injected into the tableau.
3. During mouse move events, `suggestValue(variable, newValue)` updates the tableau constants in $O(M)$ time (where $M$ is the number of dependent rows), rather than re-solving the full $O(M \times N)$ linear program.
4. When dragging ends, `removeEditVar(variable)` clears the artificial variables and restores permanent constraints.

---

## 5. Integration with FlexLayoutEngine

The `FlexLayoutEngine` combines the Cassowary solver with flexbox semantics:
- Rows and columns define linear sum constraints: $\sum \text{child.width} + (N-1) \cdot \text{gap} = \text{parent.innerWidth}$.
- `flexGrow` factors map to relative error weights in the objective function, distributing surplus space proportionally across flexible cards.
- Bounds clipping and min/max dimensions map directly to Simplex inequality rows.
