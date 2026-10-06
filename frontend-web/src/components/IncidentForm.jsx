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

const AVAILABLE_SKILLS = [
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

function formatSkill(skill) {
  return skill
    .split("-")
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

export default function IncidentForm() {
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [category, setCategory] = useState("Other");
  const [customCategory, setCustomCategory] = useState("");
  const [severity, setSeverity] = useState("Medium");
  const [zone, setZone] = useState("");
  const [address, setAddress] = useState("");
  const [selectedSkills, setSelectedSkills] = useState([]);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const navigate = useNavigate();

  function handleCategoryChange(e) {
    const selectedCategory = e.target.value;

    setCategory(selectedCategory);

    if (selectedCategory !== "Other") {
      setCustomCategory("");
    }
  }

  function toggleSkill(skill) {
    setSelectedSkills((currentSkills) =>
      currentSkills.includes(skill)
        ? currentSkills.filter((item) => item !== skill)
        : [...currentSkills, skill],
    );
  }

  async function handleSubmit(e) {
    e.preventDefault();

    setError(null);
    setSuccess("");

    if (category === "Other" && !customCategory.trim()) {
      setError("Please specify the incident category.");
      return;
    }

    setSubmitting(true);

    const rawReportText =
      category === "Other"
        ? `Custom category: ${customCategory.trim()}\n\n${description}`
        : description;

    try {
      await createIncident({
        title,
        description,
        category,
        severity,
        zone: zone || undefined,
        address: address || undefined,
        requiredSkills: selectedSkills,
        rawReportText,
      });

      setSuccess("Incident report submitted successfully.");

      setTimeout(() => {
        navigate("/incidents");
      }, 1500);
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
          <select value={category} onChange={handleCategoryChange}>
            {CATEGORIES.map((item) => (
              <option key={item} value={item}>
                {item}
              </option>
            ))}
          </select>
        </label>

        <label className="incident-form__label">
          Severity
          <select
            value={severity}
            onChange={(e) => setSeverity(e.target.value)}
          >
            {SEVERITIES.map((item) => (
              <option key={item} value={item}>
                {item}
              </option>
            ))}
          </select>
        </label>
      </div>

      {category === "Other" && (
        <label className="incident-form__label">
          Specify category
          <input
            type="text"
            value={customCategory}
            onChange={(e) => setCustomCategory(e.target.value)}
            placeholder="e.g. Road blockage, animal rescue"
            required
          />
        </label>
      )}

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

      <div className="incident-form__label">
        <span>Skills needed</span>

        <div className="incident-form__skills">
          {AVAILABLE_SKILLS.map((skill) => {
            const selected = selectedSkills.includes(skill);

            return (
              <button
                key={skill}
                type="button"
                className={`incident-form__skill ${
                  selected ? "incident-form__skill--selected" : ""
                }`}
                onClick={() => toggleSkill(skill)}
                aria-pressed={selected}
              >
                {selected ? "✓ " : ""}
                {formatSkill(skill)}
              </button>
            );
          })}
        </div>
      </div>

      {success && <p className="incident-form__success">✓ {success}</p>}

      {error && <p className="incident-form__error">{error}</p>}

      <button
        className="incident-form__submit"
        type="submit"
        disabled={submitting || !!success}
      >
        {success
          ? "Report submitted"
          : submitting
            ? "Submitting…"
            : "Submit report"}
      </button>
    </form>
  );
}
