import { useEffect, useState } from "react";
import { getVolunteers, updateAvailability } from "../api/volunteers";
import VolunteerCard from "./VolunteerCard";

export default function VolunteerList() {
  const [volunteers, setVolunteers] = useState([]);
  const [skillFilter, setSkillFilter] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  async function load() {
    setLoading(true);
    setError(null);
    try {
      const data = await getVolunteers({ skill: skillFilter || undefined });
      setVolunteers(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [skillFilter]);

  async function handleToggle(id, isAvailable) {
    await updateAvailability(id, isAvailable);
    setVolunteers((prev) =>
      prev.map((v) => (v.id === id ? { ...v, isAvailable } : v))
    );
  }

  return (
    <div style={{ maxWidth: "640px", margin: "0 auto", fontFamily: "system-ui, sans-serif" }}>
      <div style={{ padding: "20px 20px 12px" }}>
        <h1 style={{ fontSize: "22px", fontWeight: 700, color: "#1B2430", margin: 0 }}>
          Volunteers
        </h1>
        <input
          type="text"
          placeholder="Filter by skill (e.g. first-aid)"
          value={skillFilter}
          onChange={(e) => setSkillFilter(e.target.value)}
          style={{
            marginTop: "12px",
            width: "100%",
            padding: "8px 12px",
            border: "1px solid #D6D9DE",
            borderRadius: "6px",
            fontSize: "14px",
          }}
        />
      </div>

      {loading && <p style={{ padding: "0 20px", color: "#5B6472" }}>Loading volunteers…</p>}
      {error && <p style={{ padding: "0 20px", color: "#B3413E" }}>{error}</p>}
      {!loading && !error && volunteers.length === 0 && (
        <p style={{ padding: "0 20px", color: "#5B6472" }}>
          No volunteers match this filter yet.
        </p>
      )}

      <div style={{ border: "1px solid #E2E5E9", borderTop: "none" }}>
        {volunteers.map((v) => (
          <VolunteerCard key={v.id} volunteer={v} onToggleAvailability={handleToggle} />
        ))}
      </div>
    </div>
  );
}