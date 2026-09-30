import { useEffect, useState } from "react";

import { getMatchesForIncident, updateMatchStatus } from "../api/matches";
import { createAssignment } from "../api/assignments";

import "./MatchesPanel.css";

const DURATION_PRESETS = [
  { label: "30 min", value: "30" },
  { label: "1 hour", value: "60" },
  { label: "2 hours", value: "120" },
];

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

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      setError(null);
      setSuccess("");

      try {
        const data = await getMatchesForIncident(incidentId);

        if (!cancelled) {
          setMatches(data || []);
        }
      } catch (err) {
        if (!cancelled) {
          setError(err.message || "Failed to load matches.");
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    if (incidentId) {
      load();
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

    try {
      const updatedMatch = await updateMatchStatus(matchId, newStatus);

      setMatches((previous) =>
        previous.map((match) => (match.id === matchId ? updatedMatch : match)),
      );

      if (newStatus === "Approved") {
        setSuccess("Volunteer match approved.");
      } else {
        setSuccess("Volunteer match rejected.");
      }
    } catch (err) {
      setError(err.message || `Failed to ${newStatus.toLowerCase()} match.`);
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

    try {
      await createAssignment(matchId, estimatedDurationMinutes);

      setSuccess("Assignment created successfully.");

      setDurationId(null);
      setDuration("60");
      setDurationMode("60");
    } catch (err) {
      setError(err.message || "Failed to create assignment.");
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
                            ? "Creating..."
                            : "Confirm Assignment"}
                        </button>

                        <button
                          type="button"
                          className="match-row__cancel"
                          onClick={() => setDurationId(null)}
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
            </div>
          </div>
        );
      })}
    </div>
  );
}
