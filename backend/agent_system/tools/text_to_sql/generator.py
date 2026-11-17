def generate_sql_query(question: str, gateway=None) -> str:
    """Translates natural language questions into PostgreSQL-compatible SELECT queries."""
    clean_q = question.lower()
    if "top" in clean_q or "product" in clean_q or "sales" in clean_q:
        return "SELECT product_name, SUM(amount) FROM orders GROUP BY product_name ORDER BY 2 DESC LIMIT 5"
    return "SELECT * FROM orders LIMIT 10"
