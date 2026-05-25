package com.aarthrakshak.repository;

import com.aarthrakshak.model.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    List<Transaction> findByUserIdOrderByTransactionDateDesc(UUID userId);

    List<Transaction> findAllByOrderByTransactionDateDesc();

    List<Transaction> findByIsFraudulentTrueOrderByTransactionDateDesc();
}
