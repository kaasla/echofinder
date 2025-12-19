package com.echofinder.api.health;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.echofinder.api.infra.CorrelationIdFilter;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(HealthController.class)
@Import(CorrelationIdFilter.class)
class HealthControllerMockMvcTest {

  @Autowired private MockMvc mockMvc;

  @Test
  void healthEndpointReturnsOkStatus() throws Exception {
    mockMvc
        .perform(get("/api/health"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("ok"))
        .andExpect(jsonPath("$.service").value("echofinder-api"))
        .andExpect(jsonPath("$.version").value("dev"))
        .andExpect(jsonPath("$.time").exists());
  }

  @Test
  void healthEndpointReturnsCorrelationIdHeader() throws Exception {
    mockMvc
        .perform(get("/api/health"))
        .andExpect(status().isOk())
        .andExpect(header().exists("X-Correlation-Id"));
  }

  @Test
  void healthEndpointEchoesProvidedCorrelationId() throws Exception {
    String correlationId = "test-correlation-id-123";

    mockMvc
        .perform(get("/api/health").header("X-Correlation-Id", correlationId))
        .andExpect(status().isOk())
        .andExpect(header().string("X-Correlation-Id", correlationId));
  }
}
