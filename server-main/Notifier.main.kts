@file:Import("./ParseConfig.kts")

import org.slf4j.Logger
import java.net.HttpURLConnection
import java.net.URL

// Constants
val tokensFile = "/etc/asterisk/extensions_tokens.conf"
val BOT_TOKEN = parseConfigValue(tokensFile, "BOT_ID=")
val CHAT_ID = parseConfigValue(tokensFile, "CHAT_ID=")
val url = URL("https://api.telegram.org/$BOT_TOKEN/sendMessage")

fun sendTelegramMessage(message: String, logger: Logger? = null) {
    logger?.debug("Sending message $message")
    val postData = "chat_id=$CHAT_ID&text=${message.replace(" ", "%20")}"

    val connection = url.openConnection() as HttpURLConnection
    connection.requestMethod = "POST"
    connection.doOutput = true

    connection.outputStream.use { it.write(postData.toByteArray()) }
    logger?.debug(connection.inputStream.bufferedReader().readText())
}
