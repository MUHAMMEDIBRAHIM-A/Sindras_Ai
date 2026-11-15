package com.example.synrasai

sealed interface AgentUiState {
    data object Idle : AgentUiState
    data object Thinking : AgentUiState
    data class Success(val responseText: String) : AgentUiState
    data class Error(val errorMessage: String) : AgentUiState
}
