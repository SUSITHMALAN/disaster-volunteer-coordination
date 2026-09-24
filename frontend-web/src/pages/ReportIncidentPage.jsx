import IncidentForm from "../components/IncidentForm";
import BackButton from "../components/BackButton";
import "./ReportIncidentPage.css";

export default function ReportIncidentPage() {
  return (
    <main className="report-incident-page">
      <BackButton to="/" label="Back to Dashboard" />
      <IncidentForm />
    </main>
  );
}
