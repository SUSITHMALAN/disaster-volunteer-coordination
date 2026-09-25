import { apiFetch } from "./client";

export function createAssignment(matchId, estimatedDurationMinutes) {
  return apiFetch("/api/Assignments", {
    method: "POST",
    body: JSON.stringify({
      matchId,
      estimatedDurationMinutes,
    }),
  });
}

export function updateAssignmentStatus(id, newStatus) {
  return apiFetch(`/api/Assignments/${id}/status`, {
    method: "PATCH",
    body: JSON.stringify({
      newStatus,
    }),
  });
}

export function getAssignmentHistory({ volunteerId, incidentId } = {}) {
  const params = new URLSearchParams();

  if (volunteerId) {
    params.set("volunteerId", volunteerId);
  }

  if (incidentId) {
    params.set("incidentId", incidentId);
  }

  const query = params.toString() ? `?${params.toString()}` : "";

  return apiFetch(`/api/Assignments/history${query}`);
}

export function getVolunteerCapacity(volunteerId) {
  return apiFetch(`/api/Volunteers/${volunteerId}/capacity-check`);
}
