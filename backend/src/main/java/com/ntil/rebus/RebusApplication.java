package com.ntil.rebus;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;
import lombok.extern.slf4j.Slf4j;

/**
 * NTIL REBUS-GROK System
 * Main Application Entry Point
 * 
 * Mission: Real-time diplomatic misinterpretation prevention through
 * AI-powered analysis and global monitoring.
 * 
 * @author NTIL Engineering Team
 * @version 5.0.0
 */
@Slf4j
@SpringBootApplication
@EnableAsync
@EnableCaching
@EnableScheduling
public class RebusApplication {

    public static void main(String[] args) {
        SpringApplication.run(RebusApplication.class, args);
        log.info("""
╔═════════════════════════════════════════════════════╗
║ NTIL REBUS-GROK System v5.0.0                      ║
║ Status: OPERATIONAL                                 ║
║ Mission: Global Conflict Prevention Through Clarity ║
╚═════════════════════════════════════════════════════╝
            """);
    }
}
