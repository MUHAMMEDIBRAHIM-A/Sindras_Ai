import re

FORBIDDEN_KEYWORDS = ["INSERT", "UPDATE", "DELETE", "DROP", "ALTER", "TRUNCATE", "CREATE", "EXEC", "GRANT"]

def validate_readonly_sql(sql: str) -> tuple[bool, str]:
    """Validates that generated SQL is strictly a read-only SELECT query."""
    clean_sql = sql.strip().upper()

    # Must start with SELECT or WITH
    if not (clean_sql.startswith("SELECT") or clean_sql.startswith("WITH")):
        return False, "Security Error: Only SELECT queries are permitted."

    # Check for forbidden keywords
    for keyword in FORBIDDEN_KEYWORDS:
        if re.search(rf"\b{keyword}\b", clean_sql):
            return False, f"Security Error: Forbidden keyword '{keyword}' detected."

    return True, "Query validated successfully."
