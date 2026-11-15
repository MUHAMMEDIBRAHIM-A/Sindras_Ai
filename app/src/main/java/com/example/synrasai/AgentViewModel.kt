package com.example.synrasai

import android.graphics.Bitmap
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.firebase.Firebase
import com.google.firebase.ai.ai
import com.google.firebase.ai.type.content
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class AgentViewModel : ViewModel() {
    private val _uiState: MutableStateFlow<AgentUiState> = MutableStateFlow(AgentUiState.Idle)
    val uiState: StateFlow<AgentUiState> = _uiState.asStateFlow()

    private val _selectedRole: MutableStateFlow<AgentRole> = MutableStateFlow(AgentRole.GENERAL)
    val selectedRole: StateFlow<AgentRole> = _selectedRole.asStateFlow()

    fun selectRole(role: AgentRole) {
        _selectedRole.value = role
    }

    fun runAgentTask(prompt: String, bitmap: Bitmap? = null) {
        if (prompt.isBlank()) return
        _uiState.value = AgentUiState.Thinking

        viewModelScope.launch(Dispatchers.IO) {
            try {
                val currentRole = _selectedRole.value
                val generativeModel = Firebase.ai.generativeModel(
                    modelName = "gemini-2.0-flash",
                    systemInstruction = content { text(currentRole.systemPrompt) }
                )

                val inputContent = content {
                    bitmap?.let { image(it) }
                    text(prompt)
                }

                val response = generativeModel.generateContent(inputContent)
                val output = response.text ?: "Agent completed task with no output text."
                _uiState.value = AgentUiState.Success(output)
            } catch (e: Exception) {
                _uiState.value = AgentUiState.Error(e.localizedMessage ?: "Agent task execution failed.")
            }
        }
    }
}
