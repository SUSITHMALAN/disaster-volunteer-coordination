from contextvars import ContextVar


authorization_header: ContextVar[str | None] = ContextVar(
    "authorization_header",
    default=None,
)