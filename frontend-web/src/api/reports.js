import { apiFetch } from "./client";

export function getResourceSummary(params = {}) {
  const query = new URLSearchParams(params).toString();
  return apiFetch(`/api/Reports/resources/summary${query ? `?${query}` : ""}`);
}

export function getResourceShortages(params = {}) {
  const query = new URLSearchParams(params).toString();
  return apiFetch(`/api/Reports/resources/shortages${query ? `?${query}` : ""}`);
}

export function getResourcesByIncident(params = {}) {
  const query = new URLSearchParams(params).toString();
  return apiFetch(`/api/Reports/resources/by-incident${query ? `?${query}` : ""}`);
}

export function getIncidentsByZone() {
  return apiFetch("/api/Reports/incidents/by-zone");
}

export function getVolunteerLoad() {
  return apiFetch("/api/Reports/volunteers/load");
}

export function getIncidentStatistics() {
  return apiFetch("/api/Reports/incidents/statistics");
}
