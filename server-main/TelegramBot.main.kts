#!/usr/bin/env kscript
@file:Repository("https://repo1.maven.org/maven2") // Maven Central Repository
@file:DependsOn("org.jetbrains.kotlin:kotlin-script-util:1.8.22")
@file:DependsOn("com.fasterxml.jackson.module:jackson-module-kotlin:2.15.2")

import com.fasterxml.jackson.annotation.JsonIgnoreProperties
import org.jetbrains.kotlin.script.util.DependsOn
import org.jetbrains.kotlin.script.util.Repository
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.nio.file.Paths
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue

@JsonIgnoreProperties(ignoreUnknown = true)
data class TelegramUpdateResponse(
    val ok: Boolean,
    val result: List<TelegramUpdate>
)

@JsonIgnoreProperties(ignoreUnknown = true)
data class TelegramUpdate(
    val update_id: Long,
    val message: TelegramMessage
)

@JsonIgnoreProperties(ignoreUnknown = true)
data class TelegramMessage(
    val message_id: Int,
    val chat: TelegramChat,
    val date: Long,
    val text: String
)

@JsonIgnoreProperties(ignoreUnknown = true)
data class TelegramChat(
    val id: Long,
    val first_name: String,
    val username: String?
)


val tokensFile = "/etc/asterisk/extensions_tokens.conf"
val botId = parseConfigValue(tokensFile, "BOT_ID=")
val chatId = parseConfigValue(tokensFile, "CHAT_ID=").toLong()
val ussdPattern = "\\s*\\*102#"
val notAllowedUssdMessage = "String does not match allowed USSD pattern. Allowed: *102# - get balance"
val notAllowedUssdMessageUrl = notAllowedUssdMessage.encodeToUri()

val mapper = jacksonObjectMapper()

val tmpDir = System.getenv("XDG_RUNTIME_DIR")
    ?: System.getenv("TMPDIR")
    ?: System.getenv("TMP")
    ?: System.getenv("TEMP")
    ?: "/tmp"
val offsetFile = Paths.get(tmpDir, "tg_bot_offset.txt")
val offset: Int = try {
    File(offsetFile.toString()).readText().toInt()
} catch (e: IOException) {
    0
}

fun main() {
    val url = "https://api.telegram.org/${botId}/getUpdates?offset=${offset}"
    val response = getUrlResponse(url)
    println(response)
    if (response != null) {
        val updates = getChatUpdates(response, chatId)
        for (update in updates) {
            val updateId = update.update_id
            val text = update.message.text
            if (text.isBlank()) {
                continue
            }
            println("New message received: $text")
            if (text.matches(Regex(ussdPattern))) {
                println("String matches the USSD_PATTERN!")
                executeAsteriskCommand("asterisk -x \"originate Local/$text@sms-out-simulate application Echo\"")
            } else {
                println(notAllowedUssdMessage)
                sendTelegramMessage(botId, chatId, notAllowedUssdMessageUrl)
            }
            if (updateId >= offset) {
                offsetFile.toFile().writeText((updateId + 1).toString())
            }
        }
    } else {
        println("Error occurred while getting updates")
    }
}

fun parseConfigValue(filePath: String, key: String): String {
    val regex = """(?<=$key).*""".toRegex()
    return File(filePath).readLines().firstOrNull { it.startsWith(key) }?.let {
        regex.find(it)?.value ?: ""
    } ?: ""
}

fun String.encodeToUri(): String {
    return java.net.URLEncoder.encode(this, "UTF-8")
}

fun getUrlResponse(url: String): String? {
    val connection = URL(url).openConnection() as HttpURLConnection
    connection.requestMethod = "GET"
    val responseCode = connection.responseCode
    if (responseCode == HttpURLConnection.HTTP_OK) {
        return connection.inputStream.bufferedReader().use { it.readText() }
    }
    return null
}

fun executeAsteriskCommand(command: String) {
    ProcessBuilder()
        .command("sh", "-c", command)
        .start()
}

fun sendTelegramMessage(botId: String, chatId: Long, message: String) {
    ProcessBuilder()
        .command(
            "sh",
            "-c",
            "curl \"https://api.telegram.org/${botId}/sendMessage?chat_id=${chatId}&text=${message}\""
        )
        .start()
}

fun getChatUpdates(response: String, chatId: Long): List<TelegramUpdate> =
    mapper.readValue<TelegramUpdateResponse>(response).result.filter { it.message.chat.id == chatId }

main()