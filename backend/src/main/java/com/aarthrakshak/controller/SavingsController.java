package com.aarthrakshak.controller;

import com.aarthrakshak.model.dto.SavingsCurrentDTO;
import com.aarthrakshak.model.dto.SavingsSimulateRequest;
import com.aarthrakshak.model.dto.SavingsSimulateResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api")
public class SavingsController {

    @GetMapping("/savings/current")
    public ResponseEntity<SavingsCurrentDTO> getCurrentSavings() {
        return ResponseEntity.ok(new SavingsCurrentDTO(8000, 50000, 32000, 16.0));
    }

    @PostMapping("/savings/simulate")
    public ResponseEntity<SavingsSimulateResponse> simulateSavings(
            @RequestBody SavingsSimulateRequest req) {
        double r = req.getAnnualReturnRate() / 100.0;
        double monthlyRate = r / 12;
        int n = req.getTimelineMonths();
        double m = req.getMonthlyContribution();

        List<Double> projected = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            double val;
            if (monthlyRate == 0) {
                val = m * (i + 1);
            } else {
                val = m * (Math.pow(1 + monthlyRate, i + 1) - 1) / monthlyRate;
            }
            projected.add(Math.round(val * 100.0) / 100.0);
        }

        double totalContributions = m * n;
        double totalInterest = projected.isEmpty() ? 0 :
                projected.get(projected.size() - 1) - totalContributions;

        int monthsToGoal = -1;
        for (int i = 0; i < projected.size(); i++) {
            if (projected.get(i) >= req.getGoalAmount()) {
                monthsToGoal = i + 1;
                break;
            }
        }

        boolean achievable = monthsToGoal > 0 && monthsToGoal <= n;
        if (!achievable) monthsToGoal = n;

        return ResponseEntity.ok(new SavingsSimulateResponse(
                projected, monthsToGoal,
                Math.round(totalInterest * 100.0) / 100.0, achievable
        ));
    }
}
