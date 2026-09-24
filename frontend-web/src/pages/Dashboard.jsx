import { useAuth } from "../context/AuthContext";
import { Link } from "react-router-dom";
import "./Dashboard.css";

const ICON_MAP = {
  "Report an incident": { emoji: "🚨", cls: "incidents" },
  "Incidents": { emoji: "⚠️", cls: "incidents" },
  "My profile & availability": { emoji: "👤", cls: "profile" },
  "Volunteers": { emoji: "🙋", cls: "volunteers" },
  "Matches": { emoji: "🤝", cls: "matches" },
  "Approval queue": { emoji: "✅", cls: "approvals" },
};

const ROLE_LINKS = {
  Requester: [{ label: "Report an incident", to: "/incidents/new" }],
  Volunteer: [{ label: "My profile & availability", to: "/volunteers" }],
  Coordinator: [
    { label: "Incidents", to: "/incidents" },
    { label: "Volunteers", to: "/volunteers" },
    { label: "Matches", to: "/matches" },
  ],
  Admin: [
    { label: "Incidents", to: "/incidents" },
    { label: "Volunteers", to: "/volunteers" },
    { label: "Matches", to: "/matches" },
  ],
};

export default function Dashboard() {
  const { user, logout } = useAuth();
  const links = ROLE_LINKS[user?.role] || [];

  return (
    <div className="dashboard">
      <div className="dashboard__welcome">
        <p className="dashboard__greeting">Welcome back</p>
        <h1 className="dashboard__title">{user?.fullName}</h1>
        <p className="dashboard__role">
          <span className="dashboard__role-dot"></span>
          {user?.role}
        </p>
      </div>

      <p className="dashboard__section-label">Quick actions</p>
      <div className="dashboard__links">
        {links.map((link) => {
          const icon = ICON_MAP[link.label] || { emoji: "📋", cls: "incidents" };
          return (
            <Link key={link.to} className="dashboard__link" to={link.to}>
              <span className={`dashboard__link-icon dashboard__link-icon--${icon.cls}`}>
                {icon.emoji}
              </span>
              <span className="dashboard__link-text">{link.label}</span>
            </Link>
          );
        })}
      </div>

      <button className="dashboard__logout" onClick={logout}>
        Sign out
      </button>
    </div>
  );
}