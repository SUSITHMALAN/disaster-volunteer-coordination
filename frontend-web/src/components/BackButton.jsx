import { useNavigate } from "react-router-dom";
import "./BackButton.css";

export default function BackButton({
  to,
  label = "Back to Dashboard",
  className = "",
  style = {},
}) {
  const navigate = useNavigate();

  function handleClick() {
    if (to) {
      navigate(to);
    } else if (window.history.state && window.history.state.idx > 0) {
      navigate(-1);
    } else {
      navigate("/");
    }
  }

  return (
    <button
      type="button"
      className={`dvc-back-btn ${className}`}
      style={style}
      onClick={handleClick}
      aria-label={label}
    >
      <span className="dvc-back-btn__arrow">
        <svg
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M19 12H5M12 19l-7-7 7-7" />
        </svg>
      </span>
      <span className="dvc-back-btn__label">{label}</span>
    </button>
  );
}
