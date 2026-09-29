import { useEffect, useState } from "react";

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

export default function IncidentList() {
  const [incidents, setIncidents] = useState([]);

  const [statusFilter, setStatusFilter] = useState("");

  const [loading, setLoading] = useState(true);

  const [error, setError] = useState(null);

  const [updatingId, setUpdatingId] = useState(null);

  async function load() {
    setLoading(true);
    setError(null);

    try {
      const data = await getIncidents({
        status: statusFilter || undefined,
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
  }, [statusFilter]);

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

  return (
    <div className="incident-list">
      <div className="incident-list__header">
        <h1 className="incident-list__title">Incidents</h1>

        <p className="incident-list__subtitle">
          {incidents.length}{" "}
          {statusFilter ? statusFilter.toLowerCase() : "total"}
        </p>
      </div>

      <select
        className="incident-list__filter"
        value={statusFilter}
        onChange={(e) => setStatusFilter(e.target.value)}
      >
        {STATUSES.map((status) => (
          <option key={status || "all"} value={status}>
            {status || "All statuses"}
          </option>
        ))}
      </select>

      {loading && <p className="incident-list__status">Loading incidents…</p>}

      {error && (
        <p className="incident-list__status incident-list__status--error">
          {error}
        </p>
      )}

      {!loading && !error && incidents.length === 0 && (
        <p className="incident-list__status">No incidents match this filter.</p>
      )}

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
    </div>
  );
}
