import { useEffect, useMemo, useState } from "react";

import { getIncidents, updateIncidentStatus } from "../api/incidents";

import IncidentCard from "./IncidentCard";

import "./IncidentList.css";

const STATUSES = [
  "",
  "Reported",
  "Triaged",
  "Matching",
  "Assigned",
  "InProgress",
  "Resolved",
  "Cancelled",
];

const CATEGORIES = [
  "",
  "Flood",
  "Landslide",
  "PowerOutage",
  "MedicalEmergency",
  "StructuralDamage",
  "Other",
];

const SEVERITIES = ["", "Low", "Medium", "High", "Critical"];

export default function IncidentList() {
  const [incidents, setIncidents] = useState([]);

  const [statusFilter, setStatusFilter] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");
  const [severityFilter, setSeverityFilter] = useState("");
  const [zoneFilter, setZoneFilter] = useState("");

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [updatingId, setUpdatingId] = useState(null);

  async function load() {
    setLoading(true);
    setError(null);

    try {
      const data = await getIncidents({
        status: statusFilter || undefined,
        category: categoryFilter || undefined,
        severity: severityFilter || undefined,
        zone: zoneFilter.trim() || undefined,
      });

      setIncidents(data || []);
    } catch (err) {
      setError(err.message || "Failed to load incidents.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [statusFilter, categoryFilter, severityFilter]);

  useEffect(() => {
    const timer = setTimeout(() => {
      load();
    }, 350);

    return () => clearTimeout(timer);

    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [zoneFilter]);

  async function handleAdvanceStatus(id, newStatus) {
    if (updatingId) {
      return;
    }

    setUpdatingId(id);
    setError(null);

    try {
      await updateIncidentStatus(id, newStatus);

      setIncidents((prev) =>
        prev.map((incident) =>
          incident.id === id
            ? {
                ...incident,
                status: newStatus,
              }
            : incident,
        ),
      );
    } catch (err) {
      setError(err.message || "Couldn't update the incident's status.");
    } finally {
      setUpdatingId(null);
    }
  }

  async function handleCancel(id) {
    const incident = incidents.find((item) => item.id === id);

    const incidentName = incident?.title || "this incident";

    const confirmed = window.confirm(
      `Are you sure you want to cancel "${incidentName}"?`,
    );

    if (!confirmed) {
      return;
    }

    await handleAdvanceStatus(id, "Cancelled");
  }

  function handleClearFilters() {
    setStatusFilter("");
    setCategoryFilter("");
    setSeverityFilter("");
    setZoneFilter("");
  }

  const hasFilters =
    statusFilter !== "" ||
    categoryFilter !== "" ||
    severityFilter !== "" ||
    zoneFilter.trim() !== "";

  const activeCount = useMemo(
    () =>
      incidents.filter(
        (incident) =>
          incident.status !== "Resolved" && incident.status !== "Cancelled",
      ).length,
    [incidents],
  );

  return (
    <div className="incident-list">
      <div className="incident-list__header">
        <div>
          <p className="incident-list__eyebrow">INCIDENT COORDINATION</p>

          <h1 className="incident-list__title">Incidents</h1>

          <p className="incident-list__description">
            Review, filter and manage reported incidents.
          </p>
        </div>

        <div className="incident-list__counts">
          <div className="incident-list__count">
            <strong>{incidents.length}</strong>
            <span>shown</span>
          </div>

          <div className="incident-list__count">
            <strong>{activeCount}</strong>
            <span>active</span>
          </div>
        </div>
      </div>

      <div className="incident-list__filters">
        <label className="incident-list__field">
          <span>Status</span>

          <select
            value={statusFilter}
            onChange={(event) => setStatusFilter(event.target.value)}
          >
            {STATUSES.map((status) => (
              <option key={status || "all"} value={status}>
                {status || "All statuses"}
              </option>
            ))}
          </select>
        </label>

        <label className="incident-list__field">
          <span>Category</span>

          <select
            value={categoryFilter}
            onChange={(event) => setCategoryFilter(event.target.value)}
          >
            {CATEGORIES.map((category) => (
              <option key={category || "all"} value={category}>
                {category || "All categories"}
              </option>
            ))}
          </select>
        </label>

        <label className="incident-list__field">
          <span>Severity</span>

          <select
            value={severityFilter}
            onChange={(event) => setSeverityFilter(event.target.value)}
          >
            {SEVERITIES.map((severity) => (
              <option key={severity || "all"} value={severity}>
                {severity || "All severities"}
              </option>
            ))}
          </select>
        </label>

        <label className="incident-list__field incident-list__field--wide">
          <span>Zone</span>

          <input
            type="text"
            placeholder="Search zone, e.g. Colombo"
            value={zoneFilter}
            onChange={(event) => setZoneFilter(event.target.value)}
          />
        </label>
      </div>

      {hasFilters && (
        <div className="incident-list__filter-actions">
          <span>
            {incidents.length} incident
            {incidents.length === 1 ? "" : "s"} match the selected filters
          </span>

          <button type="button" onClick={handleClearFilters}>
            Clear filters
          </button>
        </div>
      )}

      {loading && <p className="incident-list__status">Loading incidents...</p>}

      {error && (
        <p className="incident-list__status incident-list__status--error">
          {error}
        </p>
      )}

      {!loading && !error && incidents.length === 0 && (
        <p className="incident-list__status">
          No incidents match the selected filters.
        </p>
      )}

      {!loading && !error && incidents.length > 0 && (
        <div className="incident-list__rows">
          {incidents.map((incident) => (
            <IncidentCard
              key={incident.id}
              incident={incident}
              onAdvanceStatus={handleAdvanceStatus}
              onCancel={handleCancel}
              isUpdating={updatingId === incident.id}
            />
          ))}
        </div>
      )}
    </div>
  );
}
