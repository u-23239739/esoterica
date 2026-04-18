package com.example.demo.repository;

import com.example.demo.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    Optional<Transaction> findByTransactionNumber(String transactionNumber);
    Optional<Transaction> findByGatewayTransactionId(String gatewayTransactionId);
    List<Transaction> findByOrderId(Long orderId);
    List<Transaction> findByStatus(String status);
    List<Transaction> findByCreatedAtBetween(LocalDateTime start, LocalDateTime end);
}

