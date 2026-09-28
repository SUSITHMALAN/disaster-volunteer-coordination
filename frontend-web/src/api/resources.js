import { apiFetch } from "./client";

export function getResources({ incidentId, category, isShortage } = {}) {
  const params = new URLSearchParams();
  if (incidentId) params.set("incidentId", incidentId);
  if (category !== undefined && category !== "") params.set("category", category);
  if (isShortage !== undefined && isShortage !== "") params.set("isShortage", isShortage);
  const query = params.toString() ? `?${params.toString()}` : "";
  return apiFetch(`/api/Resources${query}`);
}

export function getResource(id) {
  return apiFetch(`/api/Resources/${id}`);
}

export function createResource(data) {
  return apiFetch("/api/Resources", {
    method: "POST",
    body: JSON.stringify(data),
  });
}

export function updateResource(id, data) {
  return apiFetch(`/api/Resources/${id}`, {
    method: "PUT",
    body: JSON.stringify(data),
  });
}

export function deleteResource(id) {
  return apiFetch(`/api/Resources/${id}`, {
    method: "DELETE",
  });
}
