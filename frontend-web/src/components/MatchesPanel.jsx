import { useEffect, useState } from "react";

import { getMatchesForIncident, updateMatchStatus } from "../api/matches";

import { createAssignment } from "../api/assignments";

import "./MatchesPanel.css";

const DURATION_PRESETS = [
  { label: "30 min", value: "30" },
  { label: "1 hour", value: "60" },
  { label: "2 hours", value: "120" },
];

const VALIDATION_CHECKS = [
  {
    key: "capacity",
    label: "Capacity Check",
  },
  {
    key: "skills",
    label: "Required Skills",
  },
  {
    key: "severity",
    label: "Severity / Comfort Tier",
  },
  {
    key: "time-window",
    label: "Availability Window",
  },
];

function buildRankedMatches(apiMatches) {
  const list = Array.isArray(apiMatches) ? [...apiMatches] : [];

  return list.sort((a, b) => {
    const scoreA =
      typeof a.score === "number" ? (a.score > 1 ? a.score / 100 : a.score) : 0;

    const scoreB =
      typeof b.score === "number" ? (b.score > 1 ? b.score / 100 : b.score) : 0;

    return scoreB - scoreA;
  });
}

function getPassedValidationResult(matchId) {
  return {
    matchId,
    verdict: "approved",
    reason: "All assignment safety checks passed.",
    checks: VALIDATION_CHECKS.map((check) => ({
      ...check,
      status: "passed",
    })),
  };
}

function getRejectedValidationResult(matchId, message) {
  const normalizedMessage = String(message || "").toLowerCase();

  let failedIndex = -1;

  if (normalizedMessage.includes("capacity validation failed")) {
    failedIndex = 0;
  } else if (normalizedMessage.includes("skill validation failed")) {
    failedIndex = 1;
  } else if (normalizedMessage.includes("severity validation failed")) {
    failedIndex = 2;
  } else if (normalizedMessage.includes("time-window validation failed")) {
    failedIndex = 3;
  }

  if (failedIndex === -1) {
    return null;
  }

  return {
    matchId,
    verdict: "rejected",
    reason: message,
    checks: VALIDATION_CHECKS.map((check, index) => {
      let status = "not-run";

      if (index < failedIndex) {
        status = "passed";
      }

      if (index === failedIndex) {
        status = "failed";
      }

      return {
        ...check,
        status,
      };
    }),
  };
}

function getCheckIcon(status) {
  if (status === "passed") {
    return "✓";
  }

  if (status === "failed") {
    return "✕";
  }

  if (status === "running") {
    return "…";
  }

  return "–";
}

function getCheckLabel(status) {
  if (status === "passed") {
    return "Passed";
  }

  if (status === "failed") {
    return "Failed";
  }

  if (status === "running") {
    return "Checking";
  }

  return "Not run";
}

export default function MatchesPanel({ incidentId }) {
  const [matches, setMatches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [assigningId, setAssigningId] = useState(null);

  const [durationId, setDurationId] = useState(null);
  const [duration, setDuration] = useState("60");
  const [durationMode, setDurationMode] = useState("60");

  const [success, setSuccess] = useState("");
  const [updatingStatusId, setUpdatingStatusId] = useState(null);

  const [validationResult, setValidationResult] = useState(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      setError(null);
      setSuccess("");
      setValidationResult(null);

      try {
        const data = await getMatchesForIncident(incidentId);

        if (!cancelled) {
          setMatches(buildRankedMatches(data));
        }
      } catch (err) {
        if (!cancelled) {
          setMatches([]);
          setError(err.message || "Failed to load volunteer matches.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    if (incidentId) {
      load();
    } else {
      setMatches([]);
      setLoading(false);
    }

    return () => {
      cancelled = true;
    };
  }, [incidentId]);

  function openAssignmentForm(matchId) {
    setDurationId(matchId);
    setDuration("60");
    setDurationMode("60");

    setError(null);
    setSuccess("");
    setValidationResult(null);
  }

  function handleDurationPreset(value) {
    setDurationMode(value);

    if (value !== "custom") {
      setDuration(value);
    }
  }

  async function handleMatchStatus(matchId, newStatus) {
    if (updatingStatusId) {
      return;
    }

    setUpdatingStatusId(matchId);
    setError(null);
    setSuccess("");
    setValidationResult(null);

    try {
      const updatedMatch = await updateMatchStatus(matchId, newStatus);

      setMatches((previous) =>
        previous.map((match) => (match.id === matchId ? updatedMatch : match)),
      );

      setSuccess(`Volunteer match ${newStatus.toLowerCase()}.`);
    } catch (err) {
      setError(
        err.message || `Failed to ${newStatus.toLowerCase()} volunteer match.`,
      );
    } finally {
      setUpdatingStatusId(null);
    }
  }

  async function handleCreateAssignment(matchId) {
    const estimatedDurationMinutes = Number(duration);

    if (
      !Number.isInteger(estimatedDurationMinutes) ||
      estimatedDurationMinutes <= 0
    ) {
      setError("Estimated duration must be a positive number of minutes.");

      return;
    }

    setAssigningId(matchId);
    setError(null);
    setSuccess("");

    setValidationResult({
      matchId,
      verdict: "running",
      reason: "Running assignment safety checks...",
      checks: VALIDATION_CHECKS.map((check) => ({
        ...check,
        status: "running",
      })),
    });

    try {
      await createAssignment(matchId, estimatedDurationMinutes);

      setValidationResult(getPassedValidationResult(matchId));

      setMatches((previous) =>
        previous.map((match) =>
          match.id === matchId
            ? {
                ...match,
                status: "Dispatched",
              }
            : match,
        ),
      );

      setSuccess(
        "Assignment created successfully. Safety validation passed and the volunteer was dispatched.",
      );

      setDurationId(null);
      setDuration("60");
      setDurationMode("60");
    } catch (err) {
      const message = err.message || "Failed to create assignment.";

      const rejectedResult = getRejectedValidationResult(matchId, message);

      if (rejectedResult) {
        setValidationResult(rejectedResult);
      } else {
        setValidationResult(null);
      }

      setError(message);
    } finally {
      setAssigningId(null);
    }
  }

  if (loading) {
    return <p className="matches-panel__status">Loading matches...</p>;
  }

  if (matches.length === 0 && !error) {
    return (
      <p className="matches-panel__status">No matches yet for this incident.</p>
    );
  }

  return (
    <div className="matches-panel">
      {error && (
        <p className="matches-panel__status matches-panel__status--error">
          {error}
        </p>
      )}

      {success && (
        <p className="matches-panel__status matches-panel__status--success">
          {success}
        </p>
      )}

      <div className="matches-panel__validation-note">
        <strong>Safety validation:</strong> Assignment creation re-checks
        volunteer capacity, required skills, severity comfort tier, and
        availability window.
      </div>

      {matches.map((match, index) => {
        const score =
          typeof match.score === "number"
            ? match.score > 1
              ? match.score
              : match.score * 100
            : 0;

        const percentage = Math.min(Math.round(score), 100);

        const statusClass =
          match.status?.toLowerCase().replace(/\s+/g, "-") || "unknown";

        const isAssignmentOpen = durationId === match.id;

        const matchValidation =
          validationResult?.matchId === match.id ? validationResult : null;

        return (
          <div key={match.id} className="match-row">
            <div className="match-row__rank">#{index + 1}</div>

            <div className="match-row__info">
              <div className="match-row__name">{match.volunteerName}</div>

              <div className="match-row__rationale">
                {match.rationale || "No matching rationale provided."}
              </div>
            </div>

            <div className="match-row__right">
              <div className="match-row__summary">
                <div className="match-row__score">{percentage}%</div>

                <span
                  className={`match-row__status match-row__status--${statusClass}`}
                >
                  {match.status}
                </span>
              </div>

              {match.status === "Proposed" && (
                <div className="match-row__proposal-actions">
                  <button
                    type="button"
                    className="match-row__approve-button"
                    onClick={() => handleMatchStatus(match.id, "Approved")}
                    disabled={updatingStatusId === match.id}
                  >
                    {updatingStatusId === match.id ? "Updating..." : "Approve"}
                  </button>

                  <button
                    type="button"
                    className="match-row__reject-button"
                    onClick={() => handleMatchStatus(match.id, "Rejected")}
                    disabled={updatingStatusId === match.id}
                  >
                    {updatingStatusId === match.id ? "Updating..." : "Reject"}
                  </button>
                </div>
              )}

              {match.status === "Approved" && (
                <div className="match-row__assignment">
                  {isAssignmentOpen ? (
                    <div className="match-row__assignment-form">
                      <div className="match-row__duration-section">
                        <span className="match-row__duration-label">
                          Estimated Duration
                        </span>

                        <div className="match-row__duration-presets">
                          {DURATION_PRESETS.map((preset) => (
                            <button
                              key={preset.value}
                              type="button"
                              className={`match-row__duration-option ${
                                durationMode === preset.value
                                  ? "match-row__duration-option--active"
                                  : ""
                              }`}
                              onClick={() => handleDurationPreset(preset.value)}
                              disabled={assigningId === match.id}
                            >
                              {preset.label}
                            </button>
                          ))}

                          <button
                            type="button"
                            className={`match-row__duration-option ${
                              durationMode === "custom"
                                ? "match-row__duration-option--active"
                                : ""
                            }`}
                            onClick={() => handleDurationPreset("custom")}
                            disabled={assigningId === match.id}
                          >
                            Custom
                          </button>
                        </div>

                        {durationMode === "custom" && (
                          <label className="match-row__duration-field">
                            <span>Custom duration in minutes</span>

                            <input
                              type="number"
                              min="1"
                              step="1"
                              value={duration}
                              onChange={(event) =>
                                setDuration(event.target.value)
                              }
                              disabled={assigningId === match.id}
                            />
                          </label>
                        )}
                      </div>

                      <div className="match-row__selected-duration">
                        Selected: <strong>{duration || "0"} minutes</strong>
                      </div>

                      <div className="match-row__assignment-actions">
                        <button
                          type="button"
                          onClick={() => handleCreateAssignment(match.id)}
                          disabled={assigningId === match.id}
                        >
                          {assigningId === match.id
                            ? "Running validation..."
                            : "Confirm Assignment"}
                        </button>

                        <button
                          type="button"
                          className="match-row__cancel"
                          onClick={() => {
                            setDurationId(null);
                            setValidationResult(null);
                            setError(null);
                          }}
                          disabled={assigningId === match.id}
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  ) : (
                    <button
                      type="button"
                      className="match-row__assign-button"
                      onClick={() => openAssignmentForm(match.id)}
                    >
                      Create Assignment
                    </button>
                  )}
                </div>
              )}

              {matchValidation && (
                <div
                  className={`match-row__validation-result match-row__validation-result--${matchValidation.verdict}`}
                >
                  <div className="match-row__validation-header">
                    <div>
                      <span className="match-row__validation-eyebrow">
                        SAFETY VALIDATION
                      </span>

                      <strong>Safety Validation Gate</strong>
                    </div>

                    <span
                      className={`match-row__validation-verdict match-row__validation-verdict--${matchValidation.verdict}`}
                    >
                      {matchValidation.verdict === "approved"
                        ? "APPROVED"
                        : matchValidation.verdict === "rejected"
                          ? "REJECTED"
                          : "CHECKING"}
                    </span>
                  </div>

                  <div className="match-row__validation-checks">
                    {matchValidation.checks.map((check) => (
                      <div
                        key={check.key}
                        className={`match-row__validation-check match-row__validation-check--${check.status}`}
                      >
                        <span className="match-row__validation-icon">
                          {getCheckIcon(check.status)}
                        </span>

                        <span className="match-row__validation-label">
                          {check.label}
                        </span>

                        <span className="match-row__validation-state">
                          {getCheckLabel(check.status)}
                        </span>
                      </div>
                    ))}
                  </div>

                  {matchValidation.reason && (
                    <p className="match-row__validation-reason">
                      <strong>
                        {matchValidation.verdict === "rejected"
                          ? "Reason:"
                          : "Result:"}
                      </strong>{" "}
                      {matchValidation.reason}
                    </p>
                  )}
                </div>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}
