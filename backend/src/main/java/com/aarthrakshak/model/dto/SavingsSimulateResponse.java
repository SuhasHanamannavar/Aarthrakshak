package com.aarthrakshak.model.dto;

import java.util.List;

public class SavingsSimulateResponse {

    private List<Double> projectedSavings;
    private int monthsToGoal;
    private double totalInterestEarned;
    private boolean achievable;

    public SavingsSimulateResponse() {}

    public SavingsSimulateResponse(List<Double> projectedSavings, int monthsToGoal,
                                   double totalInterestEarned, boolean achievable) {
        this.projectedSavings = projectedSavings;
        this.monthsToGoal = monthsToGoal;
        this.totalInterestEarned = totalInterestEarned;
        this.achievable = achievable;
    }

    public List<Double> getProjectedSavings() { return projectedSavings; }
    public void setProjectedSavings(List<Double> projectedSavings) { this.projectedSavings = projectedSavings; }

    public int getMonthsToGoal() { return monthsToGoal; }
    public void setMonthsToGoal(int monthsToGoal) { this.monthsToGoal = monthsToGoal; }

    public double getTotalInterestEarned() { return totalInterestEarned; }
    public void setTotalInterestEarned(double totalInterestEarned) { this.totalInterestEarned = totalInterestEarned; }

    public boolean isAchievable() { return achievable; }
    public void setAchievable(boolean achievable) { this.achievable = achievable; }
}
