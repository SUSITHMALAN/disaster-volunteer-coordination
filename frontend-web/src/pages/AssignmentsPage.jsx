import { useEffect, useMemo, useState } from "react";
import BackButton from "../components/BackButton";
import {
  getAssignmentHistory,
  updateAssignmentStatus,
} from "../api/assignments";
import "./AssignmentsPage.css";

const STATUS_OPTIONS = [
  "Assigned",
  "Dispatched",
  "InProgress",
  "Completed",
  "Cancelled",
];

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

export default function AssignmentsPage() {
  const [assignments, setAssignments] = useState([]);
  const [statusFilter, setStatusFilter] = useState("All");
  const [incidentFilter, setIncidentFilter] = useState("");
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState(null);
  const [error, setError] = useState("");

  async function loadAssignments() {
    setLoading(true);
    setError("");

    try {
      const data = await getAssignmentHistory();
      setAssignments(data || []);
    } catch (err) {
      setError(err.message || "Failed to load assignments.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadAssignments();
  }, []);

  async function handleStatusUpdate(id, newStatus) {
    setUpdatingId(id);
    setError("");

    try {
      const updated = await updateAssignmentStatus(id, newStatus);

      setAssignments((current) =>
        current.map((assignment) =>
          assignment.id === id ? updated : assignment,
        ),
      );
    } catch (err) {
      setError(err.message || "Failed to update assignment status.");
    } finally {
      setUpdatingId(null);
    }
  }

  const filteredAssignments = useMemo(() => {
    return assignments.filter((assignment) => {
      const matchesStatus =
        statusFilter === "All" || assignment.status === statusFilter;

      const matchesIncident =
        !incidentFilter ||
        assignment.incidentId
          ?.toLowerCase()
          .includes(incidentFilter.trim().toLowerCase());

      return matchesStatus && matchesIncident;
    });
  }, [assignments, statusFilter, incidentFilter]);

  const groupedAssignments = useMemo(() => {
    return STATUS_OPTIONS.reduce((groups, status) => {
      groups[status] = filteredAssignments.filter(
        (assignment) => assignment.status === status,
      );

      return groups;
    }, {});
  }, [filteredAssignments]);

  return (
    <div className="assignments-page">
      <BackButton to="/" label="Back to Dashboard" />

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
          onClick={loadAssignments}
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
          <span>Incident ID</span>
          <input
            type="text"
            placeholder="Filter by incident ID"
            value={incidentFilter}
            onChange={(event) => setIncidentFilter(event.target.value)}
          />
        </label>
      </div>

      {error && (
        <div className="assignments-page__error" role="alert">
          {error}
        </div>
      )}

      {loading ? (
        <div className="assignments-page__state">Loading assignments...</div>
      ) : filteredAssignments.length === 0 ? (
        <div className="assignments-page__state">No assignments found.</div>
      ) : (
        <div className="assignments-board">
          {STATUS_OPTIONS.map((status) => {
            const items = groupedAssignments[status];

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
                            Volunteer Assignment
                          </h3>

                          <dl className="assignment-card__details">
                            <div>
                              <dt>Incident</dt>
                              <dd>{assignment.incidentId}</dd>
                            </div>

                            <div>
                              <dt>Volunteer</dt>
                              <dd>{assignment.volunteerId}</dd>
                            </div>

                            <div>
                              <dt>Assigned</dt>
                              <dd>{formatDate(assignment.assignedAtUtc)}</dd>
                            </div>
                          </dl>

                          <div className="assignment-card__actions">
                            {nextStatus && (
                              <button
                                type="button"
                                className="assignment-card__action"
                                disabled={updatingId === assignment.id}
                                onClick={() =>
                                  handleStatusUpdate(assignment.id, nextStatus)
                                }
                              >
                                {updatingId === assignment.id
                                  ? "Updating..."
                                  : nextAction}
                              </button>
                            )}

                            {["Assigned", "Dispatched", "InProgress"].includes(
                              assignment.status,
                            ) && (
                              <button
                                type="button"
                                className="assignment-card__cancel"
                                disabled={updatingId === assignment.id}
                                onClick={() =>
                                  handleStatusUpdate(assignment.id, "Cancelled")
                                }
                              >
                                {updatingId === assignment.id
                                  ? "Updating..."
                                  : "Cancel"}
                              </button>
                            )}
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
      )}
    </div>
  );
}
