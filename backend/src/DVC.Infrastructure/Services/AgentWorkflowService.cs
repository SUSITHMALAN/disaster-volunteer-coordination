using System.Net.Http.Json;
using System.Text.Json;
using DVC.Application.Dtos;
using DVC.Application.Services;
using Microsoft.Extensions.Logging;

namespace DVC.Infrastructure.Services
{
    /// <summary>
    /// Calls the FastAPI agentic-AI bridge (api.py) over HTTP.
    /// Registered as a typed HttpClient in Program.cs so the base URL is
    /// configured once via "AgentService:BaseUrl" in appsettings.
    /// </summary>
    public class AgentWorkflowService : IAgentWorkflowService
    {
        private readonly HttpClient _http;
        private readonly ILogger<AgentWorkflowService> _logger;

        // Camel-case keys from Python; preserve unknown fields as JsonElement.
        private static readonly JsonSerializerOptions _jsonOptions = new()
        {
            PropertyNameCaseInsensitive = true,
        };

        public AgentWorkflowService(HttpClient http, ILogger<AgentWorkflowService> logger)
        {
            _http = http;
            _logger = logger;
        }

        /// <inheritdoc />
        public async Task<WorkflowStatusResponse> StartWorkflowAsync(
            StartWorkflowRequest request,
            CancellationToken ct = default)
        {
            // Python endpoint expects snake_case; serialise accordingly.
            var payload = new
            {
                incident_id = request.IncidentId,
                raw_report_text = request.RawReportText,
                required_skills = request.RequiredSkills,
            };

            var httpResponse = await _http.PostAsJsonAsync("/workflows", payload, ct);
            httpResponse.EnsureSuccessStatusCode();

            return await ParseResponseAsync(httpResponse, ct);
        }

        /// <inheritdoc />
        public async Task<WorkflowStatusResponse> GetWorkflowStatusAsync(
            string threadId,
            CancellationToken ct = default)
        {
            var httpResponse = await _http.GetAsync($"/workflows/{threadId}", ct);
            httpResponse.EnsureSuccessStatusCode();

            return await ParseResponseAsync(httpResponse, ct);
        }

        /// <inheritdoc />
        public async Task<WorkflowStatusResponse> ApproveWorkflowAsync(
            string threadId,
            WorkflowApprovalRequest request,
            CancellationToken ct = default)
        {
            var payload = new
            {
                decision = request.Decision,
                feedback = request.Feedback,
            };

            var httpResponse = await _http.PostAsJsonAsync($"/workflows/{threadId}/approve", payload, ct);
            httpResponse.EnsureSuccessStatusCode();

            return await ParseResponseAsync(httpResponse, ct);
        }

        // ── Helpers ───────────────────────────────────────────────────────────

        private async Task<WorkflowStatusResponse> ParseResponseAsync(
            HttpResponseMessage httpResponse,
            CancellationToken ct)
        {
            // Read raw JSON so we can handle the flexible "state" dictionary.
            using var stream = await httpResponse.Content.ReadAsStreamAsync(ct);
            using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: ct);
            var root = doc.RootElement;

            var threadId = root.TryGetProperty("thread_id", out var tid) ? tid.GetString() ?? "" : "";
            var awaiting = root.TryGetProperty("awaiting_approval", out var aw) && aw.GetBoolean();

            var state = new Dictionary<string, object?>();
            if (root.TryGetProperty("state", out var stateEl) && stateEl.ValueKind == JsonValueKind.Object)
            {
                foreach (var prop in stateEl.EnumerateObject())
                {
                    state[prop.Name] = prop.Value.ValueKind switch
                    {
                        JsonValueKind.String => prop.Value.GetString(),
                        JsonValueKind.Number => prop.Value.TryGetInt64(out var l) ? l : prop.Value.GetDouble(),
                        JsonValueKind.True => true,
                        JsonValueKind.False => false,
                        JsonValueKind.Null => null,
                        _ => prop.Value.GetRawText(),   // arrays, nested objects → raw JSON string
                    };
                }
            }

            return new WorkflowStatusResponse
            {
                ThreadId = threadId,
                State = state,
                AwaitingApproval = awaiting,
            };
        }
    }
}
