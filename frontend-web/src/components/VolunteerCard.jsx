import "./VolunteerCard.css";

export default function VolunteerCard({ volunteer, onToggleAvailability }) {
  const isAvailable = volunteer.isAvailable;

  return (
    <div className={`v-card${isAvailable ? " v-card--available" : ""}`}>
      <div className="v-card__info">
        <div className="v-card__name">{volunteer.fullName}</div>
        <div className="v-card__skills">
          {volunteer.skills.length > 0 ? (
            volunteer.skills.map((skill) => (
              <span key={skill} className="v-card__skill-tag">{skill}</span>
            ))
          ) : (
            <span className="v-card__no-skills">No skills listed</span>
          )}
        </div>
      </div>

      <button
        className={`v-card__toggle ${isAvailable ? "v-card__toggle--available" : "v-card__toggle--unavailable"}`}
        onClick={() => onToggleAvailability(volunteer.id, !isAvailable)}
      >
        {isAvailable ? "✓ Available" : "Unavailable"}
      </button>
    </div>
  );
}