import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { createIncident } from "../api/incidents";
import "./IncidentForm.css";

const CATEGORIES = [
  "Flood",
  "Landslide",
  "PowerOutage",
  "MedicalEmergency",
  "StructuralDamage",
  "Other",
];

const SEVERITIES = ["Low", "Medium", "High", "Critical"];

export default function IncidentForm() {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState("Other");
  const [severity, setSeverity] = useState("Medium");
  const [zone, setZone] = useState("");
  const [address, setAddress] = useState("");
  const [skillsInput, setSkillsInput] = useState("");
  const [error, setError] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const navigate = useNavigate();

  async function handleSubmit(e) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);

    const requiredSkills = skillsInput
      .split(",")
      .map((s) => s.trim())
      .filter(Boolean);

    try {
      await createIncident({
        title,
        description,
        category,
        severity,
        zone: zone || undefined,
        address: address || undefined,
        requiredSkills,
        rawReportText: description,
      });
      navigate("/incidents");
    } catch (err) {
      setError(err.message || "Couldn't submit the report. Please try again.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form className="incident-form" onSubmit={handleSubmit}>
      <h1 className="incident-form__title">Report an incident</h1>
      <p className="incident-form__subtitle">
        Tell us what's happening — a coordinator will triage it shortly.
      </p>

      <label className="incident-form__label">
        Title
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="e.g. Flooded street near main road"
          required
        />
      </label>

      <label className="incident-form__label">
        Description
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Describe what's happening, who's affected, and what help is needed"
          rows={4}
          required
        />
      </label>

      <div className="incident-form__row">
        <label className="incident-form__label">
          Category
          <select value={category} onChange={(e) => setCategory(e.target.value)}>
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
        </label>

        <label className="incident-form__label">
          Severity
          <select value={severity} onChange={(e) => setSeverity(e.target.value)}>
            {SEVERITIES.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
        </label>
      </div>

      <div className="incident-form__row">
        <label className="incident-form__label">
          Zone
          <input
            type="text"
            value={zone}
            onChange={(e) => setZone(e.target.value)}
            placeholder="e.g. Colombo"
          />
        </label>

        <label className="incident-form__label">
          Address
          <input
            type="text"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            placeholder="e.g. Main St"
          />
        </label>
      </div>

      <label className="incident-form__label">
        Skills needed
        <input
          type="text"
          value={skillsInput}
          onChange={(e) => setSkillsInput(e.target.value)}
          placeholder="Comma-separated, e.g. boat, first-aid"
        />
      </label>

      {error && <p className="incident-form__error">{error}</p>}

      <button className="incident-form__submit" type="submit" disabled={submitting}>
        {submitting ? "Submitting…" : "Submit report"}
      </button>
    </form>
  );
}
