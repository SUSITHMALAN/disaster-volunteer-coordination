import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";

import MatchesPanel from "../components/MatchesPanel";
import { getIncidents } from "../api/incidents";

import "./MatchesPage.css";

export default function MatchesPage() {
  const [searchParams] = useSearchParams();

  const queryIncidentId = searchParams.get("incidentId") || "";

  const [incidents, setIncidents] = useState([]);
  const [incidentId, setIncidentId] = useState(queryIncidentId);

  const [submittedId, setSubmittedId] = useState(queryIncidentId);

  const [loadingIncidents, setLoadingIncidents] = useState(true);

  const [incidentError, setIncidentError] = useState("");

  useEffect(() => {
    fetchIncidents();
  }, []);

  useEffect(() => {
    setIncidentId(queryIncidentId);
    setSubmittedId(queryIncidentId);
  }, [queryIncidentId]);

  async function fetchIncidents() {
    setLoadingIncidents(true);
    setIncidentError("");

    try {
      const data = await getIncidents();

      setIncidents(data || []);
    } catch (err) {
      setIncidentError(err.message || "Failed to load incidents.");

      setIncidents([]);
    } finally {
      setLoadingIncidents(false);
    }
  }

  function handleSubmit(e) {
    e.preventDefault();

    if (!incidentId) {
      return;
    }

    setSubmittedId(incidentId);
  }

  return (
    <main className="matches-page">
      <header className="matches-page__header">
        <div>
          <p className="matches-page__eyebrow">VOLUNTEER COORDINATION</p>

          <h1 className="matches-page__title">Volunteer Matches</h1>

          <p className="matches-page__subtitle">
            Select an incident to review its ranked volunteer matches and create
            assignments.
          </p>
        </div>
      </header>

      <form className="matches-page__form" onSubmit={handleSubmit}>
        <label className="matches-page__field">
          <span>Incident Name</span>

          <select
            value={incidentId}
            onChange={(e) => setIncidentId(e.target.value)}
            disabled={loadingIncidents}
            required
          >
            <option value="">
              {loadingIncidents ? "Loading incidents..." : "Select an incident"}
            </option>

            {incidents.map((incident) => (
              <option key={incident.id} value={incident.id}>
                {incident.title}
              </option>
            ))}
          </select>
        </label>

        <label className="matches-page__field">
          <span>Incident ID</span>

          <input
            type="text"
            value={incidentId}
            readOnly
            placeholder="Incident ID will appear here"
          />
        </label>

        {incidentError && (
          <div className="matches-page__error" role="alert">
            {incidentError}
          </div>
        )}

        <div className="matches-page__actions">
          <button type="submit" disabled={!incidentId || loadingIncidents}>
            View Matches
          </button>
        </div>
      </form>

      {submittedId && <MatchesPanel incidentId={submittedId} />}
    </main>
  );
}
