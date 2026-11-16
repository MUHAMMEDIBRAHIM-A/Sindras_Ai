# Team Code Review Standards & Mandatory Checklist

1. **Security:**
   - Never allow hardcoded API keys, secrets, access tokens, or credentials.
   - Sanitize all inputs to prevent SQL injection, XSS, or path traversal.

2. **Error Handling & Resilience:**
   - All external API calls, HTTP requests, and DB queries must use explicit `try/except` blocks with specific exception handling.
   - Provide clear error messages without exposing internal stack traces to end users.

3. **Clean Code & Maintainability:**
   - Functions must include type hints and concise, meaningful docstrings.
   - Flag dead code, unused imports, or redundant logic.

4. **Performance & Optimization:**
   - Avoid N+1 database query anti-patterns inside loops.
   - Use async I/O or connection pooling for network operations.
