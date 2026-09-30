import "./VolunteerCard.css";

function formatAvailabilityWindow(start, end) {
  if (!start || !end) {
    return "Not specified";
  }

  const startDate = new Date(start);
  const endDate = new Date(end);

  if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime())) {
    return "Not specified";
  }

  return `${startDate.toLocaleString()} — ${endDate.toLocaleString()}`;
}

export default function VolunteerCard({
  volunteer,
  onToggleAvailability,
  isUpdating,
}) {
  const isAvailable = volunteer.isAvailable;

  const skills = volunteer.skills || [];

  const certifications = volunteer.certifications || [];

  const activeAssignments = Number(volunteer.activeAssignments || 0);

  const maximumAssignments = Number(volunteer.maximumActiveAssignments || 0);

  const atCapacity =
    maximumAssignments > 0 && activeAssignments >= maximumAssignments;

  return (
    <article className={`v-card ${isAvailable ? "v-card--available" : ""}`}>
      <div className="v-card__top">
        <div>
          <div className="v-card__name">{volunteer.fullName}</div>

          <div className="v-card__email">{volunteer.email}</div>
        </div>

        <button
          type="button"
          className={`v-card__toggle ${
            isAvailable
              ? "v-card__toggle--available"
              : "v-card__toggle--unavailable"
          }`}
          onClick={() => onToggleAvailability(volunteer.id, !isAvailable)}
          disabled={isUpdating}
        >
          {isUpdating
            ? "Updating..."
            : isAvailable
              ? "Available"
              : "Unavailable"}
        </button>
      </div>

      <div className="v-card__details-grid">
        <div className="v-card__section">
          <span className="v-card__label">Skills</span>

          <div className="v-card__tags">
            {skills.length > 0 ? (
              skills.map((skill) => (
                <span key={skill} className="v-card__tag v-card__tag--skill">
                  {skill}
                </span>
              ))
            ) : (
              <span className="v-card__empty">No skills listed</span>
            )}
          </div>
        </div>

        <div className="v-card__section">
          <span className="v-card__label">Certifications</span>

          <div className="v-card__tags">
            {certifications.length > 0 ? (
              certifications.map((certification) => (
                <span
                  key={certification}
                  className="v-card__tag v-card__tag--certification"
                >
                  {certification}
                </span>
              ))
            ) : (
              <span className="v-card__empty">No certifications</span>
            )}
          </div>
        </div>
      </div>

      <div className="v-card__metrics">
        <div className="v-card__metric">
          <span>Comfort Tier</span>

          <strong>{volunteer.comfortTier || "Not specified"}</strong>
        </div>

        <div className="v-card__metric">
          <span>Active Capacity</span>

          <strong className={atCapacity ? "v-card__capacity--full" : ""}>
            {activeAssignments} / {maximumAssignments || "N/A"}
          </strong>
        </div>

        <div className="v-card__metric v-card__metric--wide">
          <span>Availability Window</span>

          <strong>
            {formatAvailabilityWindow(
              volunteer.availabilityStartUtc,
              volunteer.availabilityEndUtc,
            )}
          </strong>
        </div>
      </div>
    </article>
  );
}
