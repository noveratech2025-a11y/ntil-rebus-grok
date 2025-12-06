package com.ntil.rebus.models;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Comprehensive Risk Assessment
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RiskAssessment {
    @Builder.Default
    private Double score = 0.0; // 0 to 100
    
    @Builder.Default
    private RiskLevel riskLevel = RiskLevel.MINIMAL;
    
    @Builder.Default
    private Double confidence = 0.0; // 0.0 to 1.0
    
    @Builder.Default
    private Map<String, Double> componentScores = Collections.emptyMap();
    
    private String primaryRiskFactor;
    private String riskSummary;

    /**
     * Determine risk level from score
     */
    public static RiskLevel levelFromScore(double score) {
        if (score >= 75) return RiskLevel.CRITICAL;
        if (score >= 60) return RiskLevel.HIGH;
        if (score >= 40) return RiskLevel.MEDIUM;
        if (score >= 20) return RiskLevel.LOW;
        return RiskLevel.MINIMAL;
    }
}
