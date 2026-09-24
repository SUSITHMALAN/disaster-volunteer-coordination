import IncidentList from "../components/IncidentList";
import BackButton from "../components/BackButton";
import "./IncidentsPage.css";

export default function IncidentsPage() {
  return (
    <main className="incidents-page">
      <BackButton to="/" label="Back to Dashboard" />
      <IncidentList />
    </main>
  );
}
