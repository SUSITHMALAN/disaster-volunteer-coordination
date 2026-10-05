using System.Net.Http.Json;
using System.Text.Json;
using DVC.Application.Dtos;
using DVC.Application.Services;
using Microsoft.Extensions.Logging;

namespace DVC.Infrastructure.Services
{
    /// <summary>
    /// Calls the FastAPI agentic-AI bridge service over HTTP.
    /// The incoming user Authorization header is forwarded per request.
    /// </summary>
    public class AgentWorkflowService : IAgentWorkflowService
    {
        private readonly HttpClient _http;
        private readonly ILogger<AgentWorkflowService> _logger;

        private static readonly JsonSerializerOptions _jsonOptions = new()
        {
            PropertyNameCaseInsensitive = true,
        };

        public AgentWorkflowService(
            HttpClient http,
            ILogger<AgentWorkflowService> logger)
        {
            _http = http;
            _logger = logger;
        }

        public async Task<WorkflowStatusResponse> StartWorkflowAsync(
            StartWorkflowRequest request,
            string? authorizationHeader,
            CancellationToken ct = default)
        {
            var payload = new
            {
                incident_id = request.IncidentId,
                raw_report_text = request.RawReportText,
                required_skills = request.RequiredSkills,
            };

            using var httpRequest = new HttpRequestMessage(
                HttpMethod.Post,
                "/workflows")
            {
                Content = JsonContent.Create(payload)
            };

            AddAuthorizationHeader(
                httpRequest,
                authorizationHeader);

            using var httpResponse = await _http.SendAsync(
                httpRequest,
                ct);

            httpResponse.EnsureSuccessStatusCode();

            return await ParseResponseAsync(
                httpResponse,
                ct);
        }

        public async Task<WorkflowStatusResponse> GetWorkflowStatusAsync(
            string threadId,
            string? authorizationHeader,
            CancellationToken ct = default)
        {
            using var httpRequest = new HttpRequestMessage(
                HttpMethod.Get,
                $"/workflows/{threadId}");

            AddAuthorizationHeader(
                httpRequest,
                authorizationHeader);

            using var httpResponse = await _http.SendAsync(
                httpRequest,
                ct);

            httpResponse.EnsureSuccessStatusCode();

            return await ParseResponseAsync(
                httpResponse,
                ct);
        }

        public async Task<WorkflowStatusResponse> ApproveWorkflowAsync(
            string threadId,
            WorkflowApprovalRequest request,
            string? authorizationHeader,
            CancellationToken ct = default)
        {
            var payload = new
            {
                decision = request.Decision,
                feedback = request.Feedback,
            };

            using var httpRequest = new HttpRequestMessage(
                HttpMethod.Post,
                $"/workflows/{threadId}/approve")
            {
                Content = JsonContent.Create(payload)
            };

            AddAuthorizationHeader(
                httpRequest,
                authorizationHeader);

            using var httpResponse = await _http.SendAsync(
                httpRequest,
                ct);

            httpResponse.EnsureSuccessStatusCode();

            return await ParseResponseAsync(
                httpResponse,
                ct);
        }

        private static void AddAuthorizationHeader(
            HttpRequestMessage request,
            string? authorizationHeader)
        {
            if (string.IsNullOrWhiteSpace(
                authorizationHeader))
            {
                return;
            }

            request.Headers.TryAddWithoutValidation(
                "Authorization",
                authorizationHeader);
        }

        private async Task<WorkflowStatusResponse> ParseResponseAsync(
            HttpResponseMessage httpResponse,
            CancellationToken ct)
        {
            using var stream =
                await httpResponse.Content.ReadAsStreamAsync(ct);

            using var doc =
                await JsonDocument.ParseAsync(
                    stream,
                    cancellationToken: ct);

            var root = doc.RootElement;

            var threadId =
                root.TryGetProperty(
                    "thread_id",
                    out var tid)
                    ? tid.GetString() ?? ""
                    : "";

            var awaiting =
                root.TryGetProperty(
                    "awaiting_approval",
                    out var aw)
                && aw.GetBoolean();

            var state =
                new Dictionary<string, object?>();

            if (
                root.TryGetProperty(
                    "state",
                    out var stateEl)
                && stateEl.ValueKind
                    == JsonValueKind.Object)
            {
                foreach (
                    var prop
                    in stateEl.EnumerateObject())
                {
                    state[prop.Name] =
                        prop.Value.ValueKind switch
                        {
                            JsonValueKind.String =>
                                prop.Value.GetString(),

                            JsonValueKind.Number =>
                                prop.Value.TryGetInt64(
                                    out var number)
                                    ? number
                                    : prop.Value.GetDouble(),

                            JsonValueKind.True =>
                                true,

                            JsonValueKind.False =>
                                false,

                            JsonValueKind.Null =>
                                null,

                            _ =>
                                prop.Value.GetRawText(),
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