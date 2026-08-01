// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

package mn.gerege.temp

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import mn.gerege.temp.ui.Radius
import mn.gerege.temp.ui.Space
import mn.gerege.temp.ui.Token

// Нэвтэрсэн хэрэглэгчийн профайл — үндсэн мэдээлэл + eID identity + PKI нэгдсэн
// тоо. Бүтэц нь iOS-ийн HomeView-тэй мөр мөрөөрөө тохирно (нэг бүтээгдэхүүн).
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(state: AppState) {
    val user = state.user ?: return

    Scaffold(
        containerColor = Token.bg,
        topBar = {
            TopAppBar(
                title = { Text("Миний профайл") },
                actions = {
                    IconButton(onClick = { state.refresh() }, enabled = !state.refreshing) {
                        if (state.refreshing) {
                            CircularProgressIndicator(modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                        } else {
                            Icon(Icons.Filled.Refresh, contentDescription = "Шинэчлэх")
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Token.surface,
                    titleContentColor = Token.fg,
                    actionIconContentColor = Token.brandText,
                ),
            )
        },
    ) { padding ->
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(padding),
            contentPadding = PaddingValues(Space.lg),
            verticalArrangement = Arrangement.spacedBy(Space.lg),
        ) {
            item { ProfileCard(user) }

            user.eid?.takeIf { it.hasIdentity }?.let { eid ->
                item {
                    Card("eID") {
                        eid.civilId?.let { InfoRow("Иргэний дугаар", it) }
                        eid.nationalId?.let { InfoRow("Регистр", it.uppercase()) }
                        eid.kycLevel?.let { InfoRow("KYC түвшин", it) }
                        eid.documentNumber?.let { InfoRow("Баримтын дугаар", it.take(16) + "…") }
                    }
                }
            }

            user.google?.email?.let { email ->
                item {
                    Card("Google") {
                        InfoRow("И-мэйл", email)
                        user.google.emailVerified?.let {
                            InfoRow("Баталгаажсан", if (it) "Тийм" else "Үгүй")
                        }
                    }
                }
            }

            state.summary?.let { summary ->
                item {
                    Card("eID PKI") {
                        InfoRow("Хүчинтэй гэрчилгээ", "${summary.certificatesValid}/${summary.certificatesTotal}")
                        InfoRow("Нэвтрэлт", "${summary.authenticationCount}")
                        InfoRow("Гарын үсэг", "${summary.signatureCount}")
                        InfoRow("Идэвхтэй төхөөрөмж", "${summary.devicesActive}/${summary.devicesTotal}")
                        InfoRow("Төлөөлдөг байгууллага", "${summary.representationCount}")
                    }
                }
            }

            item {
                OutlinedButton(
                    onClick = { state.signOut() },
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    shape = RoundedCornerShape(Radius.input),
                ) {
                    Icon(Icons.AutoMirrored.Filled.ExitToApp, contentDescription = null, tint = Token.danger)
                    Spacer(Modifier.width(Space.sm))
                    Text("Гарах", color = Token.danger)
                }
            }
        }
    }
}

@Composable
private fun ProfileCard(user: MeUser) {
    Card(title = null) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier.size(56.dp).clip(CircleShape).background(Token.brandSoft),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = user.displayName.take(1).uppercase(),
                    style = MaterialTheme.typography.titleLarge,
                    color = Token.brandText,
                    textAlign = TextAlign.Center,
                )
            }
            Spacer(Modifier.width(Space.md))
            Column {
                Text(user.displayName, style = MaterialTheme.typography.titleLarge, color = Token.fg)
                Spacer(Modifier.height(Space.xs))
                Text(
                    text = user.roleLabel,
                    style = MaterialTheme.typography.labelMedium,
                    color = Token.brandText,
                    modifier = Modifier
                        .clip(RoundedCornerShape(Radius.chip))
                        .background(Token.brandSoft)
                        .padding(horizontal = Space.sm, vertical = 2.dp),
                )
            }
        }
        Spacer(Modifier.height(Space.md))
        HorizontalDivider(color = Token.border)
        Spacer(Modifier.height(Space.md))
        user.email?.let { InfoRow("И-мэйл", it) }
        InfoRow("Нэвтрэх нэр", user.username)
    }
}

/** Картын үндсэн хэлбэр — `globals.css` → `.card` (гадаргуу + зураас + 24px зай). */
@Composable
private fun Card(title: String?, content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.card))
            .background(Token.surface)
            .border(1.dp, Token.border, RoundedCornerShape(Radius.card))
            .padding(Space.card),
    ) {
        title?.let {
            Text(
                text = it.uppercase(),
                style = MaterialTheme.typography.labelSmall,
                color = Token.muted,
            )
            Spacer(Modifier.height(Space.md))
        }
        content()
    }
}

@Composable
private fun InfoRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = Space.xs),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Top,
    ) {
        Text(label, style = MaterialTheme.typography.bodyMedium, color = Token.muted)
        Spacer(Modifier.width(Space.md))
        Text(
            text = value,
            style = MaterialTheme.typography.bodyLarge,
            color = Token.fg,
            textAlign = TextAlign.End,
        )
    }
}
