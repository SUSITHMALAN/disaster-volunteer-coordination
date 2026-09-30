import { useEffect, useMemo, useState } from "react";

import { getVolunteers, updateAvailability } from "../api/volunteers";

import VolunteerCard from "./VolunteerCard";

import "./VolunteerList.css";

export default function VolunteerList() {
  const [volunteers, setVolunteers] = useState([]);

  const [skillFilter, setSkillFilter] = useState("");
  const [availabilityFilter, setAvailabilityFilter] = useState("all");
  const [certificationFilter, setCertificationFilter] = useState("all");
  const [comfortFilter, setComfortFilter] = useState("all");

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [updatingId, setUpdatingId] = useState(null);

  async function load() {
    setLoading(true);
    setError(null);

    try {
      const data = await getVolunteers();

      setVolunteers(data || []);
    } catch (err) {
      setError(err.message || "Failed to load volunteers.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function handleToggle(id, isAvailable) {
    if (updatingId) {
      return;
    }

    setUpdatingId(id);
    setError(null);

    try {
      await updateAvailability(id, isAvailable);

      setVolunteers((prev) =>
        prev.map((volunteer) =>
          volunteer.id === id
            ? {
                ...volunteer,
                isAvailable,
              }
            : volunteer,
        ),
      );
    } catch (err) {
      setError(err.message || "Couldn't update volunteer availability.");
    } finally {
      setUpdatingId(null);
    }
  }

  const certificationOptions = useMemo(() => {
    const certifications = volunteers.flatMap(
      (volunteer) => volunteer.certifications || [],
    );

    return [...new Set(certifications)].sort();
  }, [volunteers]);

  const comfortOptions = useMemo(() => {
    const tiers = volunteers
      .map((volunteer) => volunteer.comfortTier?.trim())
      .filter(Boolean);

    return [...new Set(tiers)].sort();
  }, [volunteers]);

  const filteredVolunteers = useMemo(() => {
    const skillText = skillFilter.trim().toLowerCase();

    return volunteers.filter((volunteer) => {
      const skills = volunteer.skills || [];

      const certifications = volunteer.certifications || [];

      const matchesSkill =
        !skillText ||
        skills.some((skill) => skill.toLowerCase().includes(skillText));

      const matchesAvailability =
        availabilityFilter === "all" ||
        (availabilityFilter === "available" && volunteer.isAvailable) ||
        (availabilityFilter === "unavailable" && !volunteer.isAvailable);

      const matchesCertification =
        certificationFilter === "all" ||
        certifications.includes(certificationFilter);

      const matchesComfort =
        comfortFilter === "all" || volunteer.comfortTier === comfortFilter;

      return (
        matchesSkill &&
        matchesAvailability &&
        matchesCertification &&
        matchesComfort
      );
    });
  }, [
    volunteers,
    skillFilter,
    availabilityFilter,
    certificationFilter,
    comfortFilter,
  ]);

  function handleClearFilters() {
    setSkillFilter("");
    setAvailabilityFilter("all");
    setCertificationFilter("all");
    setComfortFilter("all");
  }

  const hasFilters =
    skillFilter.trim() !== "" ||
    availabilityFilter !== "all" ||
    certificationFilter !== "all" ||
    comfortFilter !== "all";

  return (
    <div className="volunteer-list">
      <div className="volunteer-list__header">
        <div>
          <p className="volunteer-list__eyebrow">VOLUNTEER COORDINATION</p>

          <h1 className="volunteer-list__title">Volunteers</h1>

          <p className="volunteer-list__description">
            Review volunteer availability, skills, certifications and current
            workload.
          </p>
        </div>

        <div className="volunteer-list__count">
          <strong>{filteredVolunteers.length}</strong>

          <span>of {volunteers.length} shown</span>
        </div>
      </div>

      <div className="volunteer-list__filters">
        <label className="volunteer-list__field volunteer-list__field--wide">
          <span>Skill</span>

          <input
            type="text"
            placeholder="Search skill, e.g. first aid"
            value={skillFilter}
            onChange={(event) => setSkillFilter(event.target.value)}
          />
        </label>

        <label className="volunteer-list__field">
          <span>Availability</span>

          <select
            value={availabilityFilter}
            onChange={(event) => setAvailabilityFilter(event.target.value)}
          >
            <option value="all">All volunteers</option>

            <option value="available">Available</option>

            <option value="unavailable">Unavailable</option>
          </select>
        </label>

        <label className="volunteer-list__field">
          <span>Certification</span>

          <select
            value={certificationFilter}
            onChange={(event) => setCertificationFilter(event.target.value)}
          >
            <option value="all">All certifications</option>

            {certificationOptions.map((certification) => (
              <option key={certification} value={certification}>
                {certification}
              </option>
            ))}
          </select>
        </label>

        <label className="volunteer-list__field">
          <span>Comfort Tier</span>

          <select
            value={comfortFilter}
            onChange={(event) => setComfortFilter(event.target.value)}
          >
            <option value="all">All tiers</option>

            {comfortOptions.map((tier) => (
              <option key={tier} value={tier}>
                {tier}
              </option>
            ))}
          </select>
        </label>
      </div>

      {hasFilters && (
        <div className="volunteer-list__filter-actions">
          <span>
            Showing {filteredVolunteers.length} of {volunteers.length}{" "}
            volunteers
          </span>

          <button type="button" onClick={handleClearFilters}>
            Clear filters
          </button>
        </div>
      )}

      {loading && (
        <p className="volunteer-list__status">Loading volunteers...</p>
      )}

      {error && (
        <p className="volunteer-list__status volunteer-list__status--error">
          {error}
        </p>
      )}

      {!loading && !error && filteredVolunteers.length === 0 && (
        <p className="volunteer-list__status">
          No volunteers match the selected filters.
        </p>
      )}

      {!loading && !error && filteredVolunteers.length > 0 && (
        <div className="volunteer-list__rows">
          {filteredVolunteers.map((volunteer) => (
            <VolunteerCard
              key={volunteer.id}
              volunteer={volunteer}
              onToggleAvailability={handleToggle}
              isUpdating={updatingId === volunteer.id}
            />
          ))}
        </div>
      )}
    </div>
  );
}
