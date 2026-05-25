package com.aarthrakshak.controller;

import com.aarthrakshak.model.dto.DashboardSummaryDTO;
import com.aarthrakshak.service.TransactionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class DashboardController {

    private final TransactionService transactionService;

    public DashboardController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @GetMapping("/dashboard/summary")
    public ResponseEntity<DashboardSummaryDTO> getDashboardSummary() {
        TransactionService.DashboardData data = transactionService.getDashboardData();
        DashboardSummaryDTO dto = new DashboardSummaryDTO(
                data.getBalance(),
                data.getMonthlySpend(),
                data.getMonthlySavings(),
                data.getHealthScore(),
                data.getTransactions()
        );
        return ResponseEntity.ok(dto);
    }
}
