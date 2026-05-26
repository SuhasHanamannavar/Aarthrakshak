package com.aarthrakshak.service;

import com.aarthrakshak.model.entity.Transaction;
import com.aarthrakshak.repository.TransactionRepository;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.core.type.TypeReference;

import java.io.InputStream;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.*;
import com.aarthrakshak.model.enums.TransactionCategory;

@Service
public class StatementService {

    private final GroqService groqService;
    private final TransactionRepository transactionRepository;
    private final ObjectMapper mapper = new ObjectMapper();

    public StatementService(GroqService groqService, TransactionRepository transactionRepository) {
        this.groqService = groqService;
        this.transactionRepository = transactionRepository;
    }

    public Map<String, Object> processBankStatement(MultipartFile file) throws Exception {
        String text = extractTextFromPdf(file.getBytes());
        if (text.length() > 6000) {
            text = text.substring(0, 6000); // Truncate to avoid token limits for demo
        }

        if (!groqService.hasKeys()) {
            throw new Exception("Groq API keys not configured. Cannot process statement.");
        }

        String systemPrompt = "You are a financial data extraction AI. Given the raw text of a bank statement, extract all transactions." +
                " Respond STRICTLY with a valid JSON object matching this structure: " +
                "{\"summary\": {\"totalSpend\": 1500.0, \"topCategory\": \"Food\"}, " +
                "\"transactions\": [" +
                "{\"merchant\": \"Uber\", \"amount\": 25.50, \"category\": \"Transport\"}" +
                "]}. " +
                "Do not include any explanations, markdown formatting, or text outside the JSON object.";

        String userPrompt = "Bank Statement Text:\n" + text;

        String jsonResponse = groqService.completeJson(systemPrompt, userPrompt, "llama3-8b-8192");
        
        if (jsonResponse == null || jsonResponse.isEmpty()) {
            throw new Exception("Failed to retrieve parsed JSON from Groq AI.");
        }

        try {
            return mapper.readValue(jsonResponse, new TypeReference<Map<String, Object>>() {});
        } catch (Exception e) {
            throw new Exception("Groq AI returned malformed JSON: " + jsonResponse, e);
        }
    }

    public void saveTransactions(List<Map<String, Object>> transactionsData, UUID userId) {
        if (transactionsData == null || transactionsData.isEmpty()) return;

        List<Transaction> entities = new ArrayList<>();
        for (Map<String, Object> txData : transactionsData) {
            Transaction t = new Transaction();
            t.setUserId(userId);
            t.setMerchantName(txData.get("merchant") != null ? txData.get("merchant").toString() : "Unknown");
            
            Object amountObj = txData.get("amount");
            if (amountObj instanceof Number) {
                t.setAmount(new BigDecimal(((Number) amountObj).doubleValue()));
            } else if (amountObj != null) {
                try {
                    t.setAmount(new BigDecimal(amountObj.toString()));
                } catch (Exception e) {
                    t.setAmount(BigDecimal.ZERO);
                }
            } else {
                t.setAmount(BigDecimal.ZERO);
            }

            String catString = txData.get("category") != null ? txData.get("category").toString().toLowerCase() : "other";
            try {
                t.setCategory(TransactionCategory.valueOf(catString));
            } catch (Exception e) {
                t.setCategory(TransactionCategory.other);
            }
            
            t.setTransactionDate(OffsetDateTime.now().minusDays(new Random().nextInt(30)));
            t.setMerchantLocation("Online");
            t.setFraudulent(false);
            t.setFraudScore(BigDecimal.ZERO);
            entities.add(t);
        }
        
        transactionRepository.saveAll(entities);
    }

    private String extractTextFromPdf(byte[] bytes) throws Exception {
        try (PDDocument document = org.apache.pdfbox.Loader.loadPDF(bytes)) {
            PDFTextStripper stripper = new PDFTextStripper();
            return stripper.getText(document);
        }
    }
}
