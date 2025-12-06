package com.ntil.rebus.models;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.Map;

/**
 * Communication Data Model
 * 
 * Represents a diplomatic communication or public statement
 * to be analyzed by the REBUS system.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CommunicationData {
    private String id;
    
    @NotBlank(message = "Text content is required")
    @Size(min = 10, max = 50000, message = "Text must be between 10 and 50000 characters")
    private String text;
    
    @Builder.Default
    private String language = "en";
    
    @Builder.Default
    private Instant timestamp = Instant.now();
    
    private CommunicationContext context;
    private Map<String, Object> metadata;
    
    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CommunicationContext {
        private String sourceCountry;
        private String targetCountry;
        
        @Builder.Default
        private CommunicationType communicationType = CommunicationType.DIPLOMATIC;
        
        private String region;
        private String topic;
        private String speakerRole;
        private Map<String, String> additionalContext;
    }
    
    public enum CommunicationType {
        DIPLOMATIC,
        MILITARY,
        MEDIA,
        SOCIAL,
        OFFICIAL_STATEMENT,
        TREATY,
        PRESS_CONFERENCE
    }
}
