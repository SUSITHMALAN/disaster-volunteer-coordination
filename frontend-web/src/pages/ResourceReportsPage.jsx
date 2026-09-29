import { useEffect, useState } from "react";

import {
  getResourceSummary,
  getResourceShortages,
  getResourcesByIncident,
  getVolunteerLoad,
  getIncidentStatistics,
} from "../api/reports";
import "./ResourceReportsPage.css";

const CATEGORY_LABELS = {
  0: "Medical",
  1: "Food & Water",
  2: "Shelter",
  3: "Equipment",
  4: "Personnel",
  5: "Other",
};

export default function ResourceReportsPage() {
  const [summary, setSummary] = useState([]);
  const [shortages, setShortages] = useState(null);
  const [byIncident, setByIncident] = useState([]);
  const [volunteerLoad, setVolunteerLoad] = useState(null);
  const [incidentStats, setIncidentStats] = useState(null);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [activeTab, setActiveTab] = useState("summary");

  async function fetchReportData() {
    setError("");
    try {
      const [sumData, shortData, incData, volLoadData, incStatsData] = await Promise.all([
        getResourceSummary().catch(() => []),
        getResourceShortages().catch(() => null),
        getResourcesByIncident().catch(() => []),
        getVolunteerLoad().catch(() => null),
        getIncidentStatistics().catch(() => null),
      ]);

      setSummary(sumData || []);
      setShortages(shortData);
      setByIncident(incData || []);
      setVolunteerLoad(volLoadData);
      setIncidentStats(incStatsData);
    } catch (err) {
      setError(err.message || "Failed to load reporting data.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    (async () => {
      setError("");
      try {
        const [sumData, shortData, incData, volLoadData, incStatsData] = await Promise.all([
          getResourceSummary().catch(() => []),
          getResourceShortages().catch(() => null),
          getResourcesByIncident().catch(() => []),
          getVolunteerLoad().catch(() => null),
          getIncidentStatistics().catch(() => null),
        ]);

        setSummary(sumData || []);
        setShortages(shortData);
        setByIncident(incData || []);
        setVolunteerLoad(volLoadData);
        setIncidentStats(incStatsData);
      } catch (err) {
        setError(err.message || "Failed to load reporting data.");
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  function handleRefresh() {
    setLoading(true);
    fetchReportData();
  }

  return (
    <div className="reports-page">

      <div className="reports-page__header">
        <div>
          <p className="reports-page__eyebrow">ANALYTICS & INTELLIGENCE</p>
          <h1 className="reports-page__title">Resource & Coordination Reports</h1>
          <p className="reports-page__subtitle">
            System-wide statistics on supply shortages, volunteer load, and incident allocations.
          </p>
        </div>

        <button
          type="button"
          className="reports-page__refresh"
          onClick={handleRefresh}
          disabled={loading}
        >
          {loading ? "Refreshing..." : "Refresh Analytics"}
        </button>
      </div>

      {error && <div className="reports-page__error" role="alert">{error}</div>}

      <div className="reports-tabs">
        <button
          type="button"
          className={`tab-btn ${activeTab === "summary" ? "tab-btn--active" : ""}`}
          onClick={() => setActiveTab("summary")}
        >
          Supply Summary
        </button>
        <button
          type="button"
          className={`tab-btn ${activeTab === "shortages" ? "tab-btn--active" : ""}`}
          onClick={() => setActiveTab("shortages")}
        >
          Critical Shortages ({shortages?.totalShortageCount || 0})
        </button>
        <button
          type="button"
          className={`tab-btn ${activeTab === "incidents" ? "tab-btn--active" : ""}`}
          onClick={() => setActiveTab("incidents")}
        >
          By Incident
        </button>
        <button
          type="button"
          className={`tab-btn ${activeTab === "workload" ? "tab-btn--active" : ""}`}
          onClick={() => setActiveTab("workload")}
        >
          Volunteer & Incident Load
        </button>
      </div>

      {loading ? (
        <div className="reports-page__state">Gathering system reports...</div>
      ) : (
        <div className="reports-content">
          {/* TAB 1: SUMMARY */}
          {activeTab === "summary" && (
            <div className="tab-pane">
              <h2 className="pane-title">Category-wise Resource Allocation</h2>
              {summary.length === 0 ? (
                <div className="empty-state">No summary data available.</div>
              ) : (
                <div className="summary-grid">
                  {summary.map((cat, idx) => (
                    <div key={idx} className="summary-card">
                      <div className="summary-card__header">
                        <h3>{CATEGORY_LABELS[cat.category] || `Category ${cat.category}`}</h3>
                        <span className="summary-card__count">{cat.totalItems} Items</span>
                      </div>
                      <div className="summary-card__metrics">
                        <div>
                          <span>Required</span>
                          <strong>{cat.totalRequired}</strong>
                        </div>
                        <div>
                          <span>Available</span>
                          <strong>{cat.totalAvailable}</strong>
                        </div>
                        <div className={cat.totalShortage > 0 ? "text-danger" : ""}>
                          <span>Shortage</span>
                          <strong>{cat.totalShortage}</strong>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* TAB 2: CRITICAL SHORTAGES */}
          {activeTab === "shortages" && (
            <div className="tab-pane">
              <h2 className="pane-title">Active Resource Shortage Alerts</h2>
              {!shortages || !shortages.items || shortages.items.length === 0 ? (
                <div className="empty-state empty-state--success">
                  🎉 No critical resource shortages reported!
                </div>
              ) : (
                <div className="shortage-table-wrapper">
                  <table className="report-table">
                    <thead>
                      <tr>
                        <th>Item Name</th>
                        <th>Category</th>
                        <th>Required</th>
                        <th>Available</th>
                        <th>Shortage</th>
                        <th>Unit</th>
                        <th>Priority</th>
                      </tr>
                    </thead>
                    <tbody>
                      {shortages.items.map((item) => (
                        <tr key={item.resourceId}>
                          <td><strong>{item.itemName}</strong></td>
                          <td>{CATEGORY_LABELS[item.category] || item.category}</td>
                          <td>{item.quantityRequired}</td>
                          <td>{item.quantityAvailable}</td>
                          <td className="text-danger"><strong>+{item.shortageQuantity}</strong></td>
                          <td>{item.unit}</td>
                          <td>
                            <span className={`badge priority-${item.priority}`}>
                              {item.priority === 3 ? "Critical" : item.priority === 2 ? "High" : "Medium"}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* TAB 3: BY INCIDENT */}
          {activeTab === "incidents" && (
            <div className="tab-pane">
              <h2 className="pane-title">Incident Resource Allocation Breakdown</h2>
              {byIncident.length === 0 ? (
                <div className="empty-state">No incident breakdowns reported.</div>
              ) : (
                <div className="incident-breakdown-list">
                  {byIncident.map((inc) => (
                    <div key={inc.incidentId} className="incident-report-card">
                      <div className="incident-report-card__header">
                        <h3>Incident #{inc.incidentId.substring(0, 8)}</h3>
                        <span>{inc.resources?.length || 0} Resource lines</span>
                      </div>
                      <div className="incident-report-card__body">
                        {inc.resources && inc.resources.map((res) => (
                          <div key={res.id} className="resource-mini-row">
                            <span>{res.itemName}</span>
                            <span>{res.quantityAvailable} / {res.quantityRequired} {res.unit}</span>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* TAB 4: VOLUNTEER & INCIDENT LOAD */}
          {activeTab === "workload" && (
            <div className="tab-pane">
              <h2 className="pane-title">System Operational Metrics</h2>
              <div className="metrics-row">
                {volunteerLoad && (
                  <div className="metric-box">
                    <h3>Volunteer Workforce Load</h3>
                    <ul>
                      <li><span>Total Active Volunteers:</span> <strong>{volunteerLoad.totalVolunteers ?? "N/A"}</strong></li>
                      <li><span>Assigned / On-Duty:</span> <strong>{volunteerLoad.assignedVolunteers ?? "N/A"}</strong></li>
                      <li><span>Available Capacity:</span> <strong>{volunteerLoad.availableVolunteers ?? "N/A"}</strong></li>
                    </ul>
                  </div>
                )}
                {incidentStats && (
                  <div className="metric-box">
                    <h3>Incident Overview</h3>
                    <ul>
                      <li><span>Total Incidents:</span> <strong>{incidentStats.totalIncidents ?? "N/A"}</strong></li>
                      <li><span>Active / Open:</span> <strong>{incidentStats.activeIncidents ?? "N/A"}</strong></li>
                      <li><span>Resolved / Closed:</span> <strong>{incidentStats.resolvedIncidents ?? "N/A"}</strong></li>
                    </ul>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
