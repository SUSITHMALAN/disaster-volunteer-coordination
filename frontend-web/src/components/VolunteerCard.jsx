export default function VolunteerCard({ volunteer, onToggleAvailability }) {
  return (
    <div
      style={{
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        padding: "16px 20px",
        borderBottom: "1px solid #E2E5E9",
        background: "#FFFFFF",
      }}
    >
      <div>
        <div style={{ fontWeight: 600, color: "#1B2430", fontSize: "15px" }}>
          {volunteer.fullName}
        </div>
        <div style={{ color: "#5B6472", fontSize: "13px", marginTop: "2px" }}>
          {volunteer.skills.length > 0 ? volunteer.skills.join(", ") : "No skills listed"}
        </div>
      </div>

      <button
        onClick={() => onToggleAvailability(volunteer.id, !volunteer.isAvailable)}
        style={{
          padding: "6px 14px",
          borderRadius: "6px",
          border: "none",
          fontSize: "13px",
          fontWeight: 600,
          cursor: "pointer",
          background: volunteer.isAvailable ? "#2F6B4F" : "#8A8F98",
          color: "#FFFFFF",
        }}
      >
        {volunteer.isAvailable ? "Available" : "Unavailable"}
      </button>
    </div>
  );
}