package com.railfleet.api.telemetry;

import jakarta.validation.constraints.*;

public record TelemetryRequest(
        @NotBlank @Size(max = 50) String locomotiveId,
        @NotNull @DecimalMin("-50.0") @DecimalMax("200.0") Double engineTemperature,
        @NotNull @DecimalMin("0.0") @DecimalMax("100.0") Double fuelLevel,
        @NotNull @DecimalMin("0.0") @DecimalMax("100.0") Double batteryVoltage,
        @NotNull @DecimalMin("0.0") @DecimalMax("300.0") Double speed,
        @NotNull @DecimalMin("0.0") Double engineHours
) {}