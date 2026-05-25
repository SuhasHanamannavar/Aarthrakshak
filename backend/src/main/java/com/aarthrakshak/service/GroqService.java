package com.aarthrakshak.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

@Service
public class GroqService {

    private final List<String> apiKeys;
    private final AtomicInteger keyIndex = new AtomicInteger(0);
    private final RestTemplate restTemplate;
    private static final String GROQ_URL = "https://api.groq.com/openai/v1/chat/completions";

    public GroqService(
            @Value("${GROQ_API_KEY_1:}") String key1,
            @Value("${GROQ_API_KEY_2:}") String key2,
            @Value("${GROQ_API_KEY_3:}") String key3,
            @Value("${GROQ_API_KEY_4:}") String key4,
            @Value("${GROQ_API_KEY_5:}") String key5,
            @Value("${GROQ_API_KEY_6:}") String key6,
            @Value("${GROQ_API_KEY_7:}") String key7,
            @Value("${GROQ_API_KEY_8:}") String key8,
            @Value("${GROQ_API_KEY_9:}") String key9,
            @Value("${GROQ_API_KEY_10:}") String key10) {
        this.restTemplate = new RestTemplate();
        this.apiKeys = new ArrayList<>();
        for (String k : Arrays.asList(key1, key2, key3, key4, key5, key6, key7, key8, key9, key10)) {
            if (k != null && !k.isEmpty()) apiKeys.add(k);
        }
    }

    public String complete(String systemPrompt, String userPrompt, String model, double temperature, int maxTokens) {
        if (apiKeys.isEmpty()) return null;

        Map<String, Object> request = new LinkedHashMap<>();
        request.put("model", model);
        request.put("temperature", temperature);
        request.put("max_tokens", maxTokens);

        List<Map<String, String>> messages = new ArrayList<>();
        if (systemPrompt != null && !systemPrompt.isEmpty()) {
            messages.add(Map.of("role", "system", "content", systemPrompt));
        }
        messages.add(Map.of("role", "user", "content", userPrompt));
        request.put("messages", messages);

        int attempts = 0;
        while (attempts < apiKeys.size()) {
            int idx = keyIndex.getAndIncrement() % apiKeys.size();
            String key = apiKeys.get(idx);
            try {
                HttpHeaders headers = new HttpHeaders();
                headers.setBearerAuth(key);
                headers.setContentType(MediaType.APPLICATION_JSON);
                HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);
                ResponseEntity<Map> resp = restTemplate.exchange(GROQ_URL, HttpMethod.POST, entity, Map.class);
                if (resp.getStatusCode() == HttpStatus.OK && resp.getBody() != null) {
                    List<Map> choices = (List<Map>) resp.getBody().get("choices");
                    if (choices != null && !choices.isEmpty()) {
                        Map message = (Map) choices.get(0).get("message");
                        return (String) message.get("content");
                    }
                }
            } catch (Exception e) {
                attempts++;
            }
        }
        return null;
    }

    public String completeJson(String systemPrompt, String userPrompt, String model) {
        String result = complete(systemPrompt,
                "Respond with valid JSON only, no markdown, no explanation.\n\n" + userPrompt,
                model, 0.3, 1024);
        if (result == null) return null;
        result = result.trim();
        if (result.startsWith("```json")) {
            int start = result.indexOf('\n') + 1;
            int end = result.lastIndexOf("```");
            if (end > start) result = result.substring(start, end).trim();
        } else if (result.startsWith("```")) {
            int start = result.indexOf('\n') + 1;
            int end = result.lastIndexOf("```");
            if (end > start) result = result.substring(start, end).trim();
        }
        return result;
    }

    public String complete(String userPrompt, String model) {
        return complete(null, userPrompt, model, 0.7, 1024);
    }

    public boolean hasKeys() {
        return !apiKeys.isEmpty();
    }

    public int keyCount() {
        return apiKeys.size();
    }
}
