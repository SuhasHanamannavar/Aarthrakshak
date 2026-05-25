package com.aarthrakshak.model.dto;

import java.util.List;

public class DashboardSummaryDTO {

    private double balance;
    private double monthlySpend;
    private double monthlySavings;
    private int healthScore;
    private List<TransactionDTO> transactions;

    public DashboardSummaryDTO() {}

    public DashboardSummaryDTO(double balance, double monthlySpend,
                               double monthlySavings, int healthScore,
                               List<TransactionDTO> transactions) {
        this.balance = balance;
        this.monthlySpend = monthlySpend;
        this.monthlySavings = monthlySavings;
        this.healthScore = healthScore;
        this.transactions = transactions;
    }

    public double getBalance() { return balance; }
    public void setBalance(double balance) { this.balance = balance; }

    public double getMonthlySpend() { return monthlySpend; }
    public void setMonthlySpend(double monthlySpend) { this.monthlySpend = monthlySpend; }

    public double getMonthlySavings() { return monthlySavings; }
    public void setMonthlySavings(double monthlySavings) { this.monthlySavings = monthlySavings; }

    public int getHealthScore() { return healthScore; }
    public void setHealthScore(int healthScore) { this.healthScore = healthScore; }

    public List<TransactionDTO> getTransactions() { return transactions; }
    public void setTransactions(List<TransactionDTO> transactions) { this.transactions = transactions; }
}
