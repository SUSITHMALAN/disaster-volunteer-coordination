# ADR 0001: Deterministic Scoring vs. LLM-Generated Rationales for Volunteer Matching

## Status
Accepted

## Context
In the Disaster Volunteer Coordination system, matching volunteers to emergency incidents requires high auditability, reliability, and precision. We evaluated two architectural approaches:
1. Pure LLM-based matching (where an LLM outputs both numerical match scores and decision rationales).
2. Hybrid matching (where candidate scoring is strictly deterministic based on mathematical weights, and the LLM exclusively generates human-readable explanations).

## Decision
We decided to adopt a **Hybrid Matching Architecture**:
- **Candidate Scoring**: Strictly deterministic mathematical scoring formula combining skill overlap, zone proximity, availability, and past reliability metrics (`score = skill * 0.5 + zone * 0.2 + availability * 0.2 + reliability * 0.1`).
- **LLM Responsibility**: The LLM is restricted solely to formatting and generating natural-language rationale text explaining *why* the score was produced.

## Rationale
- **Deterministic & Auditable**: Emergency response algorithms must produce 100% reproducible rankings for audit compliance. Non-deterministic LLM scoring runs the risk of hallucinations or inconsistent rankings across repeated queries.
- **Configurability**: Numerical weights can be tuned via system environment variables without needing prompt engineering or retraining LLM models.
- **Resilience & Fallbacks**: If the LLM service experiences downtime or network latency, candidate scoring and persistence proceed uninhibited using deterministic fallback template rationales.

## Consequences
- Matching Agent components are divided cleanly: `score_candidate` (pure function) vs `generate_rationale` (text formatting / LLM prompt).
- Unit tests can verify ranking algorithms without mocking external LLM responses.
