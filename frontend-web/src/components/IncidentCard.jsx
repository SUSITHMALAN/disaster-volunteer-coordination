import "./IncidentCard.css";

// Mirrors IncidentService.IsLegalTransition on the backend, so the UI only
// ever offers a status change that the API will actually accept.
const NEXT_STATUS = {
  Reported: "Triaged",
  Triaged: "Matching",
  Matching: "Assigned",
  Assigned: "InProgress",
  InProgress: "Resolved",
};

const SEVERITY_CLASS = {
  Low: "i-card__severity--low",
  Medium: "i-card__severity--medium",
  High: "i-card__severity--high",
  Critical: "i-card__severity--critical",
};

export default function IncidentCard({ incident, onAdvanceStatus, onCancel }) {
  const nextStatus = NEXT_STATUS[incident.status];
  const canCancel = incident.status !== "Resolved" && incident.status !== "Cancelled";

  return (
    <div className="i-card">
      <div className="i-card__main">
        <div className="i-card__top">
          <span className="i-card__title">{incident.title}</span>
          <span className={`i-card__severity ${SEVERITY_CLASS[incident.severity] || ""}`}>
            {incident.severity}
          </span>
        </div>

        <p className="i-card__description">{incident.description}</p>

        <div className="i-card__meta">
          <span className="i-card__tag">{incident.category}</span>
          <span className="i-card__status-badge">{incident.status}</span>
          {incident.zone && <span className="i-card__zone">📍 {incident.zone}</span>}
        </div>

        {incident.requiredSkills?.length > 0 && (
          <div className="i-card__skills">
            {incident.requiredSkills.map((skill) => (
              <span key={skill} className="i-card__skill-tag">{skill}</span>
            ))}
          </div>
        )}
      </div>

      <div className="i-card__actions">
        {nextStatus && (
          <button
            className="i-card__action i-card__action--advance"
            onClick={() => onAdvanceStatus(incident.id, nextStatus)}
          >
            Mark as {nextStatus}
          </button>
        )}
        {canCancel && (
          <button
            className="i-card__action i-card__action--cancel"
            onClick={() => onCancel(incident.id)}
          >
            Cancel
          </button>
        )}
      </div>
    </div>
  );
}
