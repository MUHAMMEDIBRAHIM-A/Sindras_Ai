BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_POLICY_PATH = os.path.join(BASE_DIR, "config", "guardrails_policy.yaml")

class ActionGuardrail:
    """Evaluates role permissions and financial thresholds before action execution."""

    def __init__(self, policy_path: str = None):
        resolved_path = policy_path or DEFAULT_POLICY_PATH
        if os.path.exists(resolved_path):
            with open(resolved_path, "r", encoding="utf-8") as f:
                self.policy = yaml.safe_load(f)
        else:
            self.policy = {
                "roles": {
                    "finance": {"max_refund": 100000, "allowed_actions": ["refund", "email", "calendar"]},
                    "support": {"max_refund": 5000, "allowed_actions": ["email", "calendar"]},
                }
            }

    def evaluate_action(self, user_role: str, action: str, amount: float = 0.0) -> dict:
        role_rules = self.policy.get("roles", {}).get(user_role, {})
        allowed_actions = role_rules.get("allowed_actions", [])

        if action not in allowed_actions:
            return {"approved": False, "requires_human": False, "reason": f"Role '{user_role}' cannot perform '{action}'."}

        max_refund = role_rules.get("max_refund", 0)
        if action == "refund" and amount > max_refund:
            return {"approved": False, "requires_human": False, "reason": f"Amount ₹{amount} exceeds max limit of ₹{max_refund} for role '{user_role}'."}

        if action == "refund" and amount > 10000:
            return {"approved": False, "requires_human": True, "reason": "Requires human approval for transactions > ₹10,000."}

        return {"approved": True, "requires_human": False, "reason": "Action auto-approved by policy."}
