package com.echofinder.api.health;

import java.time.Instant;

public record HealthResponse(
        String status,
        String service,
        String version,
        Instant time
) {
    public static HealthResponse ok() {
        return new HealthResponse(
                "ok",
                "echofinder-api",
                "dev",
                Instant.now()
        );
    }
}