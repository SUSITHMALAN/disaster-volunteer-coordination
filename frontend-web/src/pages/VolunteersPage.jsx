import { useAuth } from "../context/AuthContext";
import VolunteerList from "../components/VolunteerList";
import VolunteerProfile from "../components/VolunteerProfile";
import "./VolunteersPage.css";

export default function VolunteersPage() {
  const { user } = useAuth();

  const isVolunteer = user?.role === "Volunteer";

  return (
    <main className="volunteers-page">
      {isVolunteer ? <VolunteerProfile /> : <VolunteerList />}
    </main>
  );
}
