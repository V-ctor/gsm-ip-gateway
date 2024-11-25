import java.io.File

fun parseConfigValue(filePath: String, key: String): String {
    val regex = """(?<=$key).*""".toRegex()
    return File(filePath).readLines().firstOrNull { it.startsWith(key) }?.let {
        regex.find(it)?.value ?: ""
    } ?: ""
}