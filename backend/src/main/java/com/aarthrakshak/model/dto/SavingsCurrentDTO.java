package com.aarthrakshak.model.dto;

public class SavingsCurrentDTO {

    private double monthlySavings;
    private double monthlyIncome;
    private double monthlyExpenses;
    private double currentSavingsRate;

    public SavingsCurrentDTO() {}

    public SavingsCurrentDTO(double monthlySavings, double monthlyIncome,
                             double monthlyExpenses, double currentSavingsRate) {
        this.monthlySavings = monthlySavings;
        this.monthlyIncome = monthlyIncome;
        this.monthlyExpenses = monthlyExpenses;
        this.currentSavingsRate = currentSavingsRate;
    }

    public double getMonthlySavings() { return monthlySavings; }
    public void setMonthlySavings(double monthlySavings) { this.monthlySavings = monthlySavings; }

    public double getMonthlyIncome() { return monthlyIncome; }
    public void setMonthlyIncome(double monthlyIncome) { this.monthlyIncome = monthlyIncome; }

    public double getMonthlyExpenses() { return monthlyExpenses; }
    public void setMonthlyExpenses(double monthlyExpenses) { this.monthlyExpenses = monthlyExpenses; }

    public double getCurrentSavingsRate() { return currentSavingsRate; }
    public void setCurrentSavingsRate(double currentSavingsRate) { this.currentSavingsRate = currentSavingsRate; }
}
