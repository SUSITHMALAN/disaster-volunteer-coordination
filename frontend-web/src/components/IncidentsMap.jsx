import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { getIncidents } from "../api/incidents";
import "./IncidentsMap.css";

// Color mapping per severity risk
const SEVERITY_CONFIG = {
  Critical: {
    color: "#ef4444",
    bg: "rgba(239, 68, 68, 0.25)",
    glow: "rgba(239, 68, 68, 0.6)",
    icon: "🚨",
    label: "Critical Risk",
  },
  High: {
    color: "#f97316",
    bg: "rgba(249, 115, 22, 0.25)",
    glow: "rgba(249, 115, 22, 0.5)",
    icon: "⚠️",
    label: "High Risk",
  },
  Medium: {
    color: "#eab308",
    bg: "rgba(234, 179, 8, 0.25)",
    glow: "rgba(234, 179, 8, 0.4)",
    icon: "⚡",
    label: "Medium Risk",
  },
  Low: {
    color: "#3b82f6",
    bg: "rgba(59, 130, 246, 0.25)",
    glow: "rgba(59, 130, 246, 0.4)",
    icon: "ℹ️",
    label: "Low Risk",
  },
};

function createPinIcon(severity, isSelected = false) {
  const conf = SEVERITY_CONFIG[severity] || SEVERITY_CONFIG.Medium;
  const pulseClass = severity === "Critical" ? "dvc-map-pin__pulse--critical" : "dvc-map-pin__pulse";
  const selectedClass = isSelected ? "dvc-map-pin--selected" : "";

  const html = `
    <div class="dvc-map-pin ${selectedClass}" style="--pin-color: ${conf.color}; --pin-glow: ${conf.glow}">
      <div class="${pulseClass}"></div>
      <div class="dvc-map-pin__badge">
        <span class="dvc-map-pin__icon">${conf.icon}</span>
      </div>
    </div>
  `;

  return L.divIcon({
    className: "dvc-custom-pin-wrapper",
    html,
    iconSize: [36, 36],
    iconAnchor: [18, 36],
    popupAnchor: [0, -38],
  });
}

export default function IncidentsMap({ onSelectIncident }) {
  const mapContainerRef = useRef(null);
  const mapInstanceRef = useRef(null);
  const markersRef = useRef({});
  const [incidents, setIncidents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [severityFilter, setSeverityFilter] = useState("All");
  const [selectedIncident, setSelectedIncident] = useState(null);

  // Load incidents
  useEffect(() => {
    async function fetchMapIncidents() {
      setLoading(true);
      setError(null);
      try {
        const data = await getIncidents();
        // Fallback lat/long if some incidents don't have exact coordinates
        const withCoords = data.map((inc, index) => {
          let lat = inc.latitude;
          let lng = inc.longitude;
          if (!lat || !lng) {
            // Default Sri Lanka spread if coordinates null
            lat = 6.9271 + (index * 0.08);
            lng = 79.8612 + (index * 0.05);
          }
          return { ...inc, latitude: lat, longitude: lng };
        });
        setIncidents(withCoords);
      } catch (err) {
        setError(err.message || "Failed to load incidents for map.");
      } finally {
        setLoading(false);
      }
    }
    fetchMapIncidents();
  }, []);

  // Initialize map instance
  useEffect(() => {
    if (!mapContainerRef.current) return;
    if (mapInstanceRef.current) return;

    // Center of Sri Lanka (Coordinates ~ 7.8731, 80.7718)
    const map = L.map(mapContainerRef.current, {
      center: [7.2, 80.2],
      zoom: 8,
      zoomControl: false,
    });

    // Sleek Dark Matter tile layer for cohesive dark UI aesthetic
    L.tileLayer("https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png", {
      attribution:
        '&copy; <a href="https://carto.com/">CARTO</a>, &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19,
      subdomains: "abcd",
    }).addTo(map);

    L.control.zoom({ position: "topright" }).addTo(map);
    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // Place markers & update with filter
  useEffect(() => {
    const map = mapInstanceRef.current;
    if (!map) return;

    // Clear existing markers
    Object.values(markersRef.current).forEach((m) => m.remove());
    markersRef.current = {};

    const filtered = incidents.filter(
      (inc) => severityFilter === "All" || inc.severity === severityFilter
    );

    if (filtered.length === 0) return;

    const bounds = L.latLngBounds();

    filtered.forEach((inc) => {
      const latLng = [inc.latitude, inc.longitude];
      bounds.extend(latLng);

      const isSel = selectedIncident?.id === inc.id;
      const marker = L.marker(latLng, {
        icon: createPinIcon(inc.severity, isSel),
        title: inc.title,
      });

      const conf = SEVERITY_CONFIG[inc.severity] || SEVERITY_CONFIG.Medium;
      const skillsHtml = (inc.requiredSkills || [])
        .map((s) => `<span class="dvc-map-popup__skill">${s}</span>`)
        .join("");

      const popupContent = `
        <div class="dvc-map-popup">
          <div class="dvc-map-popup__header">
            <span class="dvc-map-popup__badge" style="background: ${conf.bg}; color: ${conf.color}; border: 1px solid ${conf.color}">
              ${conf.icon} ${inc.severity} Risk
            </span>
            <span class="dvc-map-popup__status">${inc.status}</span>
          </div>
          <h3 class="dvc-map-popup__title">${inc.title}</h3>
          <p class="dvc-map-popup__desc">${inc.description || ""}</p>
          <div class="dvc-map-popup__meta">
            <span>📍 ${inc.zone || inc.address || "Sri Lanka"}</span>
            <span>📂 ${inc.category}</span>
          </div>
          ${skillsHtml ? `<div class="dvc-map-popup__skills">${skillsHtml}</div>` : ""}
          <div class="dvc-map-popup__actions">
            <a href="/matches?incidentId=${inc.id}" class="dvc-map-popup__btn">
              🤝 View Matches & AI Scores
            </a>
          </div>
        </div>
      `;

      marker.bindPopup(popupContent, { maxWidth: 300, className: "dvc-leaflet-popup" });

      marker.on("click", () => {
        setSelectedIncident(inc);
        if (onSelectIncident) onSelectIncident(inc);
      });

      marker.addTo(map);
      markersRef.current[inc.id] = marker;
    });

    if (filtered.length > 0) {
      map.fitBounds(bounds, { padding: [40, 40], maxZoom: 12 });
    }
  }, [incidents, severityFilter, selectedIncident, onSelectIncident]);

  function handleFocusIncident(inc) {
    setSelectedIncident(inc);
    const map = mapInstanceRef.current;
    if (map && inc.latitude && inc.longitude) {
      map.flyTo([inc.latitude, inc.longitude], 13, { duration: 1.2 });
      const marker = markersRef.current[inc.id];
      if (marker) {
        setTimeout(() => marker.openPopup(), 600);
      }
    }
  }

  const criticalCount = incidents.filter((i) => i.severity === "Critical").length;
  const highCount = incidents.filter((i) => i.severity === "High").length;

  return (
    <div className="incidents-map-card">
      <div className="incidents-map-header">
        <div className="incidents-map-header__left">
          <h2 className="incidents-map-title">
            🗺️ Live Incident Risk Map
          </h2>
          <p className="incidents-map-subtitle">
            Real-time geospatial monitoring with severity risk classification
          </p>
        </div>

        {/* Severity Summary Badges */}
        <div className="incidents-map-stats">
          <span className="incidents-map-stat incidents-map-stat--critical" title="Critical incidents requiring urgent deployment">
            🚨 {criticalCount} Critical
          </span>
          <span className="incidents-map-stat incidents-map-stat--high" title="High severity incidents">
            ⚠️ {highCount} High
          </span>
          <span className="incidents-map-stat incidents-map-stat--total" title="Total active disaster alerts">
            📍 {incidents.length} Total
          </span>
        </div>
      </div>

      {/* Map Filter Controls Bar */}
      <div className="incidents-map-controls">
        <div className="incidents-map-filters">
          <span className="incidents-map-filters__label">Filter Risk:</span>
          {["All", "Critical", "High", "Medium", "Low"].map((sev) => (
            <button
              key={sev}
              type="button"
              className={`incidents-map-filter-btn ${severityFilter === sev ? "incidents-map-filter-btn--active" : ""} incidents-map-filter-btn--${sev.toLowerCase()}`}
              onClick={() => setSeverityFilter(sev)}
            >
              {sev === "Critical" && "🔴 "}
              {sev === "High" && "🟠 "}
              {sev === "Medium" && "🟡 "}
              {sev === "Low" && "🔵 "}
              {sev}
            </button>
          ))}
        </div>

        <button
          type="button"
          className="incidents-map-reset-btn"
          onClick={() => {
            const map = mapInstanceRef.current;
            if (map && incidents.length > 0) {
              const bounds = L.latLngBounds(incidents.map((i) => [i.latitude, i.longitude]));
              map.fitBounds(bounds, { padding: [40, 40] });
            }
          }}
          title="Fit all markers in view"
        >
          🎯 Reset View
        </button>
      </div>

      {/* Main Map Canvas and Incident List Bar */}
      <div className="incidents-map-layout">
        <div className="incidents-map-canvas-wrapper">
          {loading && (
            <div className="incidents-map-overlay">
              <div className="incidents-map-spinner"></div>
              <span>Loading live incident coordinates…</span>
            </div>
          )}
          {error && (
            <div className="incidents-map-overlay incidents-map-overlay--error">
              <span>⚠️ {error}</span>
            </div>
          )}
          <div ref={mapContainerRef} className="incidents-map-canvas"></div>
        </div>

        {/* Quick Incident List Sidebar for easy pin clicking */}
        <div className="incidents-map-sidebar">
          <h3 className="incidents-map-sidebar__heading">
            Incidents on Map ({incidents.filter((i) => severityFilter === "All" || i.severity === severityFilter).length})
          </h3>
          <div className="incidents-map-sidebar__list">
            {incidents
              .filter((i) => severityFilter === "All" || i.severity === severityFilter)
              .map((inc) => (
                <div
                  key={inc.id}
                  className={`incidents-map-item incidents-map-item--${inc.severity.toLowerCase()} ${selectedIncident?.id === inc.id ? "incidents-map-item--selected" : ""}`}
                  onClick={() => handleFocusIncident(inc)}
                >
                  <div className="incidents-map-item__top">
                    <span className="incidents-map-item__title">{inc.title}</span>
                    <span className={`incidents-map-item__badge incidents-map-item__badge--${inc.severity.toLowerCase()}`}>
                      {inc.severity}
                    </span>
                  </div>
                  <div className="incidents-map-item__details">
                    <span>📍 {inc.zone || inc.address || "Sri Lanka"}</span>
                    <span>{inc.category}</span>
                  </div>
                </div>
              ))}
          </div>
        </div>
      </div>
    </div>
  );
}
