import { apiFetch } from "./client";

export function getMatchesForIncident(incidentId) {
  return apiFetch(`/api/Matches?incidentId=${incidentId}`);
}

export function updateMatchStatus(matchId, newStatus) {
  return apiFetch(`/api/Matches/${matchId}/status`, {
    method: "PATCH",
    body: JSON.stringify({
      newStatus,
    }),
  });
}
