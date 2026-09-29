import { useEffect, useMemo, useState } from "react";

import {
  getAssignmentHistory,
  getVolunteerCapacity,
  updateAssignmentStatus,
} from "../api/assignments";

import { getIncidents } from "../api/incidents";

import "./AssignmentsPage.css";

const STATUS_OPTIONS = [
  "Assigned",
  "Dispatched",
  "InProgress",
  "Completed",
  "Cancelled",
];

const ACTIVE_STATUSES = ["Assigned", "Dispatched", "InProgress"];

const HISTORY_STATUSES = ["Completed", "Cancelled"];

const NEXT_STATUS = {
  Assigned: "Dispatched",
  Dispatched: "InProgress",
  InProgress: "Completed",
};

function formatStatus(status) {
  if (status === "InProgress") {
    return "In Progress";
  }

  return status;
}

function formatDate(value) {
  if (!value) {
    return "N/A";
  }

  return new Date(value).toLocaleString();
}

function shortenId(value) {
  if (!value) {
    return "N/A";
  }

  return `${value.slice(0, 8)}...`;
}

function getNextAction(status) {
  if (status === "Assigned") {
    return "Dispatch";
  }

  if (status === "Dispatched") {
    return "Start";
  }

  if (status === "InProgress") {
    return "Complete";
  }

  return null;
}

function getSuccessMessage(newStatus) {
  if (newStatus === "Dispatched") {
    return "Assignment dispatched successfully.";
  }

  if (newStatus === "InProgress") {
    return "Assignment started successfully.";
  }

  if (newStatus === "Completed") {
    return "Assignment completed successfully.";
  }

  if (newStatus === "Cancelled") {
    return "Assignment cancelled successfully.";
  }

  return "Assignment updated successfully.";
}

export default function AssignmentsPage() {
  const [assignments, setAssignments] = useState([]);
  const [incidents, setIncidents] = useState([]);

  const [statusFilter, setStatusFilter] = useState("All");
  const [incidentFilter, setIncidentFilter] = useState("");

  const [loading, setLoading] = useState(true);
  const [incidentsLoading, setIncidentsLoading] = useState(true);

  const [updatingId, setUpdatingId] = useState(null);

  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const [capacities, setCapacities] = useState({});
  const [capacityLoading, setCapacityLoading] = useState(false);

  function getIncidentName(incidentId) {
    const incident = incidents.find((item) => item.id === incidentId);

    return incident?.title || "Unknown Incident";
  }

  async function loadVolunteerCapacities(data) {
    const volunteerIds = [
      ...new Set(
        data.map((assignment) => assignment.volunteerId).filter(Boolean),
      ),
    ];

    if (volunteerIds.length === 0) {
      setCapacities({});
      return;
    }

    setCapacityLoading(true);

    try {
      const results = await Promise.all(
        volunteerIds.map(async (volunteerId) => {
          try {
            const capacity = await getVolunteerCapacity(volunteerId);

            return [volunteerId, capacity];
          } catch {
            return [volunteerId, null];
          }
        }),
      );

      setCapacities(Object.fromEntries(results));
    } finally {
      setCapacityLoading(false);
    }
  }

  async function fetchAssignments() {
    setError("");

    try {
      const data = await getAssignmentHistory();
      const assignmentData = data || [];

      setAssignments(assignmentData);

      await loadVolunteerCapacities(assignmentData);
    } catch (err) {
      setError(err.message || "Failed to load assignments.");
    } finally {
      setLoading(false);
    }
  }

  async function fetchIncidents() {
    setIncidentsLoading(true);

    try {
      const data = await getIncidents();
      setIncidents(data || []);
    } catch (err) {
      setError(err.message || "Failed to load incidents.");

      setIncidents([]);
    } finally {
      setIncidentsLoading(false);
    }
  }

  useEffect(() => {
    fetchAssignments();
    fetchIncidents();
  }, []);

  function handleRefresh() {
    setLoading(true);
    setError("");
    setSuccess("");

    fetchAssignments();
  }

  async function handleStatusUpdate(id, newStatus) {
    if (updatingId) {
      return;
    }

    setUpdatingId(id);
    setError("");
    setSuccess("");

    try {
      const updated = await updateAssignmentStatus(id, newStatus);

      setAssignments((current) =>
        current.map((assignment) =>
          assignment.id === id ? updated : assignment,
        ),
      );

      setSuccess(getSuccessMessage(newStatus));
    } catch (err) {
      setError(err.message || "Failed to update assignment status.");
    } finally {
      setUpdatingId(null);
    }
  }

  async function handleCancelAssignment(assignment) {
    const confirmed = window.confirm(
      "Are you sure you want to cancel this assignment?",
    );

    if (!confirmed) {
      return;
    }

    await handleStatusUpdate(assignment.id, "Cancelled");
  }

  const filteredAssignments = useMemo(() => {
    return assignments.filter((assignment) => {
      const matchesStatus =
        statusFilter === "All" || assignment.status === statusFilter;

      const matchesIncident =
        !incidentFilter || assignment.incidentId === incidentFilter;

      return matchesStatus && matchesIncident;
    });
  }, [assignments, statusFilter, incidentFilter]);

  const activeAssignments = useMemo(() => {
    return filteredAssignments.filter((assignment) =>
      ACTIVE_STATUSES.includes(assignment.status),
    );
  }, [filteredAssignments]);

  const historyAssignments = useMemo(() => {
    return filteredAssignments
      .filter((assignment) => HISTORY_STATUSES.includes(assignment.status))
      .sort((a, b) => new Date(b.assignedAtUtc) - new Date(a.assignedAtUtc));
  }, [filteredAssignments]);

  const groupedActiveAssignments = useMemo(() => {
    return ACTIVE_STATUSES.reduce((groups, status) => {
      groups[status] = activeAssignments.filter(
        (assignment) => assignment.status === status,
      );

      return groups;
    }, {});
  }, [activeAssignments]);

  const completedCount = historyAssignments.filter(
    (assignment) => assignment.status === "Completed",
  ).length;

  const cancelledCount = historyAssignments.filter(
    (assignment) => assignment.status === "Cancelled",
  ).length;

  return (
    <div className="assignments-page">
      <div className="assignments-page__header">
        <div>
          <p className="assignments-page__eyebrow">COORDINATOR DISPATCH</p>

          <h1 className="assignments-page__title">
            Assignment & Dispatch Board
          </h1>

          <p className="assignments-page__subtitle">
            Track volunteer assignments from dispatch through completion.
          </p>
        </div>

        <button
          type="button"
          className="assignments-page__refresh"
          onClick={handleRefresh}
          disabled={loading}
        >
          {loading ? "Refreshing..." : "Refresh"}
        </button>
      </div>

      <div className="assignments-page__filters">
        <label>
          <span>Status</span>

          <select
            value={statusFilter}
            onChange={(event) => setStatusFilter(event.target.value)}
          >
            <option value="All">All statuses</option>

            {STATUS_OPTIONS.map((status) => (
              <option key={status} value={status}>
                {formatStatus(status)}
              </option>
            ))}
          </select>
        </label>

        <label>
          <span>Incident</span>

          <select
            value={incidentFilter}
            onChange={(event) => setIncidentFilter(event.target.value)}
            disabled={incidentsLoading}
          >
            <option value="">
              {incidentsLoading ? "Loading incidents..." : "All incidents"}
            </option>

            {incidents.map((incident) => (
              <option key={incident.id} value={incident.id}>
                {incident.title}
              </option>
            ))}
          </select>
        </label>
      </div>

      {success && (
        <div className="assignments-page__success" role="status">
          {success}
        </div>
      )}

      {error && (
        <div className="assignments-page__error" role="alert">
          {error}
        </div>
      )}

      {loading ? (
        <div className="assignments-page__state">Loading assignments...</div>
      ) : (
        <>
          <section className="assignments-section">
            <div className="assignments-section__header">
              <div>
                <p className="assignments-section__eyebrow">ACTIVE WORK</p>

                <h2>Active Assignments</h2>
              </div>

              <span className="assignments-section__count">
                {activeAssignments.length} active
              </span>
            </div>

            <div className="assignments-board">
              {ACTIVE_STATUSES.map((status) => {
                const items = groupedActiveAssignments[status];

                return (
                  <section
                    key={status}
                    className={`assignment-column assignment-column--${status.toLowerCase()}`}
                  >
                    <div className="assignment-column__header">
                      <div>
                        <h2>{formatStatus(status)}</h2>

                        <span>{items.length} assignment(s)</span>
                      </div>
                    </div>

                    <div className="assignment-column__items">
                      {items.length === 0 ? (
                        <div className="assignment-column__empty">
                          No assignments
                        </div>
                      ) : (
                        items.map((assignment) => {
                          const nextStatus = NEXT_STATUS[assignment.status];

                          const nextAction = getNextAction(assignment.status);

                          const capacity = capacities[assignment.volunteerId];

                          return (
                            <article
                              key={assignment.id}
                              className="assignment-card"
                            >
                              <div className="assignment-card__top">
                                <span className="assignment-card__status">
                                  {formatStatus(assignment.status)}
                                </span>

                                <span className="assignment-card__duration">
                                  {assignment.estimatedDurationMinutes} min
                                </span>
                              </div>

                              <h3 className="assignment-card__title">
                                {getIncidentName(assignment.incidentId)}
                              </h3>

                              <dl className="assignment-card__details">
                                <div>
                                  <dt>Incident ID</dt>

                                  <dd>{shortenId(assignment.incidentId)}</dd>
                                </div>

                                <div>
                                  <dt>Volunteer</dt>

                                  <dd>{shortenId(assignment.volunteerId)}</dd>
                                </div>

                                <div>
                                  <dt>Capacity</dt>

                                  <dd>
                                    {capacityLoading && !capacity
                                      ? "Loading..."
                                      : capacity
                                        ? `${capacity.activeAssignments} / ${capacity.maximumActiveAssignments} active`
                                        : "Unavailable"}
                                  </dd>
                                </div>

                                <div>
                                  <dt>Availability</dt>

                                  <dd>
                                    {capacity
                                      ? capacity.isAvailable
                                        ? "Available"
                                        : "Unavailable"
                                      : "Unknown"}
                                  </dd>
                                </div>

                                <div>
                                  <dt>Assigned</dt>

                                  <dd>
                                    {formatDate(assignment.assignedAtUtc)}
                                  </dd>
                                </div>
                              </dl>

                              <div className="assignment-card__actions">
                                {nextStatus && (
                                  <button
                                    type="button"
                                    className="assignment-card__action"
                                    disabled={updatingId === assignment.id}
                                    onClick={() =>
                                      handleStatusUpdate(
                                        assignment.id,
                                        nextStatus,
                                      )
                                    }
                                  >
                                    {updatingId === assignment.id
                                      ? "Updating..."
                                      : nextAction}
                                  </button>
                                )}

                                <button
                                  type="button"
                                  className="assignment-card__cancel"
                                  disabled={updatingId === assignment.id}
                                  onClick={() =>
                                    handleCancelAssignment(assignment)
                                  }
                                >
                                  {updatingId === assignment.id
                                    ? "Updating..."
                                    : "Cancel"}
                                </button>
                              </div>
                            </article>
                          );
                        })
                      )}
                    </div>
                  </section>
                );
              })}
            </div>
          </section>

          <section className="assignment-history">
            <div className="assignment-history__header">
              <div>
                <p className="assignments-section__eyebrow">RECORDS</p>

                <h2>Assignment History</h2>

                <p>Completed and cancelled assignments.</p>
              </div>

              <div className="assignment-history__stats">
                <span className="history-count history-count--completed">
                  Completed {completedCount}
                </span>

                <span className="history-count history-count--cancelled">
                  Cancelled {cancelledCount}
                </span>
              </div>
            </div>

            {historyAssignments.length === 0 ? (
              <div className="assignment-history__empty">
                No completed or cancelled assignments.
              </div>
            ) : (
              <div className="assignment-history__list">
                {historyAssignments.map((assignment) => (
                  <article
                    key={assignment.id}
                    className="assignment-history__row"
                  >
                    <div className="history-main">
                      <span
                        className={`history-status history-status--${assignment.status.toLowerCase()}`}
                      >
                        {formatStatus(assignment.status)}
                      </span>

                      <div>
                        <h3>{getIncidentName(assignment.incidentId)}</h3>

                        <span className="history-id">
                          Incident {shortenId(assignment.incidentId)}
                        </span>
                      </div>
                    </div>

                    <div className="history-detail">
                      <span>Volunteer</span>

                      <strong>{shortenId(assignment.volunteerId)}</strong>
                    </div>

                    <div className="history-detail">
                      <span>Duration</span>

                      <strong>{assignment.estimatedDurationMinutes} min</strong>
                    </div>

                    <div className="history-detail">
                      <span>Assigned</span>

                      <strong>{formatDate(assignment.assignedAtUtc)}</strong>
                    </div>
                  </article>
                ))}
              </div>
            )}
          </section>
        </>
      )}
    </div>
  );
}
