import { apiFetch } from "./client";

export function getMatchesForIncident(incidentId) {
  return apiFetch(`/api/Matches?incidentId=${incidentId}`);
}