import {
  BrowserRouter,
  Routes,
  Route,
  Navigate,
  Link,
  useLocation,
} from "react-router-dom";

import { useEffect, useState } from "react";

import { AuthProvider, useAuth } from "./context/AuthContext";

import Login from "./pages/Login";

import Register from "./pages/Register";

import Dashboard from "./pages/Dashboard";

import VolunteersPage from "./pages/VolunteersPage";

import MatchesPage from "./pages/MatchesPage.jsx";

import IncidentsPage from "./pages/IncidentsPage";

import ReportIncidentPage from "./pages/ReportIncidentPage";

import AssignmentsPage from "./pages/AssignmentsPage";

import ResourcesPage from "./pages/ResourcesPage";

import ResourceReportsPage from "./pages/ResourceReportsPage";

import "./App.css";

function ProtectedRoute({ children, allowedRoles }) {
  const { user } = useAuth();

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles && !allowedRoles.includes(user.role)) {
    return <Navigate to="/" replace />;
  }

  return children;
}

function NavigationHeader() {
  const { user, logout } = useAuth();

  const location = useLocation();

  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);

  const [theme, setTheme] = useState(() => {
    const savedTheme = localStorage.getItem("dvc-theme");

    if (savedTheme === "light" || savedTheme === "dark") {
      return savedTheme;
    }

    return window.matchMedia?.("(prefers-color-scheme: light)").matches
      ? "light"
      : "dark";
  });

  const isAuthPage =
    location.pathname === "/login" || location.pathname === "/register";

  useEffect(() => {
    setMobileMenuOpen(false);
  }, [location.pathname]);

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);

    localStorage.setItem("dvc-theme", theme);
  }, [theme]);

  function handleLogout() {
    setShowLogoutConfirm(true);
  }

  function confirmLogout() {
    setShowLogoutConfirm(false);

    setMobileMenuOpen(false);

    logout();
  }

  function cancelLogout() {
    setShowLogoutConfirm(false);
  }

  function toggleTheme() {
    setTheme((current) => (current === "dark" ? "light" : "dark"));
  }

  return (
    <>
      <header className="app-header">
        <div className="app-header__left">
          <Link to="/" className="app-header__brand" title="Go to Dashboard">
            <span className="app-header__mark">DVC</span>

            <span className="app-header__title">
              Disaster Volunteer Coordination
            </span>
          </Link>
        </div>

        {user && !isAuthPage && (
          <div className="app-header__center">
            <nav className="app-header__nav">
              <Link
                to="/"
                className={`app-header__nav-link ${
                  location.pathname === "/"
                    ? "app-header__nav-link--active"
                    : ""
                }`}
              >
                Dashboard
              </Link>

              {(user.role === "Coordinator" || user.role === "Admin") && (
                <>
                  <Link
                    to="/incidents"
                    className={`app-header__nav-link ${
                      location.pathname.startsWith("/incidents")
                        ? "app-header__nav-link--active"
                        : ""
                    }`}
                  >
                    Incidents
                  </Link>

                  <Link
                    to="/volunteers"
                    className={`app-header__nav-link ${
                      location.pathname === "/volunteers"
                        ? "app-header__nav-link--active"
                        : ""
                    }`}
                  >
                    Volunteers
                  </Link>

                  <Link
                    to="/matches"
                    className={`app-header__nav-link ${
                      location.pathname === "/matches"
                        ? "app-header__nav-link--active"
                        : ""
                    }`}
                  >
                    Matches
                  </Link>

                  <Link
                    to="/assignments"
                    className={`app-header__nav-link ${
                      location.pathname === "/assignments"
                        ? "app-header__nav-link--active"
                        : ""
                    }`}
                  >
                    Assignments
                  </Link>

                  <Link
                    to="/resources"
                    className={`app-header__nav-link ${
                      location.pathname === "/resources"
                        ? "app-header__nav-link--active"
                        : ""
                    }`}
                  >
                    Resources
                  </Link>

                  <Link
                    to="/reports"
                    className={`app-header__nav-link ${
                      location.pathname === "/reports"
                        ? "app-header__nav-link--active"
                        : ""
                    }`}
                  >
                    Reports
                  </Link>
                </>
              )}

              {user.role === "Requester" && (
                <Link
                  to="/incidents/new"
                  className={`app-header__nav-link ${
                    location.pathname === "/incidents/new"
                      ? "app-header__nav-link--active"
                      : ""
                  }`}
                >
                  Report Incident
                </Link>
              )}

              {user.role === "Volunteer" && (
                <Link
                  to="/volunteers"
                  className={`app-header__nav-link ${
                    location.pathname === "/volunteers"
                      ? "app-header__nav-link--active"
                      : ""
                  }`}
                >
                  My Profile
                </Link>
              )}
            </nav>
          </div>
        )}

        <div className="app-header__right">
          <button
            type="button"
            className="app-header__theme-btn"
            onClick={toggleTheme}
            title={
              theme === "dark" ? "Switch to light mode" : "Switch to dark mode"
            }
            aria-label={
              theme === "dark" ? "Switch to light mode" : "Switch to dark mode"
            }
          >
            {theme === "dark" ? (
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                aria-hidden="true"
              >
                <circle cx="12" cy="12" r="4" />

                <path d="M12 2v2" />

                <path d="M12 20v2" />

                <path d="m4.93 4.93 1.42 1.42" />

                <path d="m17.66 17.66 1.41 1.41" />

                <path d="M2 12h2" />

                <path d="M20 12h2" />

                <path d="m6.34 17.66-1.41 1.41" />

                <path d="m19.07 4.93-1.41 1.42" />
              </svg>
            ) : (
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                aria-hidden="true"
              >
                <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
              </svg>
            )}
          </button>

          {user && !isAuthPage && (
            <>
              <div className="app-header__user">
                <span className="app-header__user-name">{user.fullName}</span>

                <span className="app-header__user-role">{user.role}</span>
              </div>

              <button
                type="button"
                className="app-header__signout-btn"
                onClick={handleLogout}
                title="Sign out"
              >
                Sign out
              </button>

              <button
                type="button"
                className="app-header__menu-btn"
                onClick={() => setMobileMenuOpen((current) => !current)}
                aria-label="Toggle navigation menu"
                aria-expanded={mobileMenuOpen}
                aria-controls="mobile-navigation"
              >
                {mobileMenuOpen ? (
                  <svg
                    width="22"
                    height="22"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    aria-hidden="true"
                  >
                    <path d="M18 6L6 18M6 6l12 12" />
                  </svg>
                ) : (
                  <svg
                    width="22"
                    height="22"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    aria-hidden="true"
                  >
                    <path d="M4 6h16M4 12h16M4 18h16" />
                  </svg>
                )}
              </button>
            </>
          )}
        </div>
      </header>

      {user && !isAuthPage && mobileMenuOpen && (
        <nav id="mobile-navigation" className="mobile-nav">
          <div className="mobile-nav__user">
            <span className="mobile-nav__user-name">{user.fullName}</span>

            <span className="mobile-nav__user-role">{user.role}</span>
          </div>

          <Link
            to="/"
            className={`mobile-nav__link ${
              location.pathname === "/" ? "mobile-nav__link--active" : ""
            }`}
          >
            Dashboard
          </Link>

          {(user.role === "Coordinator" || user.role === "Admin") && (
            <>
              <Link
                to="/incidents"
                className={`mobile-nav__link ${
                  location.pathname.startsWith("/incidents")
                    ? "mobile-nav__link--active"
                    : ""
                }`}
              >
                Incidents
              </Link>

              <Link
                to="/volunteers"
                className={`mobile-nav__link ${
                  location.pathname === "/volunteers"
                    ? "mobile-nav__link--active"
                    : ""
                }`}
              >
                Volunteers
              </Link>

              <Link
                to="/matches"
                className={`mobile-nav__link ${
                  location.pathname === "/matches"
                    ? "mobile-nav__link--active"
                    : ""
                }`}
              >
                Matches
              </Link>

              <Link
                to="/assignments"
                className={`mobile-nav__link ${
                  location.pathname === "/assignments"
                    ? "mobile-nav__link--active"
                    : ""
                }`}
              >
                Assignments
              </Link>

              <Link
                to="/resources"
                className={`mobile-nav__link ${
                  location.pathname === "/resources"
                    ? "mobile-nav__link--active"
                    : ""
                }`}
              >
                Resources
              </Link>

              <Link
                to="/reports"
                className={`mobile-nav__link ${
                  location.pathname === "/reports"
                    ? "mobile-nav__link--active"
                    : ""
                }`}
              >
                Reports
              </Link>
            </>
          )}

          {user.role === "Requester" && (
            <Link
              to="/incidents/new"
              className={`mobile-nav__link ${
                location.pathname === "/incidents/new"
                  ? "mobile-nav__link--active"
                  : ""
              }`}
            >
              Report Incident
            </Link>
          )}

          {user.role === "Volunteer" && (
            <Link
              to="/volunteers"
              className={`mobile-nav__link ${
                location.pathname === "/volunteers"
                  ? "mobile-nav__link--active"
                  : ""
              }`}
            >
              My Profile
            </Link>
          )}

          <button
            type="button"
            className="mobile-nav__signout"
            onClick={handleLogout}
          >
            Sign out
          </button>
        </nav>
      )}

      {showLogoutConfirm && (
        <div className="logout-modal-backdrop" onClick={cancelLogout}>
          <div
            className="logout-modal"
            role="dialog"
            aria-modal="true"
            aria-labelledby="logout-confirm-title"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="logout-modal__icon">↪</div>

            <h2 id="logout-confirm-title">Sign out?</h2>

            <p>
              Are you sure you want to sign out of Disaster Volunteer
              Coordination?
            </p>

            <div className="logout-modal__actions">
              <button
                type="button"
                className="logout-modal__cancel"
                onClick={cancelLogout}
              >
                Cancel
              </button>

              <button
                type="button"
                className="logout-modal__confirm"
                onClick={confirmLogout}
              >
                Sign out
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

function AppRoutes() {
  const { user } = useAuth();

  return (
    <Routes>
      <Route
        path="/login"
        element={user ? <Navigate to="/" replace /> : <Login />}
      />

      <Route
        path="/register"
        element={user ? <Navigate to="/" replace /> : <Register />}
      />

      <Route
        path="/"
        element={
          <ProtectedRoute>
            <Dashboard />
          </ProtectedRoute>
        }
      />

      <Route
        path="/incidents"
        element={
          <ProtectedRoute allowedRoles={["Coordinator", "Admin"]}>
            <IncidentsPage />
          </ProtectedRoute>
        }
      />

      <Route
        path="/incidents/new"
        element={
          <ProtectedRoute allowedRoles={["Requester", "Coordinator", "Admin"]}>
            <ReportIncidentPage />
          </ProtectedRoute>
        }
      />

      <Route
        path="/matches"
        element={
          <ProtectedRoute allowedRoles={["Coordinator", "Admin"]}>
            <MatchesPage />
          </ProtectedRoute>
        }
      />

      <Route
        path="/assignments"
        element={
          <ProtectedRoute allowedRoles={["Coordinator", "Admin"]}>
            <AssignmentsPage />
          </ProtectedRoute>
        }
      />

      <Route
        path="/resources"
        element={
          <ProtectedRoute allowedRoles={["Coordinator", "Admin"]}>
            <ResourcesPage />
          </ProtectedRoute>
        }
      />

      <Route
        path="/reports"
        element={
          <ProtectedRoute allowedRoles={["Coordinator", "Admin"]}>
            <ResourceReportsPage />
          </ProtectedRoute>
        }
      />

      <Route
        path="/volunteers"
        element={
          <ProtectedRoute allowedRoles={["Coordinator", "Admin", "Volunteer"]}>
            <VolunteersPage />
          </ProtectedRoute>
        }
      />

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

function AppFooter() {
  const location = useLocation();

  const isAuthPage =
    location.pathname === "/login" || location.pathname === "/register";

  if (isAuthPage) {
    return null;
  }

  return (
    <footer className="app-footer">
      <div className="app-footer__brand">
        <span className="app-footer__mark">DVC</span>

        <span>Disaster Volunteer Coordination</span>
      </div>

      <div className="app-footer__meta">
        © {new Date().getFullYear()} SEF Project
      </div>
    </footer>
  );
}

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <div className="app-shell">
          <NavigationHeader />

          <AppRoutes />

          <AppFooter />
        </div>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
