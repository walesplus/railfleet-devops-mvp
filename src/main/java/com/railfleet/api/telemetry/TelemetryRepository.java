package com.railfleet.api.telemetry;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface TelemetryRepository extends JpaRepository<Telemetry, Long> {
    List<Telemetry> findByLocomotiveIdOrderByRecordedAtDesc(String locomotiveId);
}
