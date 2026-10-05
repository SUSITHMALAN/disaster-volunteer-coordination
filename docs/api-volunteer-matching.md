# Volunteer & Matching API Documentation

## Overview
This document specifies the REST API endpoints provided by `VolunteersController` and `MatchesController` in the Disaster Volunteer Coordination backend.

---

## Volunteer Endpoints

### 1. `GET /api/Volunteers`
Fetch list of registered volunteers with optional filters and pagination.

**Query Parameters:**
- `skill` (string, optional): Filter volunteers possessing a specific skill (e.g. `first-aid`).
- `available` (bool, optional): Filter by availability status (`true` / `false`).
- `zone` (string, optional): Filter by geographical location zone (e.g. `Colombo`).
- `page` (int, default `1`): Page number for pagination.
- `pageSize` (int, default `20`, max `100`): Items per page.

**Response `200 OK`:**
```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "fullName": "Jane Doe",
    "email": "jane@example.com",
    "skills": ["first-aid", "boat-driver"],
    "isAvailable": true,
    "locationZone": "Colombo",
    "maximumActiveAssignments": 3,
    "activeAssignments": 1,
    "certifications": ["CPR"],
    "comfortTier": "High",
    "availabilityStartUtc": null,
    "availabilityEndUtc": null
  }
]
```

---

### 2. `GET /api/Volunteers/{id}`
Retrieve detailed information for a single volunteer.

**Response `200 OK`:** Same structure as `VolunteerListItem`.  
**Response `404 Not Found`:** Returned if volunteer ID does not exist.

---

### 3. `PATCH /api/Volunteers/{id}/availability`
Update volunteer dispatch availability status.

**Request Body:**
```json
{
  "isAvailable": false
}
```
**Response `204 No Content`**

---

### 4. `PATCH /api/Volunteers/{id}/profile`
Update volunteer profile skills and location zone.

**Request Body:**
```json
{
  "skills": ["medical", "search-rescue"],
  "isAvailable": true,
  "locationZone": "Kandy"
}
```
**Response `204 No Content`**  
**Response `400 Bad Request`:** Returned if model validation fails.

---

## Matching Endpoints

### 1. `POST /api/Matches`
Persist a newly scored volunteer match record.

**Request Body:**
```json
{
  "incidentId": "d0b13481-8012-4cfc-a496-e26038a8e100",
  "volunteerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "score": 0.85,
  "rationale": "Jane Doe scored 0.85: skill overlap 100%, available: yes."
}
```
**Response `201 Created`**

---

### 2. `GET /api/Matches/incident/{incidentId}`
Get all ranked volunteer matches for a specified incident.

**Response `200 OK`:**
```json
[
  {
    "id": "11223344-5566-7788-9900-aabbccddeeff",
    "incidentId": "d0b13481-8012-4cfc-a496-e26038a8e100",
    "volunteerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "volunteerName": "Jane Doe",
    "score": 0.85,
    "rationale": "Jane Doe scored 0.85...",
    "status": "Proposed"
  }
]
```
