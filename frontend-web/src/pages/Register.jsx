import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import BackButton from "../components/BackButton";
import "./AuthForm.css";

const ROLES = ["Requester", "Volunteer", "Coordinator", "Admin"];

export default function Register() {
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [role, setRole] = useState("Requester");
  const [skillsInput, setSkillsInput] = useState("");
  const [error, setError] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const { register } = useAuth();
  const navigate = useNavigate();

  async function handleSubmit(e) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    const parsedSkills = role === "Volunteer"
      ? skillsInput.split(",").map((s) => s.trim().toLowerCase()).filter(Boolean)
      : [];

    try {
      await register({ fullName, email, password, role, skills: parsedSkills });
      navigate("/");
    } catch (err) {
      setError("Couldn't create your account. That email may already be registered.");
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="auth-page">
      <form className="auth-form" onSubmit={handleSubmit}>
        <BackButton to="/login" label="Back to Sign in" className="dvc-back-btn--compact" style={{ alignSelf: "flex-start", marginBottom: "8px" }} />
        <h1 className="auth-form__title">Join the mission</h1>
        <p className="auth-form__subtitle">Create your account to start coordinating</p>

        <label className="auth-form__label">
          Full name
          <input
            type="text"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            placeholder="Jane Doe"
            required
          />
        </label>

        <label className="auth-form__label">
          Email
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            required
          />
        </label>

        <label className="auth-form__label">
          Password
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Min. 8 characters"
            required
            minLength={8}
          />
        </label>

        <label className="auth-form__label">
          I am a
          <select value={role} onChange={(e) => setRole(e.target.value)}>
            {ROLES.map((r) => (
              <option key={r} value={r}>{r}</option>
            ))}
          </select>
        </label>

        {role === "Volunteer" && (
          <label className="auth-form__label">
            Your Skills (optional, comma-separated)
            <input
              type="text"
              value={skillsInput}
              onChange={(e) => setSkillsInput(e.target.value)}
              placeholder="e.g. first-aid, driving, cpr, boat-operation"
            />
          </label>
        )}

        {error && <p className="auth-form__error">{error}</p>}

        <button className="auth-form__submit" type="submit" disabled={submitting}>
          {submitting ? "Creating account…" : "Create account"}
        </button>

        <p className="auth-form__switch">
          Already have an account? <Link to="/login">Sign in</Link>
        </p>
      </form>
    </div>
  );
}