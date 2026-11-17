from tools.text_to_sql.validator import validate_readonly_sql

class SafeSQLExecutor:
    """Executes validated read-only SQL queries in an isolated DB sandbox."""

    def __init__(self, db_url: str = "sqlite:///:memory:"):
        self.db_url = db_url

    def execute_query(self, sql: str) -> dict:
        valid, message = validate_readonly_sql(sql)
        if not valid:
            return {"status": "rejected", "error": message, "data": []}

        # Simulated sandbox output
        sample_rows = [
            {"product_name": "Pro Headphones", "amount": 125000},
            {"product_name": "Smart Watch", "amount": 89000},
            {"product_name": "Wireless Charger", "amount": 42000},
        ]
        return {
            "status": "success",
            "query": sql,
            "rows_count": len(sample_rows),
            "data": sample_rows,
            "recommended_chart": "bar",
        }
