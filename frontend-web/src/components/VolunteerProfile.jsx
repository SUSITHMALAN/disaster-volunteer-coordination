import { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { getVolunteerProfile, updateVolunteerProfile, updateAvailability } from "../api/volunteers";
import { apiFetch } from "../api/client";
import "./VolunteerProfile.css";

const POPULAR_SKILLS = [
  "first-aid",
  "cpr",
  "boat-operation",
  "search-and-rescue",
  "heavy-lifting",
  "driving",
  "medical",
  "electrical-repair",
  "food-prep",
  "triage",
  "logistics",
  "generator-handling",
  "swimming",
  "child-care",
];

export default function VolunteerProfile() {
  const { user } = useAuth();
  const [profile, setProfile] = useState(null);
  const [skills, setSkills] = useState([]);
  const [newSkillInput, setNewSkillInput] = useState("");
  const [isAvailable, setIsAvailable] = useState(true);
  const [assignments, setAssignments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [saveMessage, setSaveMessage] = useState(null);

  useEffect(() => {
    async function load() {
      if (!user?.userId) return;
      setLoading(true);
      setError(null);
      try {
        const data = await getVolunteerProfile(user.userId);
        setProfile(data);
        setSkills(data.skills || []);
        setIsAvailable(data.isAvailable ?? true);

        // Fetch volunteer assignments history
        try {
          const assignData = await apiFetch(`/api/assignments/history?volunteerId=${user.userId}`);
          setAssignments(assignData || []);
        } catch {
          // Non-blocking
        }
      } catch (err) {
        setError(err.message || "Could not load volunteer profile.");
      } finally {
        setLoading(false);
      }
    }
    load();
  }, [user?.userId]);

  async function handleToggleAvailability() {
    const nextVal = !isAvailable;
    setIsAvailable(nextVal);
    try {
      await updateAvailability(user.userId, nextVal);
      setProfile((prev) => (prev ? { ...prev, isAvailable: nextVal } : prev));
      setSaveMessage(`Availability updated to: ${nextVal ? "Available" : "Unavailable"}`);
      setTimeout(() => setSaveMessage(null), 3000);
    } catch (err) {
      setIsAvailable(!nextVal); // Revert
      setError("Failed to update availability status.");
    }
  }

  function handleAddSkill(skillToAdd) {
    const clean = (skillToAdd || newSkillInput).trim().toLowerCase();
    if (!clean) return;
    if (!skills.includes(clean)) {
      setSkills([...skills, clean]);
    }
    setNewSkillInput("");
  }

  function handleRemoveSkill(skillToRemove) {
    setSkills(skills.filter((s) => s !== skillToRemove));
  }

  async function handleSaveProfile(e) {
    e?.preventDefault();
    setSaving(true);
    setError(null);
    setSaveMessage(null);
    try {
      await updateVolunteerProfile(user.userId, {
        skills,
        isAvailable,
      });
      setProfile((prev) => (prev ? { ...prev, skills, isAvailable } : prev));
      setSaveMessage("Profile & skills saved successfully!");
      setTimeout(() => setSaveMessage(null), 4000);
    } catch (err) {
      setError(err.message || "Failed to save profile changes.");
    } finally {
      setSaving(false);
    }
  }

  if (loading) {
    return (
      <div className="volunteer-profile-loading">
        <div className="volunteer-profile-spinner"></div>
        <p>Loading your volunteer profile…</p>
      </div>
    );
  }

  if (error && !profile) {
    return (
      <div className="volunteer-profile-error">
        <p>⚠️ {error}</p>
        <button onClick={() => window.location.reload()}>Retry</button>
      </div>
    );
  }

  return (
    <div className="v-profile">
      {/* ── Top Header Banner ── */}
      <div className="v-profile__header">
        <div className="v-profile__avatar">
          {user?.fullName?.charAt(0)?.toUpperCase() || "V"}
        </div>
        <div className="v-profile__intro">
          <div className="v-profile__badges">
            <span className="v-profile__role-tag">{user?.role || "Volunteer"}</span>
            <span className={`v-profile__status-tag ${isAvailable ? "v-profile__status-tag--avail" : "v-profile__status-tag--busy"}`}>
              {isAvailable ? "● Available for Dispatch" : "○ Currently Unavailable"}
            </span>
          </div>
          <h1 className="v-profile__name">{profile?.fullName || user?.fullName}</h1>
          <p className="v-profile__email">{profile?.email || user?.email}</p>
        </div>

        {/* Availability Toggle Button */}
        <div className="v-profile__header-action">
          <button
            type="button"
            className={`v-profile__avail-btn ${isAvailable ? "v-profile__avail-btn--active" : ""}`}
            onClick={handleToggleAvailability}
            title="Click to toggle availability"
          >
            <span className="v-profile__avail-btn-icon">{isAvailable ? "✓" : "⏸"}</span>
            <span>{isAvailable ? "Set as Unavailable" : "Set as Available"}</span>
          </button>
        </div>
      </div>

      {saveMessage && (
        <div className="v-profile__toast v-profile__toast--success">
          ✓ {saveMessage}
        </div>
      )}

      {error && (
        <div className="v-profile__toast v-profile__toast--error">
          ⚠️ {error}
        </div>
      )}

      <div className="v-profile__grid">
        {/* ── Left Column: Skills Management ── */}
        <div className="v-profile__card v-profile__card--skills">
          <div className="v-profile__card-header">
            <h2>🛠️ My Skills & Specializations</h2>
            <span className="v-profile__counter">{skills.length} registered</span>
          </div>
          <p className="v-profile__card-desc">
            Add your disaster relief capabilities. The matching agent uses these to propose assignments for you.
          </p>

          {/* Active Skills Pills */}
          <div className="v-profile__skills-list">
            {skills.length === 0 ? (
              <p className="v-profile__no-skills">No skills added yet. Add your skills below.</p>
            ) : (
              skills.map((skill) => (
                <span key={skill} className="v-profile__skill-pill">
                  {skill}
                  <button
                    type="button"
                    className="v-profile__skill-remove"
                    onClick={() => handleRemoveSkill(skill)}
                    title={`Remove ${skill}`}
                  >
                    ×
                  </button>
                </span>
              ))
            )}
          </div>

          {/* Add Custom Skill Form */}
          <form
            className="v-profile__skill-form"
            onSubmit={(e) => {
              e.preventDefault();
              handleAddSkill();
            }}
          >
            <input
              type="text"
              placeholder="Add skill (e.g. drone-survey, first-aid)"
              value={newSkillInput}
              onChange={(e) => setNewSkillInput(e.target.value)}
            />
            <button type="submit" disabled={!newSkillInput.trim()}>
              + Add Skill
            </button>
          </form>

          {/* Quick-Select Suggestions */}
          <div className="v-profile__suggestions">
            <span className="v-profile__suggestions-label">Suggested skills:</span>
            <div className="v-profile__suggestion-pills">
              {POPULAR_SKILLS.filter((s) => !skills.includes(s)).map((skill) => (
                <button
                  key={skill}
                  type="button"
                  className="v-profile__suggestion-chip"
                  onClick={() => handleAddSkill(skill)}
                >
                  + {skill}
                </button>
              ))}
            </div>
          </div>

          <div className="v-profile__card-footer">
            <button
              type="button"
              className="v-profile__save-btn"
              onClick={handleSaveProfile}
              disabled={saving}
            >
              {saving ? "Saving Changes…" : "Save Skills & Changes"}
            </button>
          </div>
        </div>

        {/* ── Right Column: Safety & Capacity Overview ── */}
        <div className="v-profile__side-cards">
          {/* Safety & Comfort Tier */}
          <div className="v-profile__card">
            <div className="v-profile__card-header">
              <h2>🛡️ Safety & Comfort Tier</h2>
            </div>
            <div className="v-profile__meta-row">
              <span className="v-profile__meta-label">Comfort Tier</span>
              <span className="v-profile__tier-badge">
                {profile?.comfortTier || "Standard"}
              </span>
            </div>
            <div className="v-profile__meta-row">
              <span className="v-profile__meta-label">Max Active Assignments</span>
              <span className="v-profile__meta-val">
                {profile?.maximumActiveAssignments ?? 1} incident(s)
              </span>
            </div>
            <div className="v-profile__meta-row">
              <span className="v-profile__meta-label">Active Deployments</span>
              <span className="v-profile__meta-val v-profile__meta-val--highlight">
                {profile?.activeAssignments ?? assignments.length} active
              </span>
            </div>

            {profile?.certifications?.length > 0 && (
              <div className="v-profile__certs">
                <span className="v-profile__meta-label">Certifications</span>
                <ul className="v-profile__certs-list">
                  {profile.certifications.map((c) => (
                    <li key={c}>🏅 {c}</li>
                  ))}
                </ul>
              </div>
            )}
          </div>

          {/* Assigned Emergencies History */}
          <div className="v-profile__card">
            <div className="v-profile__card-header">
              <h2>📋 My Assigned Tasks</h2>
              <span className="v-profile__counter">{assignments.length}</span>
            </div>

            {assignments.length === 0 ? (
              <p className="v-profile__no-tasks">
                No active emergency assignments right now. You will be notified when matched.
              </p>
            ) : (
              <div className="v-profile__assignments-list">
                {assignments.map((a) => (
                  <div key={a.id} className="v-profile__assignment-item">
                    <div className="v-profile__assignment-header">
                      <span className="v-profile__assignment-title">
                        {a.incidentTitle || "Emergency Incident"}
                      </span>
                      <span className={`v-profile__assignment-badge v-profile__assignment-badge--${a.status?.toLowerCase()}`}>
                        {a.status}
                      </span>
                    </div>
                    <div className="v-profile__assignment-meta">
                      <span>⏱ Est: {a.estimatedDurationMinutes || 120} mins</span>
                      <span>Assigned: {new Date(a.assignedAtUtc).toLocaleDateString()}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
