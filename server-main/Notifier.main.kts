@file:Import("./ParseConfig.kts")

import java.net.HttpURLConnection
import java.net.URL
import org.slf4j.Logger

// Constants
val tokensFile = "/etc/asterisk/extensions_tokens.conf"
val BOT_TOKEN = parseConfigValue(tokensFile, "BOT_ID=")
val CHAT_ID = parseConfigValue(tokensFile, "CHAT_ID=")


fun sendTelegramMessage(botToken: String, chatId: String, message: String, logger: Logger?=null) {
    val url = URL("https://api.telegram.org/$botToken/sendMessage")
    val postData = "chat_id=$chatId&text=${message.replace(" ", "%20")}"

    val connection = url.openConnection() as HttpURLConnection
    connection.requestMethod = "POST"
    connection.doOutput = true

    connection.outputStream.use { it.write(postData.toByteArray()) }
    logger?.debug(connection.inputStream.bufferedReader().readText())
}
