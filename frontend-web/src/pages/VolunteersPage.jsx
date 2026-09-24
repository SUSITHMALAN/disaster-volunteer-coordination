import VolunteerList from "../components/VolunteerList";
import BackButton from "../components/BackButton";
import "./VolunteersPage.css";

export default function VolunteersPage() {
  return (
    <main className="volunteers-page">
      <BackButton to="/" label="Back to Dashboard" />
      <VolunteerList />
    </main>
  );
}