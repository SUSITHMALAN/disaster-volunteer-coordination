import { useState, useEffect } from "react";
import { useSearchParams } from "react-router-dom";
import MatchesPanel from "../components/MatchesPanel";
import BackButton from "../components/BackButton";
import "./MatchesPage.css";

export default function MatchesPage() {
  const [searchParams] = useSearchParams();
  const initialId = searchParams.get("incidentId") || "";
  const [incidentId, setIncidentId] = useState(initialId);
  const [submittedId, setSubmittedId] = useState(initialId);

  useEffect(() => {
    const qId = searchParams.get("incidentId");
    if (qId) {
      setIncidentId(qId);
      setSubmittedId(qId);
    }
  }, [searchParams]);

  function handleSubmit(e) {
    e.preventDefault();
    setSubmittedId(incidentId.trim());
  }

  return (
    <div className="matches-page">
      <BackButton to="/" label="Back to Dashboard" />
      <h1 className="matches-page__title">Volunteer Matches</h1>
      <p className="matches-page__subtitle">
        Enter an incident ID to see its ranked volunteer matches.
      </p>

      <form className="matches-page__form" onSubmit={handleSubmit}>
        <input
          type="text"
          placeholder="Incident ID (e.g. 55555555-5555-5555-5555-555555555551)"
          value={incidentId}
          onChange={(e) => setIncidentId(e.target.value)}
        />
        <button type="submit">View matches</button>
      </form>

      {submittedId && <MatchesPanel incidentId={submittedId} />}
    </div>
  );
}