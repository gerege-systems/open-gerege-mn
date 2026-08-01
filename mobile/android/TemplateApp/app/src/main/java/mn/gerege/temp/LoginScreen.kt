// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

package mn.gerege.temp

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import mn.gerege.temp.ui.Radius
import mn.gerege.temp.ui.Space
import mn.gerege.temp.ui.Token

// Нэвтрэх эхлэл — Gerege SSO. Нэвтрэлт бүхэлдээ template BFF-ээр дамжина
// (апп нь SSO дээр өөрийн client бүртгүүлэхгүй, вэбийн урсгалыг ашиглана).
// Дэвсгэр нь landing панелийн navy градиент — вэбийн нэвтрэх дэлгэцтэй нэг хэл.
@Composable
fun LoginScreen(state: AppState) {
    var showSso by remember { mutableStateOf(false) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(Token.navy, Token.navyDeep))),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .systemBarsPadding()
                .padding(horizontal = Space.xl),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Box(
                modifier = Modifier
                    .size(88.dp)
                    .clip(RoundedCornerShape(Radius.card))
                    .background(Token.onBrand.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Filled.Lock,
                    contentDescription = null,
                    tint = Token.onBrand,
                    modifier = Modifier.size(44.dp),
                )
            }

            Spacer(Modifier.height(Space.xl))

            Text(
                text = "Gerege Template Platform V3.0",
                style = MaterialTheme.typography.headlineMedium,
                color = Token.onBrand,
                textAlign = TextAlign.Center,
            )
            Spacer(Modifier.height(Space.sm))
            Text(
                text = "Gerege SSO-гоор нэвтэрнэ үү",
                style = MaterialTheme.typography.bodyLarge,
                color = Token.onBrand.copy(alpha = 0.72f),
                textAlign = TextAlign.Center,
            )

            state.errorMessage?.let { message ->
                Spacer(Modifier.height(Space.lg))
                Text(
                    text = message,
                    style = MaterialTheme.typography.bodyMedium,
                    color = Token.gold,
                    textAlign = TextAlign.Center,
                )
            }

            Spacer(Modifier.height(Space.xxxl))

            Button(
                onClick = { showSso = true },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(Radius.input),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Token.onBrand,
                    contentColor = Token.navy,
                ),
            ) {
                Text("Gerege SSO-гоор нэвтрэх")
            }
        }
    }

    if (showSso) {
        SsoDialog(
            onClose = { showSso = false },
            onDone = {
                showSso = false
                state.onAuthenticated()
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SsoDialog(onClose: () -> Unit, onDone: () -> Unit) {
    Dialog(
        onDismissRequest = onClose,
        properties = DialogProperties(usePlatformDefaultWidth = false),
    ) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("Gerege SSO") },
                    navigationIcon = {
                        IconButton(onClick = onClose) {
                            Icon(Icons.Filled.Close, contentDescription = "Хаах")
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = Token.surface,
                        titleContentColor = Token.fg,
                        navigationIconContentColor = Token.fg,
                    ),
                )
            },
            containerColor = Token.bg,
        ) { padding ->
            SsoWebView(
                modifier = Modifier.fillMaxSize().padding(padding),
                onDone = onDone,
            )
        }
    }
}
