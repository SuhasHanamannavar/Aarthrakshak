package com.aarthrakshak.model.dto;

public class FraudCheckRequest {

    private String transactionId;

    public FraudCheckRequest() {}

    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String transactionId) { this.transactionId = transactionId; }
}
