package foundation.tablet

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performImeAction
import androidx.compose.ui.test.performTextReplacement
import androidx.compose.ui.test.performScrollTo
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Uses the packaged Rust library through the real Activity, with no replacement binding. */
@RunWith(AndroidJUnit4::class)
class GreetingTest {
    @get:Rule
    val compose = createAndroidComposeRule<MainActivity>()

    @Test
    fun greetingChangesOnlyAfterSubmitAndPreservesInput() {
        compose.onNodeWithText("Salam Rust").assertIsDisplayed()
        compose.onNodeWithText("Masukkan nama, lalu tekan Sapa.").assertIsDisplayed()
        compose.onNodeWithText("Nama").assertIsDisplayed()
        compose.onNodeWithTag("name-input").assertTextEquals("Nama", "Ayu")
        compose.onNodeWithTag("greeting-result").assertTextEquals("")

        submitButton()
        result("Hello, Ayu!")
        replaceName("Bima")
        result("Hello, Ayu!")
        submitButton()
        result("Hello, Bima!")
        replaceName("")
        result("Hello, Bima!")
        submitButton()
        result("Hello, !")
        replaceName("Zoë 東京")
        result("Hello, !")
        submitButton()
        result("Hello, Zoë 東京!")
        replaceName("  Ayu  ")
        submitButton()
        result("Hello,   Ayu  !")
    }

    @Test
    fun keyboardSubmitCallsRust() {
        replaceName("Zoë 東京")
        compose.onNodeWithTag("greeting-result").assertTextEquals("")
        compose.onNodeWithTag("name-input").performImeAction()
        result("Hello, Zoë 東京!")
    }

    @Test
    fun activityRecreationRestoresNameAndLastResultIndependently() {
        submitButton()
        replaceName("Bima")
        compose.activityRule.scenario.recreate()
        compose.onNodeWithTag("name-input").assertTextEquals("Nama", "Bima")
        result("Hello, Ayu!")
        submitButton()
        result("Hello, Bima!")
    }

    private fun replaceName(name: String) {
        compose.onNodeWithTag("name-input").performScrollTo().performTextReplacement(name)
    }

    private fun submitButton() {
        compose.onNodeWithText("Sapa").performScrollTo().performClick()
    }

    private fun result(expected: String) {
        compose.onNodeWithTag("greeting-result").performScrollTo()
            .assertIsDisplayed().assertTextEquals(expected)
    }
}
