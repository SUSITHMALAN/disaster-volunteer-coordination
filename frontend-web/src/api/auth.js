import { apiFetch } from "./client";

export function login(email, password) {
  return apiFetch("/api/Auth/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
}

export function register({ fullName, email, password, role, skills }) {
  return apiFetch("/api/Auth/register", {
    method: "POST",
    body: JSON.stringify({ fullName, email, password, role, skills }),
  });
}