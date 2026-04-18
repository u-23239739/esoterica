package com.example.demo.repository;

import com.example.demo.entity.StockMovement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface StockMovementRepository extends JpaRepository<StockMovement, Long> {
    List<StockMovement> findByProductId(Long productId);
    List<StockMovement> findByWarehouseId(Long warehouseId);
    List<StockMovement> findByMovementType(String movementType);
    List<StockMovement> findByCreatedAtBetween(LocalDateTime start, LocalDateTime end);
}

