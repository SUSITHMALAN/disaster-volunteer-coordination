import { useAuth } from "../context/AuthContext";
import "./Dashboard.css";

const ROLE_LINKS = {
  Requester: [{ label: "Report an incident", to: "/incidents/new" }],
  Volunteer: [{ label: "My profile & availability", to: "/volunteers" }],
  Coordinator: [
    { label: "Incidents", to: "/incidents" },
    { label: "Volunteers", to: "/volunteers" },
    { label: "Approval queue", to: "/approvals" },
  ],
  Admin: [
    { label: "Incidents", to: "/incidents" },
    { label: "Volunteers", to: "/volunteers" },
    { label: "Approval queue", to: "/approvals" },
  ],
};

export default function Dashboard() {
  const { user, logout } = useAuth();
  const links = ROLE_LINKS[user?.role] || [];

  return (
    <div className="dashboard">
      <div className="dashboard__welcome">
        <h1 className="dashboard__title">Welcome, {user?.fullName}</h1>
        <p className="dashboard__role">Signed in as {user?.role}</p>
      </div>

      <div className="dashboard__links">
        {links.map((link) => (
          <a key={link.to} className="dashboard__link" href={link.to}>
            {link.label}
          </a>
        ))}
      </div>

      <button className="dashboard__logout" onClick={logout}>
        Sign out
      </button>
    </div>
  );
}