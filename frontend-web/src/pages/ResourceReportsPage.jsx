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
  0: "Water",
  1: "First Aid",
  2: "Food",
  3: "Transport",
  4: "Other",

  Water: "Water",
  FirstAid: "First Aid",
  Food: "Food",
  Transport: "Transport",
  Other: "Other",
};

function getCategoryLabel(category) {
  return CATEGORY_LABELS[category] || category || "Other";
}

function getResourceName(resource) {
  return resource.resourceName || resource.itemName || "Unnamed Resource";
}

function getNeededQuantity(resource) {
  return Number(
    resource.totalNeeded ??
      resource.neededQuantity ??
      resource.quantityRequired ??
      0,
  );
}

function getAvailableQuantity(resource) {
  return Number(
    resource.totalAvailable ??
      resource.availableQuantity ??
      resource.quantityAvailable ??
      0,
  );
}

function getUsedQuantity(resource) {
  return Number(resource.totalUsed ?? resource.usedQuantity ?? 0);
}

function getShortageQuantity(resource) {
  if (resource.totalShortage != null) {
    return Number(resource.totalShortage);
  }

  if (resource.shortageQuantity != null) {
    return Number(resource.shortageQuantity);
  }

  return Math.max(
    0,
    getNeededQuantity(resource) - getAvailableQuantity(resource),
  );
}

function shortenIncidentId(incidentId) {
  if (!incidentId) {
    return "Unknown";
  }

  return `...${incidentId.slice(-8)}`;
}

function groupResourcesByIncident(rows) {
  const grouped = {};

  rows.forEach((row) => {
    if (!grouped[row.incidentId]) {
      grouped[row.incidentId] = {
        incidentId: row.incidentId,
        incidentTitle: row.incidentTitle || "Unknown Incident",
        resources: [],
      };
    }

    grouped[row.incidentId].resources.push(row);
  });

  return Object.values(grouped);
}

function groupSummaryByCategory(rows) {
  const grouped = {};

  rows.forEach((row) => {
    const category = row.category ?? "Other";

    if (!grouped[category]) {
      grouped[category] = {
        category,
        totalItems: 0,
        totalNeeded: 0,
        totalAvailable: 0,
        totalUsed: 0,
        totalShortage: 0,
      };
    }

    grouped[category].totalItems += Number(
      row.totalItems ?? row.resourceCount ?? 0,
    );

    grouped[category].totalNeeded += Number(
      row.totalNeeded ?? row.totalRequired ?? 0,
    );

    grouped[category].totalAvailable += Number(row.totalAvailable ?? 0);

    grouped[category].totalUsed += Number(row.totalUsed ?? 0);

    grouped[category].totalShortage += Number(row.totalShortage ?? 0);
  });

  return Object.values(grouped);
}

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
      const [sumData, shortData, incData, volLoadData, incStatsData] =
        await Promise.all([
          getResourceSummary().catch(() => []),
          getResourceShortages().catch(() => null),
          getResourcesByIncident().catch(() => []),
          getVolunteerLoad().catch(() => null),
          getIncidentStatistics().catch(() => null),
        ]);

      setSummary(groupSummaryByCategory(sumData || []));
      setShortages(shortData);

      setByIncident(groupResourcesByIncident(incData || []));

      setVolunteerLoad(volLoadData);
      setIncidentStats(incStatsData);
    } catch (err) {
      setError(err.message || "Failed to load reporting data.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchReportData();
  }, []);

  function handleRefresh() {
    setLoading(true);
    fetchReportData();
  }

  const shortageItems = shortages?.items || [];

  return (
    <div className="reports-page">
      <div className="reports-page__header">
        <div>
          <p className="reports-page__eyebrow">ANALYTICS & INTELLIGENCE</p>

          <h1 className="reports-page__title">
            Resource & Coordination Reports
          </h1>

          <p className="reports-page__subtitle">
            System-wide statistics on supply shortages, volunteer load, and
            incident allocations.
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

      {error && (
        <div className="reports-page__error" role="alert">
          {error}
        </div>
      )}

      <div className="reports-tabs">
        <button
          type="button"
          className={`tab-btn ${
            activeTab === "summary" ? "tab-btn--active" : ""
          }`}
          onClick={() => setActiveTab("summary")}
        >
          Supply Summary
        </button>

        <button
          type="button"
          className={`tab-btn ${
            activeTab === "shortages" ? "tab-btn--active" : ""
          }`}
          onClick={() => setActiveTab("shortages")}
        >
          Critical Shortages (
          {shortages?.totalShortageCount ?? shortageItems.length})
        </button>

        <button
          type="button"
          className={`tab-btn ${
            activeTab === "incidents" ? "tab-btn--active" : ""
          }`}
          onClick={() => setActiveTab("incidents")}
        >
          By Incident
        </button>

        <button
          type="button"
          className={`tab-btn ${
            activeTab === "workload" ? "tab-btn--active" : ""
          }`}
          onClick={() => setActiveTab("workload")}
        >
          Volunteer & Incident Load
        </button>
      </div>

      {loading ? (
        <div className="reports-page__state">Gathering system reports...</div>
      ) : (
        <div className="reports-content">
          {/* Supply Summary */}

          {activeTab === "summary" && (
            <div className="tab-pane">
              <h2 className="pane-title">Category-wise Resource Allocation</h2>

              {summary.length === 0 ? (
                <div className="empty-state">No summary data available.</div>
              ) : (
                <div className="summary-grid">
                  {summary.map((category, index) => (
                    <div
                      key={category.category ?? index}
                      className="summary-card"
                    >
                      <div className="summary-card__header">
                        <h3>{getCategoryLabel(category.category)}</h3>

                        <span className="summary-card__count">
                          {category.totalItems ?? category.resourceCount ?? 0}{" "}
                          Items
                        </span>
                      </div>

                      <div className="summary-card__metrics">
                        <div>
                          <span>Needed</span>

                          <strong>
                            {category.totalRequired ??
                              category.totalNeeded ??
                              0}
                          </strong>
                        </div>

                        <div>
                          <span>Available</span>

                          <strong>{category.totalAvailable ?? 0}</strong>
                        </div>

                        <div>
                          <span>Used</span>

                          <strong>{category.totalUsed ?? 0}</strong>
                        </div>

                        <div
                          className={
                            Number(category.totalShortage) > 0
                              ? "text-danger"
                              : ""
                          }
                        >
                          <span>Shortage</span>

                          <strong>{category.totalShortage ?? 0}</strong>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Critical Shortages */}

          {activeTab === "shortages" && (
            <div className="tab-pane">
              <h2 className="pane-title">Active Resource Shortage Alerts</h2>

              {shortageItems.length === 0 ? (
                <div className="empty-state empty-state--success">
                  No active resource shortages reported.
                </div>
              ) : (
                <div className="shortage-table-wrapper">
                  <table className="report-table">
                    <thead>
                      <tr>
                        <th>Resource</th>
                        <th>Category</th>
                        <th>Needed</th>
                        <th>Available</th>
                        <th>Used</th>
                        <th>Shortage</th>
                        <th>Unit</th>
                      </tr>
                    </thead>

                    <tbody>
                      {shortageItems.map((item, index) => (
                        <tr key={item.id || item.resourceId || index}>
                          <td>
                            <strong>{getResourceName(item)}</strong>
                          </td>

                          <td>{getCategoryLabel(item.category)}</td>

                          <td>{getNeededQuantity(item)}</td>

                          <td>{getAvailableQuantity(item)}</td>

                          <td>{getUsedQuantity(item)}</td>

                          <td className="text-danger">
                            <strong>+{getShortageQuantity(item)}</strong>
                          </td>

                          <td>{item.unit || "units"}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* Resources By Incident */}

          {activeTab === "incidents" && (
            <div className="tab-pane">
              <div className="incident-section-heading">
                <div>
                  <h2 className="pane-title">
                    Incident Resource Allocation Breakdown
                  </h2>

                  <p>
                    Review resource availability, usage and shortages for each
                    incident.
                  </p>
                </div>

                <span className="incident-total">
                  {byIncident.length} incidents
                </span>
              </div>

              {byIncident.length === 0 ? (
                <div className="empty-state">
                  No incident breakdowns reported.
                </div>
              ) : (
                <div className="incident-breakdown-list">
                  {byIncident.map((incident) => (
                    <section
                      key={incident.incidentId}
                      className="incident-report-card"
                    >
                      <div className="incident-report-card__header">
                        <div className="incident-report-card__identity">
                          <span className="incident-report-card__label">
                            INCIDENT
                          </span>

                          <h3>{incident.incidentTitle}</h3>

                          <span className="incident-report-card__id">
                            ID {shortenIncidentId(incident.incidentId)}
                          </span>
                        </div>

                        <div className="incident-report-card__count">
                          <strong>{incident.resources.length}</strong>

                          <span>
                            {incident.resources.length === 1
                              ? "Resource"
                              : "Resources"}
                          </span>
                        </div>
                      </div>

                      <div className="incident-resource-table">
                        <div className="incident-resource-table__header">
                          <span>Resource</span>
                          <span>Needed</span>
                          <span>Available</span>
                          <span>Used</span>
                          <span>Status</span>
                        </div>

                        <div className="incident-report-card__body">
                          {incident.resources.map((resource, index) => {
                            const needed = getNeededQuantity(resource);

                            const available = getAvailableQuantity(resource);

                            const used = getUsedQuantity(resource);

                            const shortage = getShortageQuantity(resource);

                            const unit = resource.unit || "units";

                            return (
                              <div
                                key={`${incident.incidentId}-${resource.resourceName}-${index}`}
                                className="resource-report-row"
                              >
                                <div className="resource-report-row__resource">
                                  <strong>{getResourceName(resource)}</strong>

                                  <span className="resource-category">
                                    {getCategoryLabel(resource.category)}
                                  </span>
                                </div>

                                <div className="resource-report-row__metric">
                                  <span className="mobile-label">Needed</span>

                                  <strong>{needed}</strong>

                                  <small>{unit}</small>
                                </div>

                                <div className="resource-report-row__metric">
                                  <span className="mobile-label">
                                    Available
                                  </span>

                                  <strong>{available}</strong>

                                  <small>{unit}</small>
                                </div>

                                <div className="resource-report-row__metric">
                                  <span className="mobile-label">Used</span>

                                  <strong>{used}</strong>

                                  <small>{unit}</small>
                                </div>

                                <div className="resource-report-row__status">
                                  <span className="mobile-label">Status</span>

                                  {shortage > 0 ? (
                                    <span className="resource-status resource-status--shortage">
                                      Shortage {shortage} {unit}
                                    </span>
                                  ) : (
                                    <span className="resource-status resource-status--ok">
                                      Sufficient
                                    </span>
                                  )}
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    </section>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Volunteer & Incident Load */}

          {activeTab === "workload" && (
            <div className="tab-pane">
              <h2 className="pane-title">System Operational Metrics</h2>

              <div className="metrics-row">
                {volunteerLoad && (
                  <div className="metric-box">
                    <h3>Volunteer Workforce Load</h3>

                    <ul>
                      <li>
                        <span>Total Active Volunteers:</span>

                        <strong>
                          {volunteerLoad.totalVolunteers ?? "N/A"}
                        </strong>
                      </li>

                      <li>
                        <span>Assigned / On-Duty:</span>

                        <strong>
                          {volunteerLoad.assignedVolunteers ?? "N/A"}
                        </strong>
                      </li>

                      <li>
                        <span>Available Capacity:</span>

                        <strong>
                          {volunteerLoad.availableVolunteers ?? "N/A"}
                        </strong>
                      </li>
                    </ul>
                  </div>
                )}

                {incidentStats && (
                  <div className="metric-box">
                    <h3>Incident Overview</h3>

                    <ul>
                      <li>
                        <span>Total Incidents:</span>

                        <strong>{incidentStats.totalIncidents ?? "N/A"}</strong>
                      </li>

                      <li>
                        <span>Active / Open:</span>

                        <strong>
                          {incidentStats.activeIncidents ?? "N/A"}
                        </strong>
                      </li>

                      <li>
                        <span>Resolved / Closed:</span>

                        <strong>
                          {incidentStats.resolvedIncidents ?? "N/A"}
                        </strong>
                      </li>
                    </ul>
                  </div>
                )}

                {!volunteerLoad && !incidentStats && (
                  <div className="empty-state">
                    Operational metrics are not available.
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
