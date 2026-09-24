import { BrowserRouter, Routes, Route, Navigate, Link, useLocation, useNavigate } from "react-router-dom";
import { AuthProvider, useAuth } from "./context/AuthContext";
import Login from "./pages/Login";
import Register from "./pages/Register";
import Dashboard from "./pages/Dashboard";
import VolunteersPage from "./pages/VolunteersPage";
import MatchesPage from "./pages/MatchesPage.jsx";
import IncidentsPage from "./pages/IncidentsPage";
import ReportIncidentPage from "./pages/ReportIncidentPage";
import "./App.css";

function ProtectedRoute({ children }) {
  const { user } = useAuth();
  return user ? children : <Navigate to="/login" replace />;
}

function NavigationHeader() {
  const { user, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  const isAuthPage = location.pathname === "/login" || location.pathname === "/register";
  const isDashboard = location.pathname === "/";

  return (
    <header className="app-header">
      <div className="app-header__left">
        <Link to="/" className="app-header__brand" title="Go to Dashboard">
          <span className="app-header__mark">DVC</span>
          <span className="app-header__title">Disaster Volunteer Coordination</span>
        </Link>
      </div>

      {user && !isAuthPage && (
        <div className="app-header__center">
          {!isDashboard && (
            <button
              type="button"
              className="app-header__back-btn"
              onClick={() => {
                if (window.history.state && window.history.state.idx > 0) {
                  navigate(-1);
                } else {
                  navigate("/");
                }
              }}
              title="Go back to previous page"
            >
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <path d="M19 12H5M12 19l-7-7 7-7" />
              </svg>
              <span>Back</span>
            </button>
          )}

          <nav className="app-header__nav">
            <Link
              to="/"
              className={`app-header__nav-link ${location.pathname === "/" ? "app-header__nav-link--active" : ""}`}
            >
              Dashboard
            </Link>
            {(user.role === "Coordinator" || user.role === "Admin") && (
              <>
                <Link
                  to="/incidents"
                  className={`app-header__nav-link ${location.pathname.startsWith("/incidents") ? "app-header__nav-link--active" : ""}`}
                >
                  Incidents
                </Link>
                <Link
                  to="/volunteers"
                  className={`app-header__nav-link ${location.pathname === "/volunteers" ? "app-header__nav-link--active" : ""}`}
                >
                  Volunteers
                </Link>
                <Link
                  to="/matches"
                  className={`app-header__nav-link ${location.pathname === "/matches" ? "app-header__nav-link--active" : ""}`}
                >
                  Matches
                </Link>
              </>
            )}
            {user.role === "Requester" && (
              <Link
                to="/incidents/new"
                className={`app-header__nav-link ${location.pathname === "/incidents/new" ? "app-header__nav-link--active" : ""}`}
              >
                Report Incident
              </Link>
            )}
            {user.role === "Volunteer" && (
              <Link
                to="/volunteers"
                className={`app-header__nav-link ${location.pathname === "/volunteers" ? "app-header__nav-link--active" : ""}`}
              >
                My Profile
              </Link>
            )}
          </nav>
        </div>
      )}

      {user && !isAuthPage && (
        <div className="app-header__right">
          <div className="app-header__user">
            <span className="app-header__user-name">{user.fullName}</span>
            <span className="app-header__user-role">{user.role}</span>
          </div>
          <button className="app-header__signout-btn" onClick={logout} title="Sign out">
            Sign out
          </button>
        </div>
      )}
    </header>
  );
}

function AppRoutes() {
  const { user } = useAuth();

  return (
    <Routes>
      <Route path="/login" element={user ? <Navigate to="/" replace /> : <Login />} />
      <Route path="/register" element={user ? <Navigate to="/" replace /> : <Register />} />
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <Dashboard />
          </ProtectedRoute>
        }
      />
      <Route
        path="/matches"
        element={
          <ProtectedRoute>
            <MatchesPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/volunteers"
        element={
          <ProtectedRoute>
            <VolunteersPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/incidents"
        element={
          <ProtectedRoute>
            <IncidentsPage />
          </ProtectedRoute>
        }
      />
      <Route
        path="/incidents/new"
        element={
          <ProtectedRoute>
            <ReportIncidentPage />
          </ProtectedRoute>
        }
      />
      {/* Fallback to Dashboard for any other route */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <div className="app-shell">
          <NavigationHeader />
          <AppRoutes />
        </div>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
