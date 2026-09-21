namespace DVC.Application.Services
{
    public class AssignmentValidationException : Exception
    {
        public AssignmentValidationException(string message)
            : base(message)
        {
        }
    }
}