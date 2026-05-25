package com.aarthrakshak.model.dto;

public class FraudCheckResponse {

    private boolean isFraudulent;
    private double fraudScore;
    private String reason;
    private String location;
    private String deviceFingerprint;
    private String recommendedAction;

    public FraudCheckResponse() {}

    public FraudCheckResponse(boolean isFraudulent, double fraudScore,
                              String reason, String location,
                              String deviceFingerprint, String recommendedAction) {
        this.isFraudulent = isFraudulent;
        this.fraudScore = fraudScore;
        this.reason = reason;
        this.location = location;
        this.deviceFingerprint = deviceFingerprint;
        this.recommendedAction = recommendedAction;
    }

    public boolean isFraudulent() { return isFraudulent; }
    public void setFraudulent(boolean fraudulent) { isFraudulent = fraudulent; }

    public double getFraudScore() { return fraudScore; }
    public void setFraudScore(double fraudScore) { this.fraudScore = fraudScore; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getDeviceFingerprint() { return deviceFingerprint; }
    public void setDeviceFingerprint(String deviceFingerprint) { this.deviceFingerprint = deviceFingerprint; }

    public String getRecommendedAction() { return recommendedAction; }
    public void setRecommendedAction(String recommendedAction) { this.recommendedAction = recommendedAction; }
}
