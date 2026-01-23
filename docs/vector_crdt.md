# Conflict-Free Replicated Scene Tree (CRDTree)

The `stencil.crdt` package provides a decentralized, peer-to-peer replication engine for vector document graphs. It allows multiple clients to concurrently edit scene nodes, re-parent shapes, and alter styling without requiring centralized locking or server mediation.

## 1. Causal Ordering & Vector Clocks

Each participating replica maintains a `VectorClock` represented as a mapping from client identifiers to monotonically increasing logical integers:

$$V = \{ C_1: k_1, C_2: k_2, \dots, C_m: k_m \}$$

### Partial Ordering Definition
For two operations tagged with vector clocks $V_A$ and $V_B$:
- $V_A \le V_B \iff \forall k, V_A[k] \le V_B[k]$ ($V_A$ causally preceded $V_B$)
- $V_A < V_B \iff V_A \le V_B \land V_A \ne V_B$ (strict causality)
- $V_A \parallel V_B \iff \neg(V_A \le V_B) \land \neg(V_B \le V_A)$ (concurrent operations)

### State Merging
When receiving a remote operation or synchronizing state vectors:

$$V_{\text{merged}}[k] = \max(V_{\text{local}}[k], V_{\text{remote}}[k])$$

---

## 2. Deterministic Tie-Breaking with Lamport Timestamps

To resolve concurrent mutations without ambiguity, every mutation is stamped with a composite `LamportTimestamp` consisting of `(logicalTime, peerId)`:

$$\tau = \langle t, p \rangle$$

Given two concurrent timestamps $\tau_1 = \langle t_1, p_1 \rangle$ and $\tau_2 = \langle t_2, p_2 \rangle$:

$$\tau_1 \prec \tau_2 \iff (t_1 < t_2) \lor (t_1 = t_2 \land p_1 < p_2)$$

Because string comparison of `peerId` is antisymmetric and transitive, this provides a total ordering over all edits across all nodes in the distributed system.

---

## 3. Tree Replication & Cycle Prevention

Replicating hierarchical scene trees (where nodes can be moved and re-parented) is notoriously prone to cycle formation under concurrent moves. For example, if Peer A moves Node X under Node Y while Peer B concurrently moves Node Y under Node X, naive resolution creates an orphaned cycle `X -> Y -> X`, disconnecting both from the document root.

### Kleppmann Cycle Avoidance Algorithm
Stencil implements Martin Kleppmann's verified tree move algorithm:

```
function applyMove(nodeId, newParentId, timestamp):
    if nodeId == newParentId:
        return REJECT_CYCLE
    
    // Check if nodeId is an ancestor of newParentId
    curr = newParentId
    while curr != null:
        if curr == nodeId:
            return REJECT_CYCLE // Cyclic dependency detected
        curr = getParent(curr)
        
    // Execute move transaction
    setParent(nodeId, newParentId, timestamp)
    return ACCEPTED
```

When concurrent operations would induce a cycle, the operation with the smaller timestamp according to the total ordering $\prec$ is rejected or redirected to the document root, ensuring every node remains part of a strictly acyclic rooted tree.

---

## 4. Tombstone Node Lifecycle

Node deletion in `CRDTree` does not immediately purge memory structures. If a deleted node were completely removed, a delayed concurrent operation (e.g. moving a child into the deleted node or modifying its fill color) would produce a null reference or resurrection anomaly.

Instead, deletion marks the node with a `tombstone = true` flag and preserves its structural identity. Children of tombstoned nodes remain intact or can be re-parented. A garbage collection pass occurs only when a vector clock exchange confirms all known peers have witnessed the deletion timestamp.

---

## 5. Property Synchronization (LWW-Register)

Visual attributes of nodes (such as `x`, `y`, `fillColor`, `strokeWidth`, `opacity`) are modeled as Last-Write-Wins (LWW) registers. When multiple peers update the same property concurrently:
- The mutation carrying the highest Lamport timestamp $\tau$ overwrites previous state.
- Local undo/redo transactions in `HistoryManager` record exact inverse operations, rewinding and reapplying local edits without corrupting remote causality vectors.
