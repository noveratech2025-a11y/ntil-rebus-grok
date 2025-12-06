package com.ntil.rebus.models;

import lombok.Getter;

/**
 * Risk Classification Levels
 */
@Getter
public enum RiskLevel {
    MINIMAL(0, 20, "green", "Routine monitoring"),
    LOW(20, 40, "blue", "Standard protocols"),
    MEDIUM(40, 60, "yellow", "Elevated attention required"),
    HIGH(60, 75, "orange", "Immediate review required"),
    CRITICAL(75, 100, "red", "Crisis protocols activated");

    private final int minScore;
    private final int maxScore;
    private final String colorCode;
    private final String actionGuidance;

    RiskLevel(int minScore, int maxScore, String colorCode, String actionGuidance) {
        this.minScore = minScore;
        this.maxScore = maxScore;
        this.colorCode = colorCode;
        this.actionGuidance = actionGuidance;
    }
}
