import { useEffect, useState } from "react";
import { getMatchesForIncident } from "../api/matches";
import "./MatchesPanel.css";

export default function MatchesPanel({ incidentId }) {
  const [matches, setMatches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    async function load() {
      setLoading(true);
      setError(null);
      try {
        const data = await getMatchesForIncident(incidentId);
        if (!cancelled) setMatches(data);
      } catch (err) {
        if (!cancelled) setError(err.message);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    if (incidentId) load();
    return () => { cancelled = true; };
  }, [incidentId]);

  if (loading) return <p className="matches-panel__status">Loading matches…</p>;
  if (error) return <p className="matches-panel__status matches-panel__status--error">{error}</p>;
  if (matches.length === 0) return <p className="matches-panel__status">No matches yet for this incident.</p>;

  return (
    <div className="matches-panel">
      {matches.map((m, i) => (
        <div key={m.id} className="match-row">
          <div className="match-row__rank">#{i + 1}</div>
          <div className="match-row__info">
            <div className="match-row__name">{m.volunteerName}</div>
            <div className="match-row__rationale">{m.rationale}</div>
          </div>
          <div className="match-row__right">
            <div className="match-row__score">{(m.score * 100).toFixed(0)}%</div>
            <span className={`match-row__status match-row__status--${m.status.toLowerCase()}`}>
              {m.status}
            </span>
          </div>
        </div>
      ))}
    </div>
  );
}