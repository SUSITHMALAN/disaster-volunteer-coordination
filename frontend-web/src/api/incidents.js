import { apiFetch } from "./client";

export function createIncident({
  title,
  description,
  category,
  severity,
  latitude,
  longitude,
  zone,
  address,
  requiredSkills,
  rawReportText,
}) {
  return apiFetch("/api/Incidents", {
    method: "POST",
    body: JSON.stringify({
      title,
      description,
      category,
      severity,
      latitude,
      longitude,
      zone,
      address,
      requiredSkills,
      rawReportText,
    }),
  });
}

export function getIncidents({ status, category, severity, zone } = {}) {
  const params = new URLSearchParams();
  if (status) params.set("status", status);
  if (category) params.set("category", category);
  if (severity) params.set("severity", severity);
  if (zone) params.set("zone", zone);
  const query = params.toString() ? `?${params.toString()}` : "";
  return apiFetch(`/api/Incidents${query}`);
}

export function getIncident(id) {
  return apiFetch(`/api/Incidents/${id}`);
}

export function updateIncidentStatus(id, newStatus) {
  return apiFetch(`/api/Incidents/${id}/status`, {
    method: "PATCH",
    body: JSON.stringify({ newStatus }),
  });
}
