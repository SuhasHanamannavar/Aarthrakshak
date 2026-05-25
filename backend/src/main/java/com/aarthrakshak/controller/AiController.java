package com.aarthrakshak.controller;

import com.aarthrakshak.service.GroqService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/ai")
public class AiController {

    private final GroqService groqService;

    public AiController(GroqService groqService) {
        this.groqService = groqService;
    }

    @PostMapping("/complete")
    public ResponseEntity<?> complete(@RequestBody Map<String, Object> request) {
        if (!groqService.hasKeys()) {
            return ResponseEntity.ok(Map.of(
                    "error", "No Groq API keys configured",
                    "mock", true
            ));
        }
        String systemPrompt = (String) request.getOrDefault("systemPrompt", "");
        String userPrompt = (String) request.get("prompt");
        String model = (String) request.getOrDefault("model", "mixtral-8x7b-32768");
        double temperature = ((Number) request.getOrDefault("temperature", 0.7)).doubleValue();
        int maxTokens = ((Number) request.getOrDefault("maxTokens", 1024)).intValue();
        boolean expectJson = (boolean) request.getOrDefault("responseFormat", "json").equals("json");

        if (userPrompt == null || userPrompt.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "prompt is required"));
        }

        String result;
        if (expectJson) {
            result = groqService.completeJson(systemPrompt, userPrompt, model);
        } else {
            result = groqService.complete(systemPrompt, userPrompt, model, temperature, maxTokens);
        }

        if (result == null) {
            return ResponseEntity.ok(Map.of(
                    "error", "Groq API unavailable",
                    "mock", true
            ));
        }

        return ResponseEntity.ok(Map.of("content", result));
    }

    @GetMapping("/keys/status")
    public ResponseEntity<Map<String, Object>> keyStatus() {
        return ResponseEntity.ok(Map.of(
                "configured", groqService.hasKeys(),
                "keyCount", groqService.keyCount()
        ));
    }
}
