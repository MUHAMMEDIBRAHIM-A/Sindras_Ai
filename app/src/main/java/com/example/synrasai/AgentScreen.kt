package com.example.synrasai

import android.graphics.BitmapFactory
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel

val sampleImages = arrayOf(
    R.drawable.baked_goods_1,
    R.drawable.baked_goods_2,
    R.drawable.baked_goods_3,
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AgentScreen(
    agentViewModel: AgentViewModel = viewModel()
) {
    val context = LocalContext.current
    val uiState by agentViewModel.uiState.collectAsState()
    val selectedRole by agentViewModel.selectedRole.collectAsState()

    var promptText by rememberSaveable { mutableStateOf("") }
    var selectedImageIndex by remember { mutableIntStateOf(0) }
    var includeImage by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Column {
                        Text(
                            text = "Synras AI Agent",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Autonomous AI Agent Engine",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .fillMaxSize()
                .padding(16.dp)
        ) {
            // Agent Persona Selector
            Text(
                text = "Select Agent Persona",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.height(8.dp))

            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                items(AgentRole.entries.toTypedArray()) { role ->
                    val isSelected = (role == selectedRole)
                    Card(
                        modifier = Modifier
                            .width(180.dp)
                            .clickable { agentViewModel.selectRole(role) },
                        colors = CardDefaults.cardColors(
                            containerColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer
                            else MaterialTheme.colorScheme.surface
                        ),
                        border = BorderStroke(
                            width = if (isSelected) 2.dp else 1.dp,
                            color = if (isSelected) MaterialTheme.colorScheme.primary
                            else MaterialTheme.colorScheme.outlineVariant
                        ),
                        shape = RoundedCornerShape(12.dp)
                    ) {
                        Column(modifier = Modifier.padding(12.dp)) {
                            Text(
                                text = role.title,
                                style = MaterialTheme.typography.titleSmall,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = role.description,
                                style = MaterialTheme.typography.bodySmall,
                                maxLines = 2
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Multimodal Image Attachment (Optional)
            if (selectedRole == AgentRole.VISION_CREATIVE || includeImage) {
                Text(
                    text = "Multimodal Input Attachment",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = FontWeight.SemiBold
                )
                Spacer(modifier = Modifier.height(6.dp))
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    itemsIndexed(sampleImages) { index, imgRes ->
                        Card(
                            modifier = Modifier
                                .requiredSize(72.dp)
                                .clickable {
                                    selectedImageIndex = index
                                    includeImage = true
                                },
                            border = BorderStroke(
                                width = if (index == selectedImageIndex && includeImage) 3.dp else 1.dp,
                                color = if (index == selectedImageIndex && includeImage) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outlineVariant
                            )
                        ) {
                            Image(
                                painter = painterResource(imgRes),
                                contentDescription = "Sample Image $index",
                                modifier = Modifier.fillMaxSize()
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Task / Prompt Input
            OutlinedTextField(
                value = promptText,
                onValueChange = { promptText = it },
                label = { Text("Describe agent task or request...") },
                placeholder = { Text("e.g. Audit this document or analyze code...") },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp)
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Action Button
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.End
            ) {
                if (selectedRole != AgentRole.VISION_CREATIVE) {
                    Button(
                        onClick = { includeImage = !includeImage },
                        modifier = Modifier.padding(end = 8.dp)
                    ) {
                        Text(if (includeImage) "Remove Image" else "+ Add Image")
                    }
                }

                Button(
                    onClick = {
                        val bitmap = if (includeImage || selectedRole == AgentRole.VISION_CREATIVE) {
                            BitmapFactory.decodeResource(context.resources, sampleImages[selectedImageIndex])
                        } else null
                        agentViewModel.runAgentTask(promptText, bitmap)
                    },
                    enabled = promptText.isNotBlank() && uiState !is AgentUiState.Thinking
                ) {
                    Text("Run Agent Task")
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Agent Output Viewport
            Text(
                text = "Agent Execution Output",
                style = MaterialTheme.typography.labelLarge,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.height(8.dp))

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                ),
                shape = RoundedCornerShape(16.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp)
                        .verticalScroll(rememberScrollState())
                ) {
                    when (uiState) {
                        is AgentUiState.Idle -> {
                            Text(
                                text = "Select an agent persona above and enter a task prompt to execute.",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        is AgentUiState.Thinking -> {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.Center,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                CircularProgressIndicator()
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(
                                    text = "Agent is reasoning and processing task...",
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Medium
                                )
                            }
                        }
                        is AgentUiState.Success -> {
                            val output = (uiState as AgentUiState.Success).responseText
                            Text(
                                text = output,
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurface
                            )
                        }
                        is AgentUiState.Error -> {
                            val err = (uiState as AgentUiState.Error).errorMessage
                            Text(
                                text = "Agent Execution Error:\n$err",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            }
        }
    }
}

@Preview(showSystemUi = true)
@Composable
fun AgentScreenPreview() {
    Surface {
        AgentScreen()
    }
}
