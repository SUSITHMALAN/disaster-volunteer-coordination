import { useEffect, useMemo, useState } from "react";
import BackButton from "../components/BackButton";
import {
  getResources,
  createResource,
  updateResource,
  deleteResource,
} from "../api/resources";
import "./ResourcesPage.css";

const CATEGORY_NAMES = {
  0: "Medical",
  1: "Food & Water",
  2: "Shelter",
  3: "Equipment",
  4: "Personnel",
  5: "Other",
};

const PRIORITY_NAMES = {
  0: "Low",
  1: "Medium",
  2: "High",
  3: "Critical",
};

export default function ResourcesPage() {
  const [resources, setResources] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [showModal, setShowModal] = useState(false);
  const [editingResource, setEditingResource] = useState(null);

  // Filter states
  const [categoryFilter, setCategoryFilter] = useState("");
  const [shortageFilter, setShortageFilter] = useState("");
  const [incidentFilter, setIncidentFilter] = useState("");

  // Form states
  const [formData, setFormData] = useState({
    incidentId: "",
    itemName: "",
    category: 0,
    quantityRequired: 1,
    quantityAvailable: 0,
    unit: "units",
    priority: 1,
    notes: "",
  });
  const [formSubmitting, setFormSubmitting] = useState(false);
  const [formError, setFormError] = useState("");

  async function fetchResources() {
    setError("");
    try {
      const data = await getResources({
        category: categoryFilter !== "" ? Number(categoryFilter) : undefined,
        isShortage: shortageFilter !== "" ? shortageFilter === "true" : undefined,
        incidentId: incidentFilter || undefined,
      });
      setResources(data || []);
    } catch (err) {
      setError(err.message || "Failed to load resources.");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    (async () => {
      setError("");
      try {
        const data = await getResources({
          category: categoryFilter !== "" ? Number(categoryFilter) : undefined,
          isShortage: shortageFilter !== "" ? shortageFilter === "true" : undefined,
          incidentId: incidentFilter || undefined,
        });
        setResources(data || []);
      } catch (err) {
        setError(err.message || "Failed to load resources.");
      } finally {
        setLoading(false);
      }
    })();
  }, [categoryFilter, shortageFilter, incidentFilter]);

  function handleRefresh() {
    setLoading(true);
    fetchResources();
  }

  function handleOpenCreate() {
    setEditingResource(null);
    setFormData({
      incidentId: "",
      itemName: "",
      category: 0,
      quantityRequired: 1,
      quantityAvailable: 0,
      unit: "units",
      priority: 1,
      notes: "",
    });
    setFormError("");
    setShowModal(true);
  }

  function handleOpenEdit(res) {
    setEditingResource(res);
    setFormData({
      incidentId: res.incidentId || "",
      itemName: res.itemName,
      category: res.category,
      quantityRequired: res.quantityRequired,
      quantityAvailable: res.quantityAvailable,
      unit: res.unit || "units",
      priority: res.priority,
      notes: res.notes || "",
    });
    setFormError("");
    setShowModal(true);
  }

  async function handleFormSubmit(e) {
    e.preventDefault();
    setFormSubmitting(true);
    setFormError("");

    try {
      if (editingResource) {
        await updateResource(editingResource.id, {
          quantityRequired: Number(formData.quantityRequired),
          quantityAvailable: Number(formData.quantityAvailable),
          priority: Number(formData.priority),
          status: formData.quantityAvailable >= formData.quantityRequired ? "Fulfilled" : "PartiallyAllocated",
          notes: formData.notes,
        });
      } else {
        if (!formData.incidentId) {
          throw new Error("Incident ID is required to create a resource item.");
        }
        await createResource({
          ...formData,
          category: Number(formData.category),
          priority: Number(formData.priority),
          quantityRequired: Number(formData.quantityRequired),
          quantityAvailable: Number(formData.quantityAvailable),
        });
      }
      setShowModal(false);
      fetchResources();
    } catch (err) {
      setFormError(err.message || "Operation failed.");
    } finally {
      setFormSubmitting(false);
    }
  }

  async function handleDelete(id) {
    if (!window.confirm("Are you sure you want to delete this resource record?")) return;
    try {
      await deleteResource(id);
      fetchResources();
    } catch (err) {
      setError(err.message || "Failed to delete resource.");
    }
  }

  const shortageCount = useMemo(
    () => resources.filter((r) => r.isShortage || r.shortageQuantity > 0).length,
    [resources]
  );

  return (
    <div className="resources-page">
      <BackButton to="/" label="Back to Dashboard" />

      <div className="resources-page__header">
        <div>
          <p className="resources-page__eyebrow">SUPPLY & INVENTORY</p>
          <h1 className="resources-page__title">Disaster Resources & Supplies</h1>
          <p className="resources-page__subtitle">
            Manage required equipment, medical supplies, food & water allocations across incidents.
          </p>
        </div>

        <div className="resources-page__actions">
          <button
            type="button"
            className="resources-page__btn-primary"
            onClick={handleOpenCreate}
          >
            + Add Resource
          </button>
          <button
            type="button"
            className="resources-page__btn-secondary"
            onClick={handleRefresh}
            disabled={loading}
          >
            {loading ? "Refreshing..." : "Refresh"}
          </button>
        </div>
      </div>

      <div className="resources-page__stats">
        <div className="stat-card">
          <span className="stat-card__label">Total Resource Line Items</span>
          <span className="stat-card__value">{resources.length}</span>
        </div>
        <div className="stat-card stat-card--warning">
          <span className="stat-card__label">Active Shortages</span>
          <span className="stat-card__value">{shortageCount}</span>
        </div>
      </div>

      <div className="resources-page__filters">
        <label>
          <span>Category</span>
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
          >
            <option value="">All Categories</option>
            {Object.entries(CATEGORY_NAMES).map(([key, name]) => (
              <option key={key} value={key}>
                {name}
              </option>
            ))}
          </select>
        </label>

        <label>
          <span>Shortage Status</span>
          <select
            value={shortageFilter}
            onChange={(e) => setShortageFilter(e.target.value)}
          >
            <option value="">All Items</option>
            <option value="true">Shortages Only</option>
            <option value="false">Sufficient Only</option>
          </select>
        </label>

        <label>
          <span>Incident ID</span>
          <input
            type="text"
            placeholder="Search by Incident GUID"
            value={incidentFilter}
            onChange={(e) => setIncidentFilter(e.target.value)}
          />
        </label>
      </div>

      {error && <div className="resources-page__error" role="alert">{error}</div>}

      {loading ? (
        <div className="resources-page__state">Loading resource data...</div>
      ) : resources.length === 0 ? (
        <div className="resources-page__state">No resource items found matching criteria.</div>
      ) : (
        <div className="resources-grid">
          {resources.map((item) => {
            const shortage = Math.max(0, item.quantityRequired - item.quantityAvailable);
            const isShort = item.isShortage || shortage > 0;
            const percentage = Math.min(
              100,
              Math.round((item.quantityAvailable / Math.max(1, item.quantityRequired)) * 100)
            );

            return (
              <div
                key={item.id}
                className={`resource-card ${isShort ? "resource-card--shortage" : ""}`}
              >
                <div className="resource-card__header">
                  <div>
                    <span className="resource-card__category">
                      {CATEGORY_NAMES[item.category] || "Resource"}
                    </span>
                    <h3 className="resource-card__name">{item.itemName}</h3>
                  </div>
                  <span className={`badge badge--priority-${item.priority}`}>
                    {PRIORITY_NAMES[item.priority] || "Normal"}
                  </span>
                </div>

                <div className="resource-card__progress">
                  <div className="progress-bar">
                    <div
                      className={`progress-fill ${isShort ? "progress-fill--short" : ""}`}
                      style={{ width: `${percentage}%` }}
                    />
                  </div>
                  <div className="progress-label">
                    <span>
                      {item.quantityAvailable} / {item.quantityRequired} {item.unit} ({percentage}%)
                    </span>
                    {isShort && (
                      <span className="shortage-tag">Needs +{shortage} {item.unit}</span>
                    )}
                  </div>
                </div>

                <dl className="resource-card__details">
                  <div>
                    <dt>Incident ID</dt>
                    <dd>{item.incidentId}</dd>
                  </div>
                  {item.notes && (
                    <div>
                      <dt>Notes</dt>
                      <dd>{item.notes}</dd>
                    </div>
                  )}
                </dl>

                <div className="resource-card__footer">
                  <button
                    type="button"
                    className="btn-edit"
                    onClick={() => handleOpenEdit(item)}
                  >
                    Update Quantity
                  </button>
                  <button
                    type="button"
                    className="btn-delete"
                    onClick={() => handleDelete(item.id)}
                  >
                    Delete
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Modal Dialog */}
      {showModal && (
        <div className="modal-backdrop">
          <div className="modal-content">
            <h2>{editingResource ? "Update Resource Item" : "Add New Resource Item"}</h2>
            <form onSubmit={handleFormSubmit}>
              {formError && <div className="modal-error">{formError}</div>}

              {!editingResource && (
                <label className="form-field">
                  <span>Incident ID (GUID) *</span>
                  <input
                    type="text"
                    required
                    placeholder="e.g. 3fa85f64-5717-4562-b3fc-2c963f66afa6"
                    value={formData.incidentId}
                    onChange={(e) => setFormData({ ...formData, incidentId: e.target.value })}
                  />
                </label>
              )}

              <label className="form-field">
                <span>Resource Item Name *</span>
                <input
                  type="text"
                  required
                  disabled={!!editingResource}
                  placeholder="e.g. Clean Drinking Water 5L Packs"
                  value={formData.itemName}
                  onChange={(e) => setFormData({ ...formData, itemName: e.target.value })}
                />
              </label>

              {!editingResource && (
                <label className="form-field">
                  <span>Category *</span>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({ ...formData, category: Number(e.target.value) })}
                  >
                    {Object.entries(CATEGORY_NAMES).map(([val, name]) => (
                      <option key={val} value={val}>
                        {name}
                      </option>
                    ))}
                  </select>
                </label>
              )}

              <div className="form-row">
                <label className="form-field">
                  <span>Quantity Required *</span>
                  <input
                    type="number"
                    min="1"
                    required
                    value={formData.quantityRequired}
                    onChange={(e) => setFormData({ ...formData, quantityRequired: e.target.value })}
                  />
                </label>

                <label className="form-field">
                  <span>Quantity Available *</span>
                  <input
                    type="number"
                    min="0"
                    required
                    value={formData.quantityAvailable}
                    onChange={(e) => setFormData({ ...formData, quantityAvailable: e.target.value })}
                  />
                </label>
              </div>

              <div className="form-row">
                <label className="form-field">
                  <span>Unit *</span>
                  <input
                    type="text"
                    required
                    placeholder="e.g. boxes, liters, sets"
                    value={formData.unit}
                    onChange={(e) => setFormData({ ...formData, unit: e.target.value })}
                  />
                </label>

                <label className="form-field">
                  <span>Priority *</span>
                  <select
                    value={formData.priority}
                    onChange={(e) => setFormData({ ...formData, priority: Number(e.target.value) })}
                  >
                    {Object.entries(PRIORITY_NAMES).map(([val, name]) => (
                      <option key={val} value={val}>
                        {name}
                      </option>
                    ))}
                  </select>
                </label>
              </div>

              <label className="form-field">
                <span>Notes / Specifications</span>
                <textarea
                  rows="2"
                  placeholder="Additional allocation details or delivery location..."
                  value={formData.notes}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                />
              </label>

              <div className="modal-actions">
                <button
                  type="button"
                  className="btn-cancel"
                  onClick={() => setShowModal(false)}
                  disabled={formSubmitting}
                >
                  Cancel
                </button>
                <button type="submit" className="btn-save" disabled={formSubmitting}>
                  {formSubmitting ? "Saving..." : "Save Resource"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
