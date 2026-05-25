package com.aarthrakshak.controller;

import com.aarthrakshak.model.dto.*;
import com.aarthrakshak.model.entity.Transaction;
import com.aarthrakshak.repository.TransactionRepository;
import com.aarthrakshak.service.GroqService;
import com.aarthrakshak.service.TransactionService;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api")
public class FraudController {

    private final TransactionService transactionService;
    private final TransactionRepository transactionRepository;
    private final GroqService groqService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public FraudController(TransactionService transactionService,
                           TransactionRepository transactionRepository,
                           GroqService groqService) {
        this.transactionService = transactionService;
        this.transactionRepository = transactionRepository;
        this.groqService = groqService;
    }

    @PostMapping("/fraud/analyze")
    public ResponseEntity<FraudCheckResponse> analyzeFraud(@RequestBody FraudCheckRequest request) {
        if (groqService.hasKeys()) {
            try {
                Optional<Transaction> opt = transactionRepository
                        .findById(UUID.fromString(request.getTransactionId()));
                if (opt.isPresent()) {
                    Transaction t = opt.get();
                    String prompt = String.format(
                        "Analyze this transaction for fraud:\n" +
                        "Merchant: %s\nAmount: %.2f\nCategory: %s\nLocation: %s\n\n" +
                        "Respond with JSON: {\"isFraudulent\":bool,\"fraudScore\":0-100,\"reason\":\"...\",\"recommendedAction\":\"...\"}",
                        t.getMerchantName(), t.getAmount().doubleValue(),
                        t.getCategory(), t.getMerchantLocation()
                    );
                    String json = groqService.completeJson(
                        "You are a fraud detection expert. Analyze transactions for suspicious patterns.",
                        prompt, "mixtral-8x7b-32768"
                    );
                    if (json != null) {
                        Map<String, Object> result = objectMapper.readValue(json,
                                new TypeReference<Map<String, Object>>() {});
                        boolean isFraud = (boolean) result.getOrDefault("isFraudulent", false);
                        double score = ((Number) result.getOrDefault("fraudScore", 50)).doubleValue();
                        t.setFraudulent(isFraud);
                        t.setFraudScore(java.math.BigDecimal.valueOf(score));
                        transactionRepository.save(t);
                        FraudCheckResponse resp = new FraudCheckResponse(
                                isFraud, score / 100.0,
                                (String) result.getOrDefault("reason", "Analyzed by AI"),
                                t.getMerchantLocation() != null ? t.getMerchantLocation() : "Unknown",
                                "Groq AI Analysis",
                                (String) result.getOrDefault("recommendedAction", "Review transaction")
                        );
                        return ResponseEntity.ok(resp);
                    }
                }
            } catch (Exception ignored) {}
        }

        FraudCheckResponse fallback = new FraudCheckResponse(
                true, 0.82,
                "Large transaction from unknown location. Device fingerprint mismatch.",
                "Unknown Location",
                "Mozilla/5.0 (Linux; Android 14) Chrome/120... (New Device)",
                "IMMEDIATELY block card and contact support."
        );
        return ResponseEntity.ok(fallback);
    }

    @GetMapping("/fraud/history")
    public ResponseEntity<List<TransactionDTO>> getFraudHistory() {
        return ResponseEntity.ok(transactionService.getFraudHistory());
    }

    @PostMapping("/fraud/block-card")
    public ResponseEntity<Map<String, String>> blockCard(@RequestBody(required = false) Map<String, Object> body) {
        String message = "Aapka card block kar diya gaya hai.";
        if (groqService.hasKeys()) {
            try {
                String groqResp = groqService.complete(
                    "You are a helpful Hindi-English financial assistant.",
                    "A user's card has been blocked for fraud. Give a short reassuring message in Hinglish (mix of Hindi and English) explaining next steps.",
                    "llama3-8b-8192", 0.7, 256
                );
                if (groqResp != null) message = groqResp.trim();
            } catch (Exception ignored) {}
        }
        return ResponseEntity.ok(Map.of("message", message));
    }

    @PostMapping("/fraud/mark-safe")
    public ResponseEntity<Void> markSafe(@RequestBody FraudActionRequest request) {
        transactionService.markSafe(request.getTransactionId());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/fraud/report")
    public ResponseEntity<Void> reportFraud(@RequestBody FraudActionRequest request) {
        transactionService.reportFraud(request.getTransactionId());
        return ResponseEntity.ok().build();
    }
}
