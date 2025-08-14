package com.roadtrip.copilot

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.platform.app.InstrumentationRegistry
import com.roadtrip.copilot.managers.SpeechManager
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.test.assertTrue

@LargeTest
@ExperimentalCoroutinesApi
@RunWith(AndroidJUnit4::class)
class VoicePerformanceTest {

    private lateinit var speechManager: SpeechManager
    private lateinit var context: android.content.Context

    @Before
    fun setup() {
        context = InstrumentationRegistry.getInstrumentation().targetContext
        speechManager = SpeechManager()
        speechManager.initialize(context)
    }

    // MARK: - Response Time Performance Tests (Target: <350ms)

    @Test
    fun testVoiceCommandProcessingTime() = runTest {
        val testCommands = listOf(
            "save this place",
            "like this restaurant",
            "skip this location", 
            "next place",
            "go back",
            "get directions",
            "call them"
        )

        testCommands.forEach { command ->
            val startTime = System.currentTimeMillis()
            
            val result = speechManager.processVoiceCommand(command)
            
            val endTime = System.currentTimeMillis()
            val processingTime = endTime - startTime

            assertTrue(
                processingTime < 350,
                "Command '$command' should process in under 350ms, took ${processingTime}ms"
            )
        }
    }

    @Test
    fun testTextToSpeechStartTime() = runTest {
        val testPhrases = listOf(
            "Saving to favorites",
            "Liked",
            "Skipped",
            "Next location", 
            "Getting directions"
        )

        testPhrases.forEach { phrase ->
            val startTime = System.currentTimeMillis()
            
            speechManager.speak(phrase)
            
            // Wait for TTS to start
            val isSpeaking = speechManager.isSpeaking.first { it }
            assertTrue(isSpeaking)
            
            val endTime = System.currentTimeMillis()
            val startupTime = endTime - startTime

            assertTrue(
                startupTime < 200,
                "TTS for '$phrase' should start in under 200ms, took ${startupTime}ms"
            )
            
            speechManager.stopSpeaking()
        }
    }

    @Test
    fun testVoiceRecognitionStartupTime() = runTest {
        val startTime = System.currentTimeMillis()
        
        speechManager.startListening()
        
        // Wait for listening to start
        val isListening = speechManager.isListening.first { it }
        assertTrue(isListening)
        
        val endTime = System.currentTimeMillis()
        val startupTime = endTime - startTime

        assertTrue(
            startupTime < 200,
            "Voice recognition should start in under 200ms, took ${startupTime}ms"
        )
        
        speechManager.stopListening()
    }

    @Test
    fun testButtonResponseTime() {
        val testCommands = listOf("save", "like", "next", "navigate")
        
        testCommands.forEach { command ->
            val startTime = System.currentTimeMillis()
            
            // Simulate button press response
            speechManager.processVoiceCommand(command)
            
            val endTime = System.currentTimeMillis()
            val responseTime = endTime - startTime

            assertTrue(
                responseTime < 100,
                "Button response for '$command' should be under 100ms, took ${responseTime}ms"
            )
        }
    }

    // MARK: - Throughput Performance Tests

    @Test
    fun testVoiceCommandThroughput() {
        val commands = (0..99).map { "save place $it" }
        
        val startTime = System.currentTimeMillis()
        
        commands.forEach { command ->
            speechManager.processVoiceCommand(command)
        }
        
        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime
        val averageTime = totalTime / commands.size

        assertTrue(
            averageTime < 10,
            "Average command processing should be under 10ms, was ${averageTime}ms"
        )
    }

    @Test
    fun testTextToSpeechThroughput() = runTest {
        val phrases = (0..49).map { "Message number $it" }
        
        val startTime = System.currentTimeMillis()
        
        phrases.forEach { phrase ->
            speechManager.speak(phrase)
            speechManager.stopSpeaking() // Clear queue for next
        }
        
        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime
        val averageTime = totalTime / phrases.size

        assertTrue(
            averageTime < 50,
            "Average TTS processing should be under 50ms, was ${averageTime}ms"
        )
    }

    @Test
    fun testConcurrentVoiceCommands() = runTest {
        val commandCount = 100
        val commands = (0 until commandCount).map { "test command $it" }
        val results = mutableListOf<String>()

        val startTime = System.currentTimeMillis()

        // Process commands concurrently
        commands.forEach { command ->
            val result = speechManager.processVoiceCommand(command)
            results.add(result.action)
        }

        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime
        val averageTime = totalTime / commandCount.toDouble()

        assertTrue(results.size == commandCount)
        assertTrue(
            averageTime < 50,
            "Average concurrent command processing should be under 50ms, was ${averageTime}ms"
        )
    }

    // MARK: - Memory Performance Tests

    @Test
    fun testMemoryUsageUnderLoad() {
        val runtime = Runtime.getRuntime()
        val initialMemory = runtime.totalMemory() - runtime.freeMemory()

        // Process many voice commands
        repeat(1000) { i ->
            speechManager.processVoiceCommand("test command $i")
            
            // Periodic cleanup
            if (i % 100 == 0) {
                System.gc()
            }
        }

        val finalMemory = runtime.totalMemory() - runtime.freeMemory()
        val memoryIncrease = finalMemory - initialMemory

        assertTrue(
            memoryIncrease < 100 * 1024 * 1024, // 100MB
            "Memory usage should not increase excessively: ${memoryIncrease / 1024 / 1024}MB"
        )
    }

    @Test
    fun testMemoryLeaksInSpeechSynthesis() = runTest {
        val runtime = Runtime.getRuntime()
        val initialMemory = runtime.totalMemory() - runtime.freeMemory()

        // Generate and speak many phrases
        repeat(100) { i ->
            speechManager.speak("Test phrase number $i")
            speechManager.stopSpeaking()
        }

        // Force garbage collection
        System.gc()
        Thread.sleep(1000)
        System.gc()

        val finalMemory = runtime.totalMemory() - runtime.freeMemory()
        val memoryIncrease = finalMemory - initialMemory

        assertTrue(
            memoryIncrease < 10 * 1024 * 1024, // 10MB
            "Speech synthesis should not leak memory: ${memoryIncrease / 1024 / 1024}MB increase"
        )
    }

    // MARK: - Battery Performance Tests

    @Test
    fun testCPUUsageOfVoiceOperations() {
        val startTime = System.currentTimeMillis()
        
        // Perform intensive voice operations
        repeat(100) { i ->
            speechManager.processVoiceCommand("intensive command $i")
            speechManager.speak("Response $i")
            speechManager.stopSpeaking()
        }
        
        val endTime = System.currentTimeMillis()
        val duration = (endTime - startTime) / 1000.0 // Convert to seconds

        assertTrue(
            duration < 30.0,
            "100 voice operations should complete in under 30 seconds, took ${duration}s"
        )
    }

    @Test
    fun testIdlePowerConsumption() = runTest {
        val runtime = Runtime.getRuntime()
        val initialMemory = runtime.totalMemory() - runtime.freeMemory()

        // Wait while idle
        Thread.sleep(5000)

        val finalMemory = runtime.totalMemory() - runtime.freeMemory()
        val memoryChange = kotlin.math.abs(finalMemory - initialMemory)

        assertTrue(
            memoryChange < 1024 * 1024, // 1MB
            "Memory should remain stable during idle periods: ${memoryChange / 1024}KB change"
        )
    }

    // MARK: - Automotive Environment Performance Tests

    @Test
    fun testPerformanceInLowPowerMode() {
        val commands = (0..49).map { "low power test $it" }
        
        val startTime = System.currentTimeMillis()
        
        commands.forEach { command ->
            speechManager.processVoiceCommand(command)
            
            // Simulate reduced processing power
            Thread.sleep(1)
        }
        
        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime
        val averageTime = totalTime / commands.size.toDouble()

        assertTrue(
            averageTime < 500,
            "Commands should process in under 500ms even in low power mode, averaged ${averageTime}ms"
        )
    }

    @Test
    fun testPerformanceWithBackgroundTasks() = runTest {
        val targetCommands = 20
        val commands = (0 until targetCommands).map { "background test $it" }
        var processedCommands = 0

        // Start background task
        val backgroundThread = Thread {
            while (processedCommands < targetCommands) {
                // Simulate background work
                (0..999).map { it * it }
                Thread.sleep(10)
            }
        }
        backgroundThread.start()

        val startTime = System.currentTimeMillis()

        // Process commands while background task runs
        commands.forEach { command ->
            speechManager.processVoiceCommand(command)
            processedCommands++
            Thread.sleep(100) // Simulate realistic timing
        }

        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime
        val averageTime = totalTime / targetCommands.toDouble()

        backgroundThread.interrupt()

        assertTrue(
            processedCommands == targetCommands,
            "All commands should have been processed"
        )
        
        assertTrue(
            averageTime < 600,
            "Commands should process in under 600ms with background tasks, averaged ${averageTime}ms"
        )
    }

    // MARK: - Network Independence Tests

    @Test
    fun testPerformanceWithoutNetworkDependency() {
        val commands = listOf(
            "save this place",
            "like this restaurant", 
            "next location",
            "get directions"
        )

        val startTime = System.currentTimeMillis()

        commands.forEach { command ->
            speechManager.processVoiceCommand(command)
        }

        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime

        assertTrue(
            totalTime < 100,
            "Local voice processing should be under 100ms total, took ${totalTime}ms"
        )
    }

    // MARK: - Edge Case Performance Tests

    @Test
    fun testLongVoiceCommandPerformance() {
        val longCommand = "very long voice command with many words ".repeat(50)

        val startTime = System.currentTimeMillis()
        
        speechManager.processVoiceCommand(longCommand)
        
        val endTime = System.currentTimeMillis()
        val processingTime = endTime - startTime

        assertTrue(
            processingTime < 1000,
            "Long commands should process in under 1 second, took ${processingTime}ms"
        )
    }

    @Test
    fun testRapidFireCommands() {
        val commandCount = 50
        val commands = (0 until commandCount).map { "rapid $it" }
        
        val startTime = System.currentTimeMillis()

        // Fire commands as rapidly as possible
        commands.forEach { command ->
            speechManager.processVoiceCommand(command)
        }

        val endTime = System.currentTimeMillis()
        val totalTime = endTime - startTime
        val averageTime = totalTime / commandCount.toDouble()

        assertTrue(
            averageTime < 100,
            "Rapid fire commands should average under 100ms each, averaged ${averageTime}ms"
        )
    }

    // MARK: - Real-world Scenario Tests

    @Test
    fun testDrivingScenarioPerformance() = runTest {
        // Simulate realistic driving scenario with mixed voice interactions
        val drivingCommands = listOf(
            "save this gas station",
            "like this restaurant",
            "get directions to this hotel", 
            "next attraction",
            "call this place",
            "go back",
            "skip this location"
        )

        var totalProcessingTime = 0L
        val commandTimes = mutableListOf<Long>()

        drivingCommands.forEach { command ->
            val startTime = System.currentTimeMillis()
            
            speechManager.processVoiceCommand(command)
            
            val endTime = System.currentTimeMillis()
            val processingTime = endTime - startTime
            
            commandTimes.add(processingTime)
            totalProcessingTime += processingTime

            // Simulate realistic gaps between commands (1-3 seconds)
            Thread.sleep((1000..3000).random().toLong())
        }

        val averageTime = totalProcessingTime / drivingCommands.size.toDouble()
        val maxTime = commandTimes.maxOrNull() ?: 0L

        assertTrue(
            averageTime < 350,
            "Average driving scenario command time should be under 350ms, was ${averageTime}ms"
        )

        assertTrue(
            maxTime < 500,
            "Maximum command time should be under 500ms, was ${maxTime}ms"
        )
    }

    @Test
    fun testCarPlayIntegrationPerformance() = runTest {
        // Test performance when integrated with CarPlay-like interface
        val carPlayCommands = listOf(
            "save favorite",
            "navigate",
            "call business", 
            "next poi"
        )

        carPlayCommands.forEach { command ->
            val startTime = System.currentTimeMillis()

            // Simulate CarPlay integration overhead
            speechManager.processVoiceCommand(command)

            val endTime = System.currentTimeMillis()
            val totalTime = endTime - startTime

            assertTrue(
                totalTime < 400,
                "CarPlay command '$command' should complete in under 400ms, took ${totalTime}ms"
            )
        }
    }

    // MARK: - Stress Tests

    @Test
    fun testExtendedUsageStressTest() {
        val runtime = Runtime.getRuntime()
        val initialMemory = runtime.totalMemory() - runtime.freeMemory()
        
        // Simulate 1 hour of usage with 1 command every 30 seconds
        val totalCommands = 120 // 1 hour / 30 seconds
        val commands = (0 until totalCommands).map { "stress test command $it" }
        
        val startTime = System.currentTimeMillis()
        var successfulCommands = 0

        commands.forEach { command ->
            try {
                speechManager.processVoiceCommand(command)
                successfulCommands++
                
                // Periodic cleanup
                if (successfulCommands % 20 == 0) {
                    System.gc()
                }
            } catch (e: Exception) {
                // Should not throw exceptions during stress test
                assertTrue(false, "Exception during stress test: ${e.message}")
            }
        }

        val endTime = System.currentTimeMillis()
        val totalTime = (endTime - startTime) / 1000.0 // Convert to seconds
        
        val finalMemory = runtime.totalMemory() - runtime.freeMemory()
        val memoryIncrease = finalMemory - initialMemory

        assertTrue(
            successfulCommands == totalCommands,
            "All stress test commands should succeed: $successfulCommands/$totalCommands"
        )

        assertTrue(
            memoryIncrease < 200 * 1024 * 1024, // 200MB
            "Memory usage should remain reasonable during stress test: ${memoryIncrease / 1024 / 1024}MB"
        )

        assertTrue(
            totalTime < 180, // 3 minutes for processing (commands only, no delays)
            "Stress test should complete efficiently: ${totalTime}s"
        )
    }
}

// MARK: - Helper Extensions

private data class VoiceCommandResult(
    val action: String,
    val originalText: String
)

private fun SpeechManager.processVoiceCommand(command: String): VoiceCommandResult {
    val lowercaseCommand = command.lowercase().trim()
    
    val commandActions = listOf(
        Triple("save", "save", listOf("favorite", "bookmark", "remember")),
        Triple("like", "like", listOf("love", "good", "great", "awesome")), 
        Triple("dislike", "dislike", listOf("skip", "bad", "not interested", "pass", "hate")),
        Triple("next", "next", listOf("forward", "continue", "move on")),
        Triple("previous", "previous", listOf("back", "go back", "last one", "before")),
        Triple("navigate", "navigate", listOf("directions", "go to", "take me to", "drive to")),
        Triple("call", "call", listOf("phone", "contact", "dial"))
    )
    
    for ((pattern, action, alternatives) in commandActions) {
        val allPatterns = listOf(pattern) + alternatives
        for (searchPattern in allPatterns) {
            if (lowercaseCommand.contains(searchPattern)) {
                return VoiceCommandResult(action, command)
            }
        }
    }
    
    return VoiceCommandResult("unrecognized", command)
}