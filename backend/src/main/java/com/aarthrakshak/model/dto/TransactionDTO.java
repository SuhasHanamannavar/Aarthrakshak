package com.aarthrakshak.model.dto;

import com.aarthrakshak.model.entity.Transaction;

public class TransactionDTO {

    private String id;
    private double amount;
    private String merchant;
    private String category;
    private String timestamp;
    private boolean isFraudulent;
    private double fraudScore;
    private String location;

    public TransactionDTO() {}

    public static TransactionDTO fromEntity(Transaction t) {
        TransactionDTO dto = new TransactionDTO();
        dto.id = t.getId().toString();
        dto.amount = t.getAmount().doubleValue();
        dto.merchant = t.getMerchantName() != null ? t.getMerchantName() : "";
        dto.category = t.getCategory() != null ? t.getCategory().name() : "other";
        dto.timestamp = t.getTransactionDate() != null
                ? t.getTransactionDate().toString()
                : (t.getCreatedAt() != null ? t.getCreatedAt().toString() : "");
        dto.isFraudulent = t.isFraudulent();
        dto.fraudScore = t.getFraudScore() != null
                ? t.getFraudScore().doubleValue() / 100.0
                : 0.0;
        dto.location = t.getMerchantLocation() != null ? t.getMerchantLocation() : "";
        return dto;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public double getAmount() { return amount; }
    public void setAmount(double amount) { this.amount = amount; }

    public String getMerchant() { return merchant; }
    public void setMerchant(String merchant) { this.merchant = merchant; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getTimestamp() { return timestamp; }
    public void setTimestamp(String timestamp) { this.timestamp = timestamp; }

    public boolean isFraudulent() { return isFraudulent; }
    public void setFraudulent(boolean fraudulent) { isFraudulent = fraudulent; }

    public double getFraudScore() { return fraudScore; }
    public void setFraudScore(double fraudScore) { this.fraudScore = fraudScore; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }
}
