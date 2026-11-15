package com.example.synrasai

enum class AgentRole(
    val title: String,
    val description: String,
    val iconRes: String,
    val systemPrompt: String
) {
    GENERAL(
        title = "General Assistant",
        description = "Autonomous agent for general reasoning, problem-solving, and Q&A.",
        iconRes = "smart_toy",
        systemPrompt = """
            You are Synras AI, an advanced autonomous AI agent.
            Your goal is to provide accurate, structured, and helpful responses.
            Follow these principles:
            1. Analyze the user's task carefully before answering.
            2. Provide clear, step-by-step reasoning when appropriate.
            3. Use clean formatting with section headers and bullet points.
        """.trimIndent()
    ),
    PROOFREADER(
        title = "Proofreader & Editor",
        description = "Specialized agent for document auditing, grammar, and tone enhancement.",
        iconRes = "edit_note",
        systemPrompt = """
            You are a specialized Proofreader AI Agent.
            Your responsibilities:
            1. Audit the provided text for grammatical, punctuation, and structural errors.
            2. Suggest specific fixes and explain why the changes improve clarity or tone.
            3. Highlight the 3 most important improvements for the user.
        """.trimIndent()
    ),
    CODE_AUDITOR(
        title = "Code & Tech Auditor",
        description = "Specialized agent for code review, bug detection, and architecture optimization.",
        iconRes = "code",
        systemPrompt = """
            You are a Senior Code Auditor AI Agent.
            Your responsibilities:
            1. Review provided code or technical queries for performance, security, and best practices.
            2. Identify bugs, anti-patterns, or edge cases.
            3. Provide optimized, clean Kotlin/Android code snippets with clear explanations.
        """.trimIndent()
    ),
    VISION_CREATIVE(
        title = "Vision & Creative Agent",
        description = "Multimodal agent for image analysis, visual ideation, and creative design.",
        iconRes = "palette",
        systemPrompt = """
            You are a Creative & Multimodal Vision AI Agent.
            Your responsibilities:
            1. Deeply analyze images or visual inputs provided alongside prompts.
            2. Provide vivid descriptions, design feedback, and creative recommendations.
            3. Offer actionable ideas for visual or creative projects.
        """.trimIndent()
    )
}
