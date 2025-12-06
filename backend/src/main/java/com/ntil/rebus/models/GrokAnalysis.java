package com.ntil.rebus.models;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Processed Grok Analysis Result
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GrokAnalysis {
    @Builder.Default
    private Double sentimentScore = 0.0; // -1.0 to 1.0
    
    @Builder.Default
    private Double misinformationProbability = 0.0; // 0.0 to 1.0
    
    @Builder.Default
    private List<String> escalatoryLanguage = Collections.emptyList();
    
    @Builder.Default
    private List<String> culturalNuances = Collections.emptyList();
    
    @Builder.Default
    private Double confidence = 0.0; // 0.0 to 1.0
    
    private String reasoning;
    private String errorMessage;
    private Long processingTimeMs;

    /**
     * Create error response
     */
    public static GrokAnalysis error(String message) {
        return GrokAnalysis.builder()
            .errorMessage(message)
            .confidence(0.0)
            .escalatoryLanguage(Collections.emptyList())
            .culturalNuances(Collections.emptyList())
            .build();
    }

    /**
     * Check if analysis completed successfully
     */
    public boolean isSuccessful() {
        return errorMessage == null || errorMessage.isEmpty();
    }
}
