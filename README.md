# Disaster/Incident Micro-Volunteering Coordination Platform

SE3090 Assignment 1 — Integrated Full-Stack and Agentic AI Application Development.

A platform connecting people affected by localized incidents (floods, landslides,
outages, community emergencies) with nearby volunteers, coordinated by community
coordinators, with an agentic AI subsystem that triages incidents, matches
volunteers, validates assignments against safety rules, and dispatches only after
human approval.

## Team

| Student | Component | Agent |
|---|---|---|
| Student 1 | Incident & Request Management | Triage/Intake Agent |
| Student 2 | Volunteer Registry & Matching | Matching Agent |
| Student 3 | Task Assignment & Dispatch Tracking | Safety/Validation Agent |
| Student 4 | Resource/Supply Logging & Reporting | Coordinator/Dispatch Agent |

## Stack

- **Backend:** ASP.NET Core Web API, Entity Framework Core, PostgreSQL
- **Web:** React
- **Mobile:** Flutter
- **Agentic AI:** Python, LangGraph (internal service called only by ASP.NET Core)

## Repo structure