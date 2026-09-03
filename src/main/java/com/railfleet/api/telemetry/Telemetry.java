package com.railfleet.api.telemetry;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "telemetry")
public class Telemetry {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 50)
    private String locomotiveId;

    @Column(nullable = false)
    private Double engineTemperature;

    @Column(nullable = false)
    private Double fuelLevel;

    @Column(nullable = false)
    private Double batteryVoltage;

    @Column(nullable = false)
    private Double speed;

    @Column(nullable = false)
    private Double engineHours;

    @Column(nullable = false)
    private OffsetDateTime recordedAt;

    protected Telemetry() {}

    public Telemetry(String locomotiveId, Double engineTemperature, Double fuelLevel,
                     Double batteryVoltage, Double speed, Double engineHours) {
        this.locomotiveId = locomotiveId;
        this.engineTemperature = engineTemperature;
        this.fuelLevel = fuelLevel;
        this.batteryVoltage = batteryVoltage;
        this.speed = speed;
        this.engineHours = engineHours;
        this.recordedAt = OffsetDateTime.now();
    }

    public Long getId() { return id; }
    public String getLocomotiveId() { return locomotiveId; }
    public Double getEngineTemperature() { return engineTemperature; }
    public Double getFuelLevel() { return fuelLevel; }
    public Double getBatteryVoltage() { return batteryVoltage; }
    public Double getSpeed() { return speed; }
    public Double getEngineHours() { return engineHours; }
    public OffsetDateTime getRecordedAt() { return recordedAt; }
}