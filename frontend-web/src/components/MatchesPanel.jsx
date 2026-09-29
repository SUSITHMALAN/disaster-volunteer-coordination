import { useEffect, useState } from "react";

import { getMatchesForIncident } from "../api/matches";
import { createAssignment } from "../api/assignments";

import "./MatchesPanel.css";

export default function MatchesPanel({ incidentId }) {
  const [matches, setMatches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [assigningId, setAssigningId] = useState(null);

  const [durationId, setDurationId] = useState(null);
  const [duration, setDuration] = useState("60");

  const [success, setSuccess] = useState("");

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
    } catch (err) {
      setError(err.message || "Failed to create assignment.");
    } finally {
      setAssigningId(null);
    }
  }

  if (loading) {
    return <p className="matches-panel__status">Loading matches...</p>;
  }

  if (error) {
    return (
      <p className="matches-panel__status matches-panel__status--error">
        {error}
      </p>
    );
  }

  if (matches.length === 0) {
    return (
      <p className="matches-panel__status">No matches yet for this incident.</p>
    );
  }

  return (
    <div className="matches-panel">
      {success && (
        <p className="matches-panel__status matches-panel__status--success">
          {success}
        </p>
      )}

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

        return (
          <div key={match.id} className="match-row">
            <div className="match-row__rank">#{index + 1}</div>

            <div className="match-row__info">
              <div className="match-row__name">{match.volunteerName}</div>

              <div className="match-row__rationale">{match.rationale}</div>
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

              {match.status === "Approved" && (
                <div className="match-row__assignment">
                  {durationId === match.id ? (
                    <div className="match-row__assignment-form">
                      <label className="match-row__duration-field">
                        <span>Duration (minutes)</span>

                        <input
                          type="number"
                          min="1"
                          step="1"
                          value={duration}
                          onChange={(event) => setDuration(event.target.value)}
                        />
                      </label>

                      <div className="match-row__assignment-actions">
                        <button
                          type="button"
                          onClick={() => handleCreateAssignment(match.id)}
                          disabled={assigningId === match.id}
                        >
                          {assigningId === match.id ? "Creating..." : "Confirm"}
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
                      onClick={() => setDurationId(match.id)}
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
