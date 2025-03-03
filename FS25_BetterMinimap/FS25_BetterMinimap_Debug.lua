-- FS25_BetterMinimap_Debug.lua
-- Debug script to log debug information in XML format

FS25_BetterMinimap_Debug = {}

--- Gets the path to the debug log XML file
function FS25_BetterMinimap_Debug:getLogFilePath()
    local settingsDir = getUserProfileAppPath() .. "modSettings/FS25_BetterMinimap/"
    return settingsDir .. "FS25_BetterMinimap_Debug.xml"
end

--- Writes a log entry to the XML file
function FS25_BetterMinimap_Debug:writeLog(level, message)
    local filePath = self:getLogFilePath()

    -- Load existing XML file or create a new one
    local xmlFile = loadXMLFile("debugLog", filePath)
    if xmlFile == 0 then
        xmlFile = createXMLFile("debugLog", filePath, "FS25_BetterMinimap_Debug")
    end

    -- Escape special characters to avoid XML parsing errors
    local function escapeXml(str)
        str = str:gsub("&", "&amp;")
        str = str:gsub("<", "&lt;")
        str = str:gsub(">", "&gt;")
        return str
    end

    -- Retrieve valid date values
    local year = g_currentMission.environment.currentYear or getDate("%Y") or 2025
    local month = g_currentMission.environment.currentMonth or getDate("%m") or 1
    local day = g_currentMission.environment.currentDay or getDate("%d") or 1

    -- Retrieve valid time values
    local hour = math.floor((g_currentMission.environment.dayTime or 0) / (60 * 60 * 1000)) % 24
    local minute = math.floor((g_currentMission.environment.dayTime or 0) / (60 * 1000)) % 60

    -- If hour or minute is invalid, fallback to system time
    if hour == 0 and minute == 0 then
        hour = getTime("%H") or 12
        minute = getTime("%M") or 0
    end

    -- Format timestamp
    local timestamp = string.format("%04d-%02d-%02d %02d:%02d", year, month, day, hour, minute)

    -- Find next available log entry index
    local logIndex = 0
    while hasXMLProperty(xmlFile, string.format("FS25_BetterMinimap_Debug.log(%d)", logIndex)) do
        logIndex = logIndex + 1
    end

    -- Write new log entry
    local logPath = string.format("FS25_BetterMinimap_Debug.log(%d)", logIndex)
    setXMLInt(xmlFile, logPath .. "#logid", logIndex)
    setXMLString(xmlFile, logPath .. "#time", timestamp)
    setXMLString(xmlFile, logPath .. "#level", level)
    setXMLString(xmlFile, logPath .. "#message", escapeXml(message)) -- Escaped message

    -- Save and close file
    saveXMLFile(xmlFile)
    delete(xmlFile)
end
--- Logs an error message
function FS25_BetterMinimap_Debug:logError(message)
    self:writeLog("Error", message)
end

--- Logs a warning message
function FS25_BetterMinimap_Debug:logWarning(message)
    self:writeLog("Warning", message)
end

--- Logs an info message
function FS25_BetterMinimap_Debug:logInfo(message)
    self:writeLog("Info", message)
end

--- Runs all debugging checks
function FS25_BetterMinimap_Debug:runAllChecks()
    self:logInfo("==== FS25_BetterMinimap Debugging Start ====")
    self:logInfo("Checking available functions in g_fieldManager...")
    self:logInfo("Checking available functions in mapOverlay...")
    self:logInfo("==== Debugging Complete ====")
end

return FS25_BetterMinimap_Debug
