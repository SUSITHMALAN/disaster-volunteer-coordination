import { createContext, useContext, useState } from "react";
import { login as loginApi, register as registerApi } from "../api/auth";

const AuthContext = createContext(null);

function loadStoredUser() {
  const raw = localStorage.getItem("dvc_user");
  return raw ? JSON.parse(raw) : null;
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(loadStoredUser());

  function persist(authResponse) {
    const { token, userId, fullName, email, role } = authResponse;
    localStorage.setItem("dvc_token", token);
    const userData = { userId, fullName, email, role };
    localStorage.setItem("dvc_user", JSON.stringify(userData));
    setUser(userData);
  }

  async function login(email, password) {
    const response = await loginApi(email, password);
    persist(response);
  }

  async function register(fields) {
    const response = await registerApi(fields);
    persist(response);
  }

  function logout() {
    localStorage.removeItem("dvc_token");
    localStorage.removeItem("dvc_user");
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}