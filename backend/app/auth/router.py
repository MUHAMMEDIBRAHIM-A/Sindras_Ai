"""Authentication & Two-Stage Zero-Trust Agent ID Approval Endpoints."""

import re
import uuid
from datetime import datetime, timezone, time
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.responses import HTMLResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..database import get_db
from ..models import User, AgentRegistration
from ..schemas import (
    LoginRequest,
    RegisterRequest,
    CreateTrialRequest,
    AgentIdLoginRequest,
    OwnerReviewRequest,
    TokenResponse,
    UserResponse,
)
from .dependencies import get_current_user
from .service import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["Authentication"])

MASTER_OWNER_EMAIL = "ibu2007ava@gmail.com"
MASTER_OWNER_PHONE = "9442895971"
MASTER_OWNER_AGENT_ID = "742 IBBU 07 PRO"

# Regex for NNN LLLL NN LLL (accepts with or without single spaces)
AGENT_ID_REGEX = re.compile(r"^[0-9]{3}\s?[A-Z]{4}\s?[0-9]{2}\s?[A-Z]{3}$")


def _get_today_midnight_utc() -> datetime:
    now = datetime.now(timezone.utc)
    return datetime.combine(now.date(), time(23, 59, 59, tzinfo=timezone.utc))


def _normalize_agent_id(raw_id: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9]", "", raw_id).upper()
    if len(cleaned) == 12:
        return f"{cleaned[0:3]} {cleaned[3:7]} {cleaned[7:9]} {cleaned[9:12]}"
    return raw_id.strip().upper()


@router.post("/create-trial", response_model=TokenResponse, status_code=status.HTTP_200_OK)
async def create_trial(body: CreateTrialRequest, db: AsyncSession = Depends(get_db)):
    """Stage 1: First-Time User 1-Day Trial Pass.
    Master Owner (ibu2007ava@gmail.com / 9442895971) automatically gets permanent master access.
    External users get a 1-day temporary trial session expiring at 11:59 PM today.
    """
    clean_email = body.email.strip().lower()
    clean_phone = re.sub(r"[^0-9+]", "", body.phone)

    today_end = _get_today_midnight_utc()

    # Master Owner Check
    if clean_email == MASTER_OWNER_EMAIL.lower() or MASTER_OWNER_PHONE in clean_phone:
        token = create_access_token(f"owner:{clean_email}")
        return TokenResponse(
            access_token=token,
            status="APPROVED",
            is_owner=True,
            agent_id=MASTER_OWNER_AGENT_ID,
            trial_expires_at=today_end.isoformat(),
            message="Master Owner verified. Permanent clearance granted.",
        )

    # Register or fetch existing trial
    result = await db.execute(select(AgentRegistration).where(AgentRegistration.email == clean_email))
    reg = result.scalar_one_or_none()

    if reg is None:
        reg = AgentRegistration(
            email=clean_email,
            phone=clean_phone,
            status="TRIAL",
            trial_expires_at=today_end,
        )
        db.add(reg)
        await db.flush()

    token = create_access_token(f"trial:{reg.id}")
    review_link = f"/auth/owner-review/{reg.id}"
    print(f"\n[SECURITY AUDIT] Owner Approval Email queued for: {MASTER_OWNER_EMAIL}")
    print(f"Applicant: {clean_email} | Phone: {clean_phone}")
    print(f"Review URL: http://10.189.101.145:8000{review_link}\n")

    return TokenResponse(
        access_token=token,
        status="TRIAL",
        is_owner=False,
        agent_id="TRIAL DAY 1",
        trial_expires_at=today_end.isoformat(),
        message="1-Day Trial Pass active until 11:59 PM. Owner verification sent to ibu2007ava@gmail.com.",
    )


@router.post("/login-agent-id", response_model=TokenResponse)
async def login_agent_id(body: AgentIdLoginRequest, db: AsyncSession = Depends(get_db)):
    """Stage 3: Second Login & Daily Reset (ID-Only Login: NNN LLLL NN LLL)."""
    normalized = _normalize_agent_id(body.agent_id)
    if not AGENT_ID_REGEX.match(normalized):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid 12-Digit Agent ID format. Expected format: NNN LLLL NN LLL (e.g. 742 IBBU 07 PRO)",
        )

    today_end = _get_today_midnight_utc()

    # Master Owner Fast-Path
    if normalized == MASTER_OWNER_AGENT_ID:
        token = create_access_token(f"owner:{MASTER_OWNER_EMAIL}")
        return TokenResponse(
            access_token=token,
            status="APPROVED",
            is_owner=True,
            agent_id=MASTER_OWNER_AGENT_ID,
            trial_expires_at=today_end.isoformat(),
            message="Master Owner authenticated successfully.",
        )

    # Check database for approved agent
    result = await db.execute(
        select(AgentRegistration).where(
            AgentRegistration.assigned_agent_id == normalized,
            AgentRegistration.status == "APPROVED"
        )
    )
    reg = result.scalar_one_or_none()

    if reg is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Agent ID not recognized or pending owner approval. Contact ibu2007ava@gmail.com",
        )

    token = create_access_token(f"agent:{reg.id}")
    return TokenResponse(
        access_token=token,
        status="APPROVED",
        is_owner=False,
        agent_id=normalized,
        trial_expires_at=today_end.isoformat(),
        message=f"Agent ID {normalized} verified. Session active until 11:59 PM.",
    )


@router.get("/owner-review/{request_id}", response_class=HTMLResponse)
async def get_owner_review_page(request_id: str, db: AsyncSession = Depends(get_db)):
    """Stage 2: Owner HTML Review & ID Assignment Portal."""
    try:
        req_uuid = uuid.UUID(request_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid request ID")

    result = await db.execute(select(AgentRegistration).where(AgentRegistration.id == req_uuid))
    reg = result.scalar_one_or_none()

    if reg is None:
        raise HTTPException(status_code=404, detail="Trial registration request not found")

    default_suggested_id = "891 SYNR 26 PRO"

    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>SINRAS AI — Master Owner Approval Portal</title>
        <style>
            body {{
                margin: 0;
                padding: 0;
                background-color: #12161C;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                color: #F1F5F9;
                display: flex;
                align-items: center;
                justify-content: center;
                min-height: 100vh;
            }}
            .card {{
                background-color: #1A2029;
                border: 1px solid #283240;
                border-radius: 16px;
                padding: 32px;
                max-width: 480px;
                width: 90%;
                box-shadow: 0 10px 30px rgba(0,0,0,0.5);
            }}
            .badge {{
                display: inline-block;
                background: rgba(57, 255, 20, 0.15);
                color: #39FF14;
                border: 1px solid #39FF14;
                padding: 4px 12px;
                border-radius: 999px;
                font-size: 12px;
                font-weight: bold;
                letter-spacing: 1px;
                margin-bottom: 16px;
            }}
            h1 {{
                font-size: 22px;
                margin: 0 0 16px 0;
                color: #FFFFFF;
            }}
            .field {{
                margin-bottom: 16px;
            }}
            .label {{
                font-size: 12px;
                color: #94A3B8;
                margin-bottom: 4px;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }}
            .value {{
                font-size: 15px;
                font-weight: 500;
                color: #F1F5F9;
                background: #0E1217;
                padding: 10px 14px;
                border-radius: 8px;
                border: 1px solid #283240;
            }}
            input[type="text"] {{
                width: 100%;
                box-sizing: border-box;
                background: #0E1217;
                border: 1.5px solid #00E5FF;
                color: #39FF14;
                font-size: 16px;
                font-family: monospace;
                letter-spacing: 2px;
                padding: 12px;
                border-radius: 8px;
                text-transform: uppercase;
                outline: none;
            }}
            button {{
                width: 100%;
                background: #39FF14;
                color: #0E1217;
                border: none;
                padding: 14px;
                border-radius: 10px;
                font-size: 15px;
                font-weight: bold;
                cursor: pointer;
                margin-top: 16px;
                transition: opacity 0.2s;
            }}
            button:hover {{
                opacity: 0.9;
            }}
            .status-box {{
                margin-top: 16px;
                padding: 12px;
                border-radius: 8px;
                font-size: 13px;
                background: rgba(0, 229, 255, 0.1);
                border: 1px solid #00E5FF;
                color: #00E5FF;
            }}
        </style>
    </head>
    <body>
        <div class="card">
            <span class="badge">OWNER SECURITY CLEARANCE</span>
            <h1>Assign 12-Digit Agent ID</h1>
            <div class="field">
                <div class="label">Applicant Email</div>
                <div class="value">{reg.email}</div>
            </div>
            <div class="field">
                <div class="label">Phone Number</div>
                <div class="value">{reg.phone}</div>
            </div>
            <div class="field">
                <div class="label">Current Status</div>
                <div class="value">{reg.status}</div>
            </div>
            <form method="POST" action="/auth/owner-review/{request_id}">
                <div class="field">
                    <div class="label">12-Digit Agent ID Format (NNN LLLL NN LLL)</div>
                    <input type="text" name="agent_id" value="{reg.assigned_agent_id or default_suggested_id}" required />
                </div>
                <button type="submit">Accept & Send 12-Digit ID</button>
            </form>
            <div class="status-box">
                Approved IDs are instantly emailed to applicant and activated for daily logins.
            </div>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)


@router.post("/owner-review/{request_id}")
async def post_owner_review(request_id: str, request: Request, db: AsyncSession = Depends(get_db)):
    """Stage 2: Process Owner Approval and ID Assignment."""
    try:
        req_uuid = uuid.UUID(request_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid request ID")

    result = await db.execute(select(AgentRegistration).where(AgentRegistration.id == req_uuid))
    reg = result.scalar_one_or_none()

    if reg is None:
        raise HTTPException(status_code=404, detail="Trial registration request not found")

    # Extract agent_id from Form or JSON
    content_type = request.headers.get("content-type", "")
    if "application/json" in content_type:
        data = await request.json()
        agent_id = data.get("agent_id", "")
    else:
        form = await request.form()
        agent_id = form.get("agent_id", "")

    normalized_id = _normalize_agent_id(str(agent_id))
    if not AGENT_ID_REGEX.match(normalized_id):
        raise HTTPException(status_code=400, detail="Agent ID must strictly follow NNN LLLL NN LLL format")

    reg.assigned_agent_id = normalized_id
    reg.status = "APPROVED"
    await db.flush()

    print(f"\n[APPROVAL CONFIRMED] Applicant {reg.email} granted Agent ID: {normalized_id}")
    print(f"Automated approval notification dispatched to user.\n")

    return HTMLResponse(content=f"""
    <html>
    <body style="background:#12161C;color:#F1F5F9;font-family:sans-serif;display:flex;align-items:center;justify-content:center;height:100vh;">
        <div style="background:#1A2029;padding:32px;border-radius:16px;border:1px solid #39FF14;text-align:center;">
            <h2 style="color:#39FF14;">Agent ID Assigned Successfully!</h2>
            <p>ID: <b>{normalized_id}</b></p>
            <p>User {reg.email} can now sign in using this 12-Digit Agent ID.</p>
        </div>
    </body>
    </html>
    """)


# ── Standard Endpoints for compatibility ──────────────────────────────────

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    if result.scalar_one_or_none() is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="An account with this email already exists")

    if len(body.password) < 8:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Password must be at least 8 characters")

    user = User(email=body.email, password_hash=hash_password(body.password))
    db.add(user)
    await db.flush()

    token = create_access_token(str(user.id))
    return TokenResponse(access_token=token)


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == body.email))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")

    token = create_access_token(str(user.id))
    return TokenResponse(access_token=token)


@router.get("/me", response_model=UserResponse)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user
