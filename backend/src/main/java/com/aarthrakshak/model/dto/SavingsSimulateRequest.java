package com.aarthrakshak.model.dto;

public class SavingsSimulateRequest {

    private double monthlyContribution;
    private double annualReturnRate;
    private double goalAmount;
    private int timelineMonths;

    public SavingsSimulateRequest() {}

    public double getMonthlyContribution() { return monthlyContribution; }
    public void setMonthlyContribution(double monthlyContribution) { this.monthlyContribution = monthlyContribution; }

    public double getAnnualReturnRate() { return annualReturnRate; }
    public void setAnnualReturnRate(double annualReturnRate) { this.annualReturnRate = annualReturnRate; }

    public double getGoalAmount() { return goalAmount; }
    public void setGoalAmount(double goalAmount) { this.goalAmount = goalAmount; }

    public int getTimelineMonths() { return timelineMonths; }
    public void setTimelineMonths(int timelineMonths) { this.timelineMonths = timelineMonths; }
}
