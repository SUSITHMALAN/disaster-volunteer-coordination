import { useState } from "react";
import MatchesPanel from "../components/MatchesPanel";
import "./MatchesPage.css";

export default function MatchesPage() {
  const [incidentId, setIncidentId] = useState("");
  const [submittedId, setSubmittedId] = useState("");

  function handleSubmit(e) {
    e.preventDefault();
    setSubmittedId(incidentId.trim());
  }

  return (
    <div className="matches-page">
      <h1 className="matches-page__title">Volunteer Matches</h1>
      <p className="matches-page__subtitle">
        Enter an incident ID to see its ranked volunteer matches.
      </p>

      <form className="matches-page__form" onSubmit={handleSubmit}>
        <input
          type="text"
          placeholder="Incident ID"
          value={incidentId}
          onChange={(e) => setIncidentId(e.target.value)}
        />
        <button type="submit">View matches</button>
      </form>

      {submittedId && <MatchesPanel incidentId={submittedId} />}
    </div>
  );
}