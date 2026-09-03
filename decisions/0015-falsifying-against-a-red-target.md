# 0015 — Falsifying a new assertion against an already-red target

Operator-decided, from pass 0039's LEDGER 48. When a new assertion's reference
target already violates it, the falsification and the measurement are two claims
and get two artifacts. The assertion's capability is proven on a purpose-built
known-good fixture: the break must go red there, the control must stay green
there, polarity rules unchanged. The reference target's real behaviour is then
measured and Bucket-sorted separately, with the boundary rationale stated (it
predates the rule). Neither artifact substitutes for the other: falsifying only
against the red target proves nothing about the green path, and fixing the
target to falsify the assertion rewrites history to fit the grader. Pass 0039's
Help block is the worked example.
