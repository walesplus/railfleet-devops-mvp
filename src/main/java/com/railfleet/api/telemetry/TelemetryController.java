package com.railfleet.api.telemetry;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/telemetry")
public class TelemetryController {
    private final TelemetryRepository repository;

    public TelemetryController(TelemetryRepository repository) {
        this.repository = repository;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Telemetry create(@Valid @RequestBody TelemetryRequest request) {
        return repository.save(new Telemetry(
                request.locomotiveId(),
                request.engineTemperature(),
                request.fuelLevel(),
                request.batteryVoltage(),
                request.speed(),
                request.engineHours()
        ));
    }

    @GetMapping
    public List<Telemetry> all() {
        return repository.findAll();
    }

    @GetMapping("/{id}")
    public Telemetry one(@PathVariable Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Telemetry not found: " + id));
    }

    @GetMapping("/locomotive/{locomotiveId}")
    public List<Telemetry> byLocomotive(@PathVariable String locomotiveId) {
        return repository.findByLocomotiveIdOrderByRecordedAtDesc(locomotiveId);
    }
}