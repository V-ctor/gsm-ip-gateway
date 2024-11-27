#!/usr/bin/env kotlin
/*
Use param log_level=<Level> for setting logging severity: trace, debug, info, error. Info is by default.

List of checking endpoints must be stored in /tmp/state.yaml like this
asterisk.endpoint:
- {name: cloud, registered: true}
- {name: 201, registered: false}
 */

@file:DependsOn("org.yaml:snakeyaml:2.0")
@file:Import("./Notifier.main.kts")

import org.slf4j.LoggerFactory
import org.yaml.snakeyaml.Yaml
import java.io.File

val STATE_FILE = "/tmp/state.yaml" // Path to the state YAML file
val ASTERISK_COMMAND = "/usr/sbin/asterisk -rx" // Asterisk CLI command path

System.setProperty("org.slf4j.simpleLogger.showDateTime", "true")
System.setProperty("org.slf4j.simpleLogger.dateTimeFormat", "yyyy.MM.dd HH:mm:ss")

val logLevel = args.firstOrNull { it.contains("log_level") }?.split("=")?.get(1) ?: "info"

System.setProperty(org.slf4j.impl.SimpleLogger.DEFAULT_LOG_LEVEL_KEY, logLevel)

val logger = LoggerFactory.getLogger("check_endpoint_state")

// YAML loader and dumper setup
private val yaml: Yaml = Yaml()

fun executeCommand(command: String): String {
    logger.debug("Executing command: bash -c \"$command\"")
    return ProcessBuilder("bash", "-c", command)
        .redirectErrorStream(true)
        .start()
        .inputStream.bufferedReader().readText().trim()
        .also { logger.debug(it) }
}

fun isEndpointRegistered(endpoint: String): Boolean {
    val output = executeCommand("$ASTERISK_COMMAND \"pjsip show aor $endpoint\"")
    logger.debug("Command output for endpoint $endpoint: $output")
    return output.lines().any { it.contains("Contact:") && !it.contains("<Aor/ContactUri") }
}

// Function to read and parse YAML state file
fun loadState(): MutableMap<String, Any> {
    val file = File(STATE_FILE)
    if (!file.exists()) {
        file.writeText(yaml.dump(mapOf("asterisk" to mapOf("endpoints" to emptyList<Map<String, Any>>()))))
    }
    return yaml.load(file.readText()) ?: mutableMapOf()
}

// Function to save state back to YAML
fun saveState(state: Map<String, Any>) {
    File(STATE_FILE).writeText(yaml.dump(state))
}

// Function to check and update states
fun checkAndUpdateStates() {
    val state = loadState()
    logger.debug(state.toString())

    val endpoints = state["asterisk.endpoint"] as? List<MutableMap<String, Any>> ?: return
    logger.debug(endpoints.toString())

    for (endpoint in endpoints) {
        logger.debug(endpoint.toString())
        val name = endpoint["name"].let { (it as? String) ?: (it as? Int)?.toString() } ?: continue
        logger.debug(name)
        val wasRegistered = endpoint["registered"] as? Boolean ?: false
        val isRegistered = isEndpointRegistered(name)

        if (wasRegistered != isRegistered) {
            endpoint["registered"] = isRegistered
            val status = if (isRegistered) "registered" else "unregistered"
            logger.info("Endpoint $name status changed to $status")

            // Send a notification if the state changes
            sendTelegramMessage("Endpoint $name is now $status.", logger)
        } else {
            logger.info("Endpoint $name status unchanged (registered=$isRegistered)")
        }
    }

    saveState(state)
}

checkAndUpdateStates()