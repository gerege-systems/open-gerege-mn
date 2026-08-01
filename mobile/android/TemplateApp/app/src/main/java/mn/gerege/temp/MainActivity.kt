// Gerege Template Platform V3.0
// Gerege Systems Development Team болон Claude AI хамтран бүтээв, 2026.

package mn.gerege.temp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.Crossfade
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import kotlinx.coroutines.launch
import mn.gerege.temp.ui.GeregeTheme
import mn.gerege.temp.ui.Token

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent {
            GeregeTheme {
                RootScreen()
            }
        }
    }
}

/**
 * Session-ий эх төлөв. `user` байвал нэвтэрсэн, эс бол Login дэлгэц.
 * ViewModel болгосон учир: WebView SSO нээгдэх/хаагдах, тохиргоо солигдох үед
 * төлөв дахин ачаалахгүй.
 */
class AppState : ViewModel() {
    var user by mutableStateOf<MeUser?>(null)
        private set
    var summary by mutableStateOf<EidSummary?>(null)
        private set
    var loading by mutableStateOf(true)
        private set
    var refreshing by mutableStateOf(false)
        private set

    /** Сүлжээ/серверийн алдааг нэвтрэх дэлгэцэд харуулна (401 бол алдаа биш). */
    var errorMessage by mutableStateOf<String?>(null)
        private set

    /** Апп нээгдэхэд cookie session хүчинтэй эсэхийг `/api/me`-ээр шалгана. */
    fun restore() {
        viewModelScope.launch {
            loading = true
            load()
            loading = false
        }
    }

    /** Нэвтрэлт амжилттай (cookie суусан) болсны дараа профайлыг татна. */
    fun onAuthenticated() {
        viewModelScope.launch { load() }
    }

    fun refresh() {
        viewModelScope.launch {
            refreshing = true
            load()
            refreshing = false
        }
    }

    fun signOut() {
        viewModelScope.launch {
            ApiClient.logout()
            user = null
            summary = null
            errorMessage = null
        }
    }

    private suspend fun load() {
        try {
            user = ApiClient.me()
            summary = ApiClient.eidSummary()
            errorMessage = null
        } catch (e: ApiError.Http) {
            // 401 = зүгээр л нэвтрээгүй байна; бусад статус л жинхэнэ алдаа.
            user = null
            summary = null
            errorMessage = if (e.code == 401) null else e.message
        } catch (e: ApiError) {
            user = null
            summary = null
            errorMessage = e.message
        }
    }
}

@Composable
fun RootScreen(state: AppState = viewModel()) {
    LaunchedEffect(Unit) { state.restore() }

    Crossfade(targetState = state.loading to (state.user != null), label = "root") { (loading, signedIn) ->
        when {
            loading -> Box(
                modifier = Modifier.fillMaxSize().background(Token.bg),
                contentAlignment = Alignment.Center,
            ) { CircularProgressIndicator() }

            signedIn -> HomeScreen(state)
            else -> LoginScreen(state)
        }
    }
}
