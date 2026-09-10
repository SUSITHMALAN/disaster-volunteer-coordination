import { apiFetch } from "./client";

export function getVolunteers({ skill, available } = {}) {
  const params = new URLSearchParams();
  if (skill) params.set("skill", skill);
  if (available !== undefined) params.set("available", available);
  const query = params.toString() ? `?${params.toString()}` : "";
  return apiFetch(`/api/Volunteers${query}`);
}

export function updateAvailability(volunteerId, isAvailable) {
  return apiFetch(`/api/Volunteers/${volunteerId}/availability`, {
    method: "PATCH",
    body: JSON.stringify({ isAvailable }),
  });
}

export function getMatches(incidentId) {
  return apiFetch(`/api/Matches?incidentId=${incidentId}`);
}