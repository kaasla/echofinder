package com.echofinder.api.infra;

import java.util.Map;

public record ErrorEnvelope(ErrorDetail error) {

  public record ErrorDetail(ErrorCode code, String message, Map<String, Object> details) {
    public ErrorDetail(ErrorCode code, String message) {
      this(code, message, Map.of());
    }
  }

  public static ErrorEnvelope of(ErrorCode code, String message) {
    return new ErrorEnvelope(new ErrorDetail(code, message));
  }

  public static ErrorEnvelope of(ErrorCode code, String message, Map<String, Object> details) {
    return new ErrorEnvelope(new ErrorDetail(code, message, details));
  }
}
