import { useAuth } from "../context/AuthContext";
import VolunteerList from "../components/VolunteerList";
import VolunteerProfile from "../components/VolunteerProfile";
import BackButton from "../components/BackButton";
import "./VolunteersPage.css";

export default function VolunteersPage() {
  const { user } = useAuth();
  const isVolunteer = user?.role === "Volunteer";

  return (
    <main className="volunteers-page">
      <BackButton to="/" label="Back to Dashboard" />
      {isVolunteer ? <VolunteerProfile /> : <VolunteerList />}
    </main>
  );
}