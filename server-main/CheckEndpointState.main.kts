#!/usr/bin/env kotlin

@file:DependsOn("org.yaml:snakeyaml:2.0")
@file:Import("./Notifier.main.kts")

import java.io.File
import org.slf4j.LoggerFactory


val ENDPOINT = "cloud" // Name of the PJSIP endpoint to check
val STATE_FILE = "/tmp/state.yaml" // Path to the state YAML file
val ASTERISK_COMMAND = "/usr/sbin/asterisk -rx" // Asterisk CLI command path

System.setProperty("org.slf4j.simpleLogger.showDateTime","true")
System.setProperty("org.slf4j.simpleLogger.dateTimeFormat","yyyy.MM.dd HH:mm:ss")

val logLevel = args.firstOrNull { it.contains("log_level") }?.split("=")?.get(1) ?: "info"

System.setProperty(org.slf4j.impl.SimpleLogger.DEFAULT_LOG_LEVEL_KEY, logLevel)

val logger = LoggerFactory.getLogger("check_endpoint_state")

fun executeCommand(command: String): String {

    logger.debug("Executing command: bash -c \"$command\"")
    val process = ProcessBuilder("bash", "-c", command)
        .redirectErrorStream(true)
        .start()

    val output = process.inputStream.bufferedReader().readText().trim()
    logger.debug(output)
    return output
}

fun parseRegistrationStatus(output: String): Boolean {
    // Match Contact lines with actual registration data
    val contactRegex = Regex("""Contact:\s+.+@.+""")
    return contactRegex.containsMatchIn(output)
}


fun readYaml(filePath: String): Map<String, Any> {
    val yaml = org.yaml.snakeyaml.Yaml()
    if (!File(filePath).exists()) return emptyMap() // Return empty map if file doesn't exist
    File(filePath).inputStream().use { input ->
        return yaml.load(input) as? Map<String, Any> ?: emptyMap()
    }
}

fun writeYaml(filePath: String, data: Map<String, Any>) {
    val yaml = org.yaml.snakeyaml.Yaml()
    File(filePath).outputStream().use { output ->
        yaml.dump(data, output.writer())
    }
}

fun checkAndUpdateState(endpoint: String, stateFile: String, botToken: String, chatId: String) {
    val command = "$ASTERISK_COMMAND \"pjsip show aor $endpoint\""
    val output = executeCommand(command)

    val isRegistered = parseRegistrationStatus(output)

    // Load current state from YAML file
    val currentState = readYaml(stateFile).toMutableMap()
    val endpoints = (currentState["asterisk.endpoint"] as? List<MutableMap<String, Any>>)?.toMutableList() ?: mutableListOf()

    var endpointFound = false
    var stateChanged = false

    // Process each endpoint
    for (ep in endpoints) {
        if (ep["name"] == endpoint) {
            endpointFound = true
            val previousState = ep["registered"] as? Boolean ?: false

            if (previousState != isRegistered) {
                logger.info("State change detected for endpoint $endpoint:")
                logger.info("Previous state: registered=$previousState, New state: registered=$isRegistered")
                ep["registered"] = isRegistered
                stateChanged = true

                // Send Telegram notification
                val message = if (isRegistered) {
                    "Endpoint $endpoint is now registered."
                } else {
                    "Endpoint $endpoint is now unregistered."
                }
                sendTelegramMessage(botToken, chatId, message, logger)
            }
        }
    }

    // If endpoint wasn't found, add it to the state
    if (!endpointFound) {
        logger.info("Endpoint $endpoint not found in state file, adding it.")
        endpoints.add(mutableMapOf("name" to endpoint, "registered" to isRegistered))
        stateChanged = true
    }

    // Update the state file if there was a change
    if (stateChanged) {
        logger.info("Updating state file with new state for endpoint $endpoint.")
        currentState["asterisk.endpoint"] = endpoints
        writeYaml(stateFile, currentState)
    } else {
        logger.debug("No state changes detected for endpoint $endpoint.")
    }

    logger.info("Current state of endpoint $endpoint: registered=$isRegistered")
}

// Main script logic
checkAndUpdateState(ENDPOINT, STATE_FILE, BOT_TOKEN, CHAT_ID)
