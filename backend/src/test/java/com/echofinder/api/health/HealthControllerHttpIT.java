package com.echofinder.api.health;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class HealthControllerHttpIT {

  @LocalServerPort private int port;

  @Autowired private TestRestTemplate restTemplate;

  @Test
  void healthEndpointReturnsOkOverHttp() {
    String url = "http://localhost:" + port + "/api/health";

    ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);

    assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    assertThat(response.getBody()).isNotNull();
    assertThat(response.getBody().get("status")).isEqualTo("ok");
    assertThat(response.getBody().get("service")).isEqualTo("echofinder-api");
    assertThat(response.getBody().get("version")).isEqualTo("dev");
    assertThat(response.getBody().get("time")).isNotNull();
  }

  @Test
  void healthEndpointGeneratesCorrelationIdWhenMissing() {
    String url = "http://localhost:" + port + "/api/health";

    ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);

    assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    assertThat(response.getHeaders().getFirst("X-Correlation-Id")).isNotBlank();
  }

  @Test
  void healthEndpointEchoesProvidedCorrelationId() {
    String url = "http://localhost:" + port + "/api/health";
    String correlationId = "integration-test-correlation-id";

    HttpHeaders headers = new HttpHeaders();
    headers.set("X-Correlation-Id", correlationId);
    HttpEntity<Void> request = new HttpEntity<>(headers);

    ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, request, Map.class);

    assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    assertThat(response.getHeaders().getFirst("X-Correlation-Id")).isEqualTo(correlationId);
  }

  @Test
  void unknownPathReturns404WithErrorEnvelope() {
    String url = "http://localhost:" + port + "/api/nonexistent";

    ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);

    assertThat(response.getStatusCode()).isEqualTo(HttpStatus.NOT_FOUND);
    assertThat(response.getBody()).isNotNull();
    assertThat(response.getBody().get("error")).isNotNull();

    @SuppressWarnings("unchecked")
    Map<String, Object> error = (Map<String, Object>) response.getBody().get("error");
    assertThat(error.get("code")).isEqualTo("NOT_FOUND");
    assertThat(error.get("message")).isNotNull();
  }
}
