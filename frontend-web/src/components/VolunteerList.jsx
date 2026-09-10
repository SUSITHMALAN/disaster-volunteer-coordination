import { useEffect, useState } from "react";
import { getVolunteers, updateAvailability } from "../api/volunteers";
import VolunteerCard from "./VolunteerCard";
import "./VolunteerList.css";

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
    <div className="volunteer-list">
      <div className="volunteer-list__header">
        <h1 className="volunteer-list__title">Volunteers</h1>
        <p className="volunteer-list__subtitle">
          {volunteers.length} registered
        </p>
      </div>

      <input
        type="text"
        className="volunteer-list__filter"
        placeholder="Filter by skill — e.g. first-aid"
        value={skillFilter}
        onChange={(e) => setSkillFilter(e.target.value)}
      />

      {loading && <p className="volunteer-list__status">Loading volunteers…</p>}
      {error && <p className="volunteer-list__status volunteer-list__status--error">{error}</p>}
      {!loading && !error && volunteers.length === 0 && (
        <p className="volunteer-list__status">
          No volunteers match this filter. Try a different skill.
        </p>
      )}

      <div className="volunteer-list__rows">
        {volunteers.map((v) => (
          <VolunteerCard key={v.id} volunteer={v} onToggleAvailability={handleToggle} />
        ))}
      </div>
    </div>
  );
}