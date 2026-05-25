package com.aarthrakshak.service;

import com.aarthrakshak.model.dto.TransactionDTO;
import com.aarthrakshak.model.entity.Transaction;
import com.aarthrakshak.repository.TransactionRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Random;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final GroqService groqService;
    private final Random random = new Random();

    public TransactionService(TransactionRepository transactionRepository,
                              GroqService groqService) {
        this.transactionRepository = transactionRepository;
        this.groqService = groqService;
    }

    public List<TransactionDTO> getAllTransactions() {
        return transactionRepository.findAllByOrderByTransactionDateDesc()
                .stream()
                .map(TransactionDTO::fromEntity)
                .collect(Collectors.toList());
    }

    public Optional<TransactionDTO> getTransactionById(UUID id) {
        return transactionRepository.findById(id)
                .map(TransactionDTO::fromEntity);
    }

    public List<TransactionDTO> getFraudHistory() {
        return transactionRepository.findByIsFraudulentTrueOrderByTransactionDateDesc()
                .stream()
                .map(TransactionDTO::fromEntity)
                .collect(Collectors.toList());
    }

    public TransactionDTO analyzeFraud(String transactionId) {
        try {
            UUID id = UUID.fromString(transactionId);
            Optional<Transaction> opt = transactionRepository.findById(id);
            if (opt.isPresent()) {
                Transaction t = opt.get();
                boolean isFraud = random.nextDouble() > 0.3;
                double score = 0.3 + random.nextDouble() * 0.7;
                t.setFraudulent(isFraud);
                java.math.BigDecimal bd = java.math.BigDecimal.valueOf(score * 100);
                t.setFraudScore(bd);
                transactionRepository.save(t);
                return TransactionDTO.fromEntity(t);
            }
        } catch (IllegalArgumentException ignored) {}
        return null;
    }

    public boolean markSafe(String transactionId) {
        try {
            UUID id = UUID.fromString(transactionId);
            Optional<Transaction> opt = transactionRepository.findById(id);
            if (opt.isPresent()) {
                Transaction t = opt.get();
                t.setFraudulent(false);
                t.setFraudScore(java.math.BigDecimal.ZERO);
                transactionRepository.save(t);
                return true;
            }
        } catch (IllegalArgumentException ignored) {}
        return false;
    }

    public boolean reportFraud(String transactionId) {
        try {
            UUID id = UUID.fromString(transactionId);
            Optional<Transaction> opt = transactionRepository.findById(id);
            if (opt.isPresent()) {
                Transaction t = opt.get();
                t.setFraudulent(true);
                t.setFraudScore(java.math.BigDecimal.valueOf(95));
                transactionRepository.save(t);
                return true;
            }
        } catch (IllegalArgumentException ignored) {}
        return false;
    }

    public DashboardData getDashboardData() {
        List<Transaction> all = transactionRepository.findAllByOrderByTransactionDateDesc();
        List<TransactionDTO> dtos = all.stream()
                .map(TransactionDTO::fromEntity)
                .collect(Collectors.toList());

        double balance = all.stream()
                .mapToDouble(t -> t.getAmount().doubleValue())
                .sum();

        double monthlySpend = balance * 0.15;
        double monthlySavings = balance * 0.2;
        int healthScore = 72;

        if (groqService.hasKeys() && !all.isEmpty()) {
            try {
                Transaction last = all.get(0);
                String prompt = String.format(
                    "Given financial data: balance=%.2f, monthlySpend=%.2f, monthlySavings=%.2f, recentTransaction=%s. " +
                    "Respond with JSON: {\"healthScore\":0-100,\"monthlySpend\":number,\"monthlySavings\":number}",
                    balance, monthlySpend, monthlySavings, last.getMerchantName()
                );
                String json = groqService.completeJson(
                    "You are a financial health analyst. Score users 0-100 based on spending patterns.",
                    prompt, "llama3-8b-8192"
                );
                if (json != null) {
                    com.fasterxml.jackson.databind.ObjectMapper m = new com.fasterxml.jackson.databind.ObjectMapper();
                    Map<String, Object> result = m.readValue(json,
                            new com.fasterxml.jackson.core.type.TypeReference<Map<String, Object>>() {});
                    healthScore = ((Number) result.getOrDefault("healthScore", 72)).intValue();
                    monthlySpend = ((Number) result.getOrDefault("monthlySpend", monthlySpend)).doubleValue();
                    monthlySavings = ((Number) result.getOrDefault("monthlySavings", monthlySavings)).doubleValue();
                }
            } catch (Exception ignored) {}
        }

        return new DashboardData(balance, monthlySpend, monthlySavings, healthScore, dtos);
    }

    public static class DashboardData {
        private final double balance;
        private final double monthlySpend;
        private final double monthlySavings;
        private final int healthScore;
        private final List<TransactionDTO> transactions;

        public DashboardData(double balance, double monthlySpend,
                             double monthlySavings, int healthScore,
                             List<TransactionDTO> transactions) {
            this.balance = balance;
            this.monthlySpend = monthlySpend;
            this.monthlySavings = monthlySavings;
            this.healthScore = healthScore;
            this.transactions = transactions;
        }

        public double getBalance() { return balance; }
        public double getMonthlySpend() { return monthlySpend; }
        public double getMonthlySavings() { return monthlySavings; }
        public int getHealthScore() { return healthScore; }
        public List<TransactionDTO> getTransactions() { return transactions; }
    }
}
